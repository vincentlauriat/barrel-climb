#!/usr/bin/env python3
"""Generates the app icon (macOS + iOS) into an .appiconset. Stdlib only. Deterministic.

The icon is a 32 × 32 pixel-art composition — a barrel resting on a girder — scaled to
1024 px with hard edges, then box-filtered down to every size the macOS catalog needs.
"""
import json, struct, sys, zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from gen_sprites import BARREL, GIRDER, PALETTE, grid  # noqa: E402

CANVAS = 32
MASTER = 1024
BACKGROUND = (20, 20, 20, 255)
MAC_SIZES = [16, 32, 64, 128, 256, 512, 1024]


def compose():
    """32 × 32 grid of palette keys: black ground, girder along the bottom, barrel above."""
    canvas = [["K"] * CANVAS for _ in range(CANVAS)]
    girder = grid(GIRDER)
    for y in range(8):
        for x in range(CANVAS):
            canvas[22 + y][x] = girder[y][x % 8]
    barrel = grid(BARREL)
    for y in range(10):
        for x in range(10):
            c = barrel[y][x]
            if c != ".":
                for dy in range(2):
                    for dx in range(2):
                        canvas[2 + 2 * y + dy][6 + 2 * x + dx] = c
    return canvas


def rgba_master(canvas):
    scale = MASTER // CANVAS
    px = [[None] * MASTER for _ in range(MASTER)]
    for y in range(MASTER):
        row = canvas[y // scale]
        for x in range(MASTER):
            c = PALETTE[row[x // scale]]
            px[y][x] = BACKGROUND if c[3] == 0 else c
    return px


def downscale(px, size):
    """Box filter from MASTER to `size` (must divide MASTER)."""
    k = MASTER // size
    out = []
    for y in range(size):
        row = []
        for x in range(size):
            acc = [0, 0, 0, 0]
            for yy in range(y * k, (y + 1) * k):
                src = px[yy]
                for xx in range(x * k, (x + 1) * k):
                    p = src[xx]
                    acc[0] += p[0]; acc[1] += p[1]; acc[2] += p[2]; acc[3] += p[3]
            n = k * k
            row.append((acc[0] // n, acc[1] // n, acc[2] // n, acc[3] // n))
        out.append(row)
    return out


def png_bytes(px):
    h, w = len(px), len(px[0])
    raw = b"".join(b"\x00" + b"".join(bytes(p) for p in row) for row in px)

    def chunk(kind, data):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")


def contents_json():
    images = [{"filename": "icon_1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}]
    for pt in (16, 32, 128, 256, 512):
        for scale in (1, 2):
            images.append({"filename": f"icon_{pt * scale}.png", "idiom": "mac", "scale": f"{scale}x", "size": f"{pt}x{pt}"})
    return {"images": images, "info": {"author": "xcode", "version": 1}}


def main(out_dir):
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    master = rgba_master(compose())
    for size in MAC_SIZES:
        px = master if size == MASTER else downscale(master, size)
        (out / f"icon_{size}.png").write_bytes(png_bytes(px))
    (out / "Contents.json").write_text(json.dumps(contents_json(), indent=2) + "\n")
    print(f"wrote {len(MAC_SIZES)} icons to {out}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "App/Resources/Assets.xcassets/AppIcon.appiconset")
