#!/usr/bin/env python3
"""Generates the app icon (macOS + iOS) into an .appiconset. Stdlib only. Deterministic.

The artwork is a 32 x 32 pixel-art scene — a barrel rolling down a girder, a ladder beside
it — drawn at 1024 px with hard pixel edges, then laid on the rounded square macOS expects.
iOS masks the icon itself, so it gets the same art full-bleed.
"""
import json, struct, sys, zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from gen_sprites import PALETTE  # noqa: E402

CANVAS = 32  # art grid
MASTER = 1024  # rendered icon
MAC_SIZES = [16, 32, 64, 128, 256, 512, 1024]

# macOS icons are a rounded square inset in the canvas rather than a full-bleed image.
BODY = 824  # Apple's grid for a "square" app icon
CORNER = 0.2237  # squircle-ish corner radius, as a fraction of BODY
SS = 4  # supersampling used to antialias the corners

BG_TOP = (26, 16, 48, 255)  # deep violet — reads on a light or a dark dock
BG_BOTTOM = (8, 6, 16, 255)

ART = """
................................
................................
.........LL.............LL......
.........LL.............LL......
.........LL....NNNNNN...LL......
.........LL...NnnnnnnN..LL......
.........LL..NnNNNNNNnN.LL......
.........LLLLNnNnnnnNnNLLLL.....
.........LL..NnNnnnnNnN.LL......
.........LL..NnNnnnnNnN.LL......
.........LL..NnNNNNNNnN.LL......
.........LL...NnnnnnnN..LL......
.........LL....NNNNNN...LL......
.........LL.............LL......
.........LLLLLLLLLLLLLLLLLL.....
.........LL.............LL......
.........LL.............LL......
................................
................................
GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
GggggggggggggggggggggggggggggggG
GgGGGGgGGGGgGGGGgGGGGgGGGGgGGGgG
GgG..GgG..GgG..GgG..GgG..GgG..gG
GgG..GgG..GgG..GgG..GgG..GgG..gG
GgGGGGgGGGGgGGGGgGGGGgGGGGgGGGgG
GggggggggggggggggggggggggggggggG
GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
................................
................................
................................
................................
................................
"""


def grid(text):
    rows = [r for r in text.strip("\n").split("\n")]
    w = len(rows[0])
    assert all(len(r) == w for r in rows), "ragged art"
    assert len(rows) == CANVAS and w == CANVAS, f"art must be {CANVAS} x {CANVAS}"
    return [list(r) for r in rows]


def background(y, size):
    """Vertical gradient, so the icon has depth instead of reading as a flat black tile."""
    t = y / max(1, size - 1)
    return tuple(int(a + (b - a) * t) for a, b in zip(BG_TOP, BG_BOTTOM))


def render_body(size):
    """The artwork on its gradient, at `size` px, with no rounding yet."""
    art = grid(ART)
    scale = size / CANVAS
    px = []
    for y in range(size):
        bg = background(y, size)
        row = []
        for x in range(size):
            c = art[min(CANVAS - 1, int(y / scale))][min(CANVAS - 1, int(x / scale))]
            rgba = PALETTE[c]
            row.append(bg if rgba[3] == 0 else rgba)
        px.append(row)
    return px


def corner_coverage(size):
    """Per-pixel alpha of a rounded square, supersampled so the corners are not jagged."""
    r = CORNER * size
    cov = [[255] * size for _ in range(size)]
    span = int(r) + 2
    for cy, cx in ((r, r), (r, size - r), (size - r, r), (size - r, size - r)):
        for y in range(max(0, int(cy - span)), min(size, int(cy + span))):
            for x in range(max(0, int(cx - span)), min(size, int(cx + span))):
                # only the pixels outside the corner's quarter-disc need measuring
                if (x < r or x > size - r) and (y < r or y > size - r):
                    hits = 0
                    for sy in range(SS):
                        for sx in range(SS):
                            py, pxx = y + (sy + 0.5) / SS, x + (sx + 0.5) / SS
                            ny = r if py < r else (size - r if py > size - r else py)
                            nx = r if pxx < r else (size - r if pxx > size - r else pxx)
                            if (py - ny) ** 2 + (pxx - nx) ** 2 <= r * r:
                                hits += 1
                    cov[y][x] = min(cov[y][x], hits * 255 // (SS * SS))
    return cov


def mac_master():
    """1024 canvas, transparent, with the rounded body centred in it."""
    body = render_body(BODY)
    cov = corner_coverage(BODY)
    inset = (MASTER - BODY) // 2
    px = [[(0, 0, 0, 0)] * MASTER for _ in range(MASTER)]
    for y in range(BODY):
        for x in range(BODY):
            a = cov[y][x]
            if a:
                r, g, b, _ = body[y][x]
                px[y + inset][x + inset] = (r, g, b, a)
    return px


def downscale(px, size):
    src = len(px)
    k = src // size
    out = []
    for y in range(size):
        row = []
        for x in range(size):
            acc = [0, 0, 0, 0]
            for yy in range(y * k, (y + 1) * k):
                line = px[yy]
                for xx in range(x * k, (x + 1) * k):
                    p = line[xx]
                    # premultiply so transparent pixels do not darken the edges
                    a = p[3]
                    acc[0] += p[0] * a; acc[1] += p[1] * a; acc[2] += p[2] * a; acc[3] += a
            a = acc[3] // (k * k)
            if a == 0:
                row.append((0, 0, 0, 0))
            else:
                # un-premultiply: acc[c] is sum(colour x alpha), acc[3] is sum(alpha)
                row.append((acc[0] // acc[3], acc[1] // acc[3], acc[2] // acc[3], a))
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
    images = [{"filename": "icon_ios_1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}]
    for pt in (16, 32, 128, 256, 512):
        for scale in (1, 2):
            images.append(
                {"filename": f"icon_{pt * scale}.png", "idiom": "mac", "scale": f"{scale}x", "size": f"{pt}x{pt}"})
    return {"images": images, "info": {"author": "xcode", "version": 1}}


def main(out_dir):
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    for old in out.glob("*.png"):
        old.unlink()
    master = mac_master()
    for size in MAC_SIZES:
        px = master if size == MASTER else downscale(master, size)
        (out / f"icon_{size}.png").write_bytes(png_bytes(px))
    # iOS masks the icon itself, so it takes the art full-bleed and opaque.
    (out / "icon_ios_1024.png").write_bytes(png_bytes(render_body(MASTER)))
    (out / "Contents.json").write_text(json.dumps(contents_json(), indent=2) + "\n")
    print(f"wrote {len(MAC_SIZES) + 1} icons to {out}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "App/Resources/Assets.xcassets/AppIcon.appiconset")
