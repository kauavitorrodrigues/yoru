#!/usr/bin/env python3
import concurrent.futures
import hashlib
import json
import os
import sys

from PIL import Image, ImageSequence

JPEG_QUALITY = 85
GIF_EXTENSIONS = frozenset({".gif"})


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
    img_ratio = img.width / img.height
    target_ratio = width / height

    if img_ratio > target_ratio:
        new_height = height
        new_width = round(img_ratio * new_height)
    else:
        new_width = width
        new_height = round(new_width / img_ratio)

    img = img.resize((new_width, new_height), Image.LANCZOS)

    left = (new_width - width) // 2
    top = (new_height - height) // 2
    return img.crop((left, top, left + width, top + height))


def _generate_static(src_path: str, dst_path: str, width: int, height: int) -> None:
    with Image.open(src_path) as img:
        img = _fit_and_crop(img, width, height).convert("RGB")
        img.save(dst_path, "JPEG", quality=JPEG_QUALITY)


def _generate_animated(src_path: str, dst_path: str, width: int, height: int) -> None:
    # Every frame is saved as a full width x height canvas (no `optimize`,
    # explicit disposal=2) rather than the delta-encoded partial frames GIF
    # normally prefers. Downscaling a delta-encoded frame on its own loses
    # the rest of the canvas it was meant to be composited onto, and
    # AnimatedImage in QML renders that as solid black. optimize=False costs
    # some file size but is what makes the cached preview decode correctly.
    frames = []
    durations = []
    with Image.open(src_path) as img:
        for frame in ImageSequence.Iterator(img):
            durations.append(frame.info.get("duration", 100))
            frames.append(_fit_and_crop(frame.convert("RGBA"), width, height).convert("RGB"))
    if not frames:
        raise ValueError(f"no frames decoded from {src_path}")
    frames[0].save(dst_path, save_all=True, append_images=frames[1:], duration=durations, loop=0, optimize=False, disposal=2)


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
    if ext in GIF_EXTENSIONS:
        try:
            animated_dst = cache_path(cache_dir, src_path, width, height, "gif")
            if not os.path.exists(animated_dst):
                _generate_animated(src_path, animated_dst, width, height)
            result["animatedThumbnailPath"] = animated_dst
        except Exception as exc:
            print(f"generate_thumbnails: animated preview failed for {src_path}: {exc}", file=sys.stderr)

    return result


def main() -> None:
    if len(sys.argv) < 4:
        print("usage: generate_thumbnails.py <cache_dir> <width> <height> [wallpaper_path ...]", file=sys.stderr)
        sys.exit(1)

    cache_dir = sys.argv[1]
    width = int(sys.argv[2])
    height = int(sys.argv[3])
    paths = sys.argv[4:]
    if not paths:
        return

    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
        futures = {executor.submit(generate, cache_dir, path, width, height): path for path in paths}
        for future in concurrent.futures.as_completed(futures):
            print(json.dumps(future.result()), flush=True)


if __name__ == "__main__":
    main()
