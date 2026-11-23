#!/usr/bin/env python3
"""Generate wallpaper picker thumbnails, keeping peak memory low.

usage: generate_thumbnails.py <cache_dir> <width> <height> [--workers N]
                              [--max-pixels N] [--no-animated]
                              (--dir <wallpaper_dir> | [wallpaper_path ...])

Prefer --dir: the script scans the directory itself, so the file list never
goes through argv (which can hit ARG_MAX with thousands of wallpapers).
Positional paths are still accepted for compatibility.

Emits one JSON line per image on stdout as soon as it is done.
"""
import concurrent.futures
import hashlib
import json
import os
import re
import sys

from scan_wallpapers import list_wallpapers

JPEG_QUALITY = 85
GIF_EXTENSIONS = frozenset({".gif"})
JPEG_EXTENSIONS = frozenset({".jpg", ".jpeg"})

# Decoding is the memory-hungry part, so default to a small pool.
DEFAULT_WORKERS = 2
# A single animated preview never keeps more than this many frames.
MAX_GIF_FRAMES = 150
# Pillow raises DecompressionBombError above 2x this value (~200M pixels),
# which rejects absurdly large files instead of decoding them.
MAX_IMAGE_PIXELS = 100_000_000
# --no-animated skips the downscaled GIF previews (static thumbnails only).
ANIMATED_PREVIEWS = True

CACHE_NAME_RE = re.compile(r"^[0-9a-f]{64}_\d+x\d+\.(jpg|gif)$")

# PIL is imported lazily: when every thumbnail is already cached (the common
# case) the script never needs to load it at all.
_Image = None
_ImageSequence = None


def _pil():
    global _Image, _ImageSequence
    if _Image is None:
        from PIL import Image, ImageSequence

        Image.MAX_IMAGE_PIXELS = MAX_IMAGE_PIXELS
        _Image, _ImageSequence = Image, ImageSequence
    return _Image, _ImageSequence


def cache_path(cache_dir: str, src_path: str, width: int, height: int, ext: str) -> str:
    # mtime is folded into the key so replacing a file in place (same path,
    # new content) invalidates the cache instead of serving a stale entry.
    try:
        mtime = os.path.getmtime(src_path)
    except OSError:
        mtime = 0
    digest_input = f"{src_path}:{mtime}"
    sha256 = hashlib.sha256(digest_input.encode()).hexdigest()
    return os.path.join(cache_dir, f"{sha256}_{width}x{height}.{ext}")


def _fit_and_crop(img, width: int, height: int):
    Image, _ = _pil()
    img_ratio = img.width / img.height
    target_ratio = width / height

    if img_ratio > target_ratio:
        new_height = height
        new_width = round(img_ratio * new_height)
    else:
        new_width = width
        new_height = round(new_width / img_ratio)

    # reducing_gap lets Pillow do a cheap integer-factor reduce() first and
    # only then the LANCZOS pass, instead of filtering the full-size image.
    img = img.resize((new_width, new_height), Image.LANCZOS, reducing_gap=2.0)

    left = (new_width - width) // 2
    top = (new_height - height) // 2
    return img.crop((left, top, left + width, top + height))


def _generate_static(src_path: str, dst_path: str, width: int, height: int) -> None:
    Image, _ = _pil()
    with Image.open(src_path) as img:
        if os.path.splitext(src_path)[1].lower() in JPEG_EXTENSIONS:
            # Let the JPEG decoder downscale while reading (by 1/2, 1/4, 1/8),
            # so a 4K/8K photo is never fully decoded. Keeps >= 2x the target
            # so quality is unaffected.
            img.draft("RGB", (width * 2, height * 2))
        img = _fit_and_crop(img, width, height).convert("RGB")
        img.save(dst_path, "JPEG", quality=JPEG_QUALITY)


def _animated_frames(img, width: int, height: int, durations: list):
    _, ImageSequence = _pil()
    for index, frame in enumerate(ImageSequence.Iterator(img)):
        if index >= MAX_GIF_FRAMES:
            break
        # Appended before yielding: Pillow reads durations[i] when it pulls
        # frame i from this generator.
        durations.append(frame.info.get("duration", 100))
        # One full-size RGBA frame exists at a time; only the downscaled RGB
        # result is handed on.
        yield _fit_and_crop(frame.convert("RGBA"), width, height).convert("RGB")


