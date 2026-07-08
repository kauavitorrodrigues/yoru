#!/usr/bin/env python3
import json
import os
import sys

# Limited to formats stock Pillow (no extra plugins) can decode. avif/heic/heif
# would scan but fail thumbnail generation silently.
SUPPORTED_EXTENSIONS = frozenset({
    ".jpg", ".jpeg", ".png", ".webp", ".bmp", ".gif",
    ".tiff", ".tif",
})


def scan(wallpaper_dir: str) -> None:
    if not os.path.isdir(wallpaper_dir):
        print(json.dumps([]))
        return

    results = []
    for root, dirs, files in os.walk(wallpaper_dir):
        dirs.sort()
        for filename in sorted(files):
            ext = os.path.splitext(filename)[1].lower()
            if ext in SUPPORTED_EXTENSIONS:
                path = os.path.join(root, filename)
                results.append({"path": path, "fileName": filename})

    print(json.dumps(results))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("usage: scan_wallpapers.py <wallpaper_dir>", file=sys.stderr)
        sys.exit(1)
    scan(sys.argv[1])