def _generate_animated(src_path: str, dst_path: str, width: int, height: int) -> None:
    # Every frame is saved as a full width x height canvas (no `optimize`,
    # explicit disposal=2) rather than the delta-encoded partial frames GIF
    # normally prefers. Downscaling a delta-encoded frame on its own loses
    # the rest of the canvas it was meant to be composited onto, and
    # AnimatedImage in QML renders that as solid black. optimize=False costs
    # some file size but is what makes the cached preview decode correctly.
    Image, _ = _pil()
    durations: list = []
    tmp_path = dst_path + ".tmp"
    try:
        with Image.open(src_path) as img:
            frames = _animated_frames(img, width, height, durations)
            first = next(frames, None)
            if first is None:
                raise ValueError(f"no frames decoded from {src_path}")
            # Pillow reads `duration[0]` before consuming the generator.
            first.save(tmp_path, "GIF", save_all=True, append_images=frames, duration=durations, loop=0, optimize=False, disposal=2)
        os.replace(tmp_path, dst_path)
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)


def generate(cache_dir: str, src_path: str, width: int, height: int) -> dict:
    static_dst = cache_path(cache_dir, src_path, width, height, "jpg")
    result = {"path": src_path}

    try:
        os.makedirs(cache_dir, exist_ok=True)
        if not os.path.exists(static_dst):
            _generate_static(src_path, static_dst, width, height)
        result["thumbnailPath"] = static_dst
    except Exception as exc:
        print(f"generate_thumbnails: static thumbnail failed for {src_path}: {exc}", file=sys.stderr)
        return {"path": src_path, "error": str(exc)}

    # A failure here shouldn't discard the static thumbnail generated above:
    # without this, an error decoding the GIF (corrupt file, zero frames)
    # would silently drop `thumbnailPath` from the result too, and since the
    # static file already exists on disk, every future rescan would retry
    # and fail the same way, leaving the item permanently blank.
    ext = os.path.splitext(src_path)[1].lower()
    if ANIMATED_PREVIEWS and ext in GIF_EXTENSIONS:
        try:
            animated_dst = cache_path(cache_dir, src_path, width, height, "gif")
            if not os.path.exists(animated_dst):
                _generate_animated(src_path, animated_dst, width, height)
            result["animatedThumbnailPath"] = animated_dst
        except Exception as exc:
            print(f"generate_thumbnails: animated preview failed for {src_path}: {exc}", file=sys.stderr)

    return result


def prune_cache(cache_dir: str, paths: list, width: int, height: int) -> None:
    """Delete cache files that no current wallpaper maps to.

    The key includes mtime, so replaced or removed wallpapers (and a changed
    thumbnail size) would otherwise leave orphans forever. Only files matching
    the cache naming scheme are touched.
    """
    keep = set()
    for path in paths:
        keep.add(os.path.basename(cache_path(cache_dir, path, width, height, "jpg")))
        if os.path.splitext(path)[1].lower() in GIF_EXTENSIONS:
            keep.add(os.path.basename(cache_path(cache_dir, path, width, height, "gif")))
    try:
        names = os.listdir(cache_dir)
    except OSError:
        return
    for name in names:
        if CACHE_NAME_RE.match(name) and name not in keep:
            try:
                os.remove(os.path.join(cache_dir, name))
            except OSError:
                pass


def _parse_args(argv: list):
    global MAX_IMAGE_PIXELS, ANIMATED_PREVIEWS
    workers = DEFAULT_WORKERS
    directory = None
    positional = []
    i = 0
    while i < len(argv):
        arg = argv[i]
        if arg == "--workers" and i + 1 < len(argv):
            workers = max(1, int(argv[i + 1]))
            i += 2
        elif arg == "--max-pixels" and i + 1 < len(argv):
            MAX_IMAGE_PIXELS = max(1, int(float(argv[i + 1])))
            i += 2
        elif arg == "--no-animated":
            ANIMATED_PREVIEWS = False
            i += 1
        elif arg == "--dir" and i + 1 < len(argv):
            directory = argv[i + 1]
            i += 2
        else:
            positional.append(arg)
            i += 1
    return workers, directory, positional


def main() -> None:
    workers, directory, positional = _parse_args(sys.argv[1:])
    if len(positional) < 3:
        print("usage: generate_thumbnails.py <cache_dir> <width> <height> [--workers N] [--max-pixels N] [--no-animated] (--dir <wallpaper_dir> | [wallpaper_path ...])", file=sys.stderr)
        sys.exit(1)

    cache_dir = positional[0]
    width = int(positional[1])
    height = int(positional[2])
    if directory is not None:
        paths = [entry["path"] for entry in list_wallpapers(directory)]
    else:
        paths = positional[3:]
    if not paths:
        return

    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as executor:
        futures = {executor.submit(generate, cache_dir, path, width, height): path for path in paths}
        for future in concurrent.futures.as_completed(futures):
            print(json.dumps(future.result()), flush=True)

    # Only a run over the complete wallpaper list knows what is orphaned.
    if directory is not None:
        prune_cache(cache_dir, paths, width, height)


if __name__ == "__main__":
    main()
