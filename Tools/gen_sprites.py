#!/usr/bin/env python3
"""Generates the game's original pixel art as RGBA PNGs. Stdlib only. Deterministic."""
import struct, sys, zlib
from pathlib import Path

PALETTE = {
    ".": (0, 0, 0, 0),           # transparent
    "K": (20, 20, 20, 255),      # near black
    "W": (240, 240, 240, 255),   # white
    "R": (220, 40, 40, 255),     # red (cap, shirt)
    "B": (40, 80, 220, 255),     # blue (overalls)
    "S": (250, 200, 150, 255),   # skin
    "N": (120, 70, 30, 255),     # brown (barrel, hair, Kong fur)
    "n": (170, 110, 50, 255),    # light brown
    "Y": (250, 220, 60, 255),    # yellow
    "O": (250, 140, 40, 255),    # orange (fire)
    "P": (250, 100, 180, 255),   # pink (Pauline dress)
    "C": (60, 200, 240, 255),    # cyan (blue barrel)
    "c": (30, 120, 200, 255),    # dark cyan
    "G": (250, 80, 200, 255),    # magenta girder
    "g": (150, 40, 120, 255),    # dark magenta
    "L": (80, 200, 255, 255),    # ladder
}

PLAYER_STAND = """
....RRRR....
...RRRRRR...
...SSNSSK...
...SNSSSK...
...SSSSS....
..RRBBRRR...
.RRBBBBRRS..
.SSBBBBBSS..
...BBBBBB...
...BBBBBB...
...BB..BB...
...BB..BB...
..NNN..NNN..
..NNN..NNN..
............
............
"""
PLAYER_WALK1 = """
....RRRR....
...RRRRRR...
...SSNSSK...
...SNSSSK...
...SSSSS....
..RRBBRRR...
.RRBBBBRRS..
.SSBBBBBSS..
...BBBBBB...
...BBBBBB...
..BB....BB..
.BB......BB.
NNN......NNN
NNN......NNN
............
............
"""
PLAYER_JUMP = """
....RRRR..S.
...RRRRRR.S.
...SSNSSKS..
...SNSSSKR..
...SSSSSRR..
..RRBBRRR...
.RRBBBBRR...
.SSBBBBB....
...BBBBBB...
...BBBBBB...
..BB....BB..
.BB......BB.
NNN......NNN
............
............
............
"""
PLAYER_CLIMB1 = """
....RRRR....
...RRRRRR...
...NNNNNN...
S..NNNNNN...
S..RRBBRR...
SSRRBBBBRR..
..RRBBBBRR..
...BBBBBB..S
...BBBBBB..S
...BBBBBBSS.
...BB..BB...
...BB..BB...
..NNN..NNN..
..NNN..NNN..
............
............
"""
PLAYER_HAMMER1 = """
.......NN...
.......NN...
....RRRRN...
...RRRRRR...
...SSNSSK...
...SNSSSK...
...SSSSS....
..RRBBRRR...
.RRBBBBRRS..
.SSBBBBBSS..
...BBBBBB...
...BBBBBB...
...BB..BB...
...BB..BB...
..NNN..NNN..
..NNN..NNN..
"""
BARREL = """
..NNNNNN..
.NnnnnnnN.
NnNNNNNNnN
NnNnnnnNnN
NnNnnnnNnN
NnNnnnnNnN
NnNnnnnNnN
NnNNNNNNnN
.NnnnnnnN.
..NNNNNN..
"""
FIREBALL_1 = """
....OO....
...OYYO...
..OYYYYO..
.OYYWWYYO.
.OYWWWWYO.
OOYWWWWYOO
OYYWWWWYYO
.OYYWWYYO.
..OYYYYO..
...OOOO...
..K....K..
.K......K.
"""
KONG_IDLE = """
............NNNNNNNNNNNNNNNN............
.........NNNNNNNNNNNNNNNNNNNNNN.........
.......NNNNNNNNNNNNNNNNNNNNNNNNNN.......
......NNNNNNnnnnnnnnnnnnnnnnNNNNNN......
.....NNNNNnnnnnnnnnnnnnnnnnnnnNNNNN.....
.....NNNNnnnnKKnnnnnnnnnnKKnnnnNNNN.....
....NNNNnnnnnKKnnnnnnnnnnKKnnnnnNNNN....
....NNNNnnnnnnnnnnnnnnnnnnnnnnnnNNNN....
....NNNNnnnnnnSSSSSSSSSSSSnnnnnnNNNN....
....NNNNnnnnnSSSSSSSSSSSSSSnnnnnNNNN....
....NNNNnnnnnnSSSSKKKKSSSSnnnnnnNNNN....
....NNNNnnnnnnnSSSSSSSSSSnnnnnnnNNNN....
.....NNNNnnnnnnnnnnnnnnnnnnnnnnNNNN.....
....NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN....
...NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN...
..NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN..
.NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN.
.NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN.
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
.NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN.
.NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN.
..NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN..
..NNNNNN........................NNNNNN..
.NNNNNNN........................NNNNNNN.
.NNNNNNN........................NNNNNNN.
.NNNNNNN........................NNNNNNN.
........................................
"""
PAULINE_1 = """
.....NNNNNN.....
....NNNNNNNN....
...NNNSSSSNNN...
...NNSSSSSSNN...
...NNSKSSKSNN...
...NNSSSSSSNN...
....NSSSSSSN....
.....SSSSSS.....
......PPPP......
.....PPPPPP.....
....PPPPPPPP....
..S.PPPPPPPP.S..
..S.PPPPPPPP.S..
..SSPPPPPPPPSS..
....PPPPPPPP....
....PPPPPPPP....
...PPPPPPPPPP...
...PPPPPPPPPP...
..PPPPPPPPPPPP..
..PPPPPPPPPPPP..
.PPPPPPPPPPPPPP.
.PPPPPPPPPPPPPP.
....KK....KK....
....KK....KK....
"""
HAMMER = """
..KKKKKK..
.KnnnnnnK.
.KnnnnnnK.
.KnnnnnnK.
..KKKKKK..
....NN....
....NN....
....NN....
....NN....
....NN....
"""
OIL_DRUM = """
.KKKKKKKKKKKKKK.
KccccccccccccccK
KcCCCCCCCCCCCCcK
KcCcccccccccccCK
KcCcccccccccccCK
KcCCCCCCCCCCCCcK
KccccccccccccccK
KcCCCCCCCCCCCCcK
KcCcccccccccccCK
KcCcccccccccccCK
KcCCCCCCCCCCCCcK
KccccccccccccccK
KcCCCCCCCCCCCCcK
KccccccccccccccK
KccccccccccccccK
.KKKKKKKKKKKKKK.
"""
GIRDER = """
GGGGGGGG
GggggggG
GgGGGGgG
GgG..GgG
GgG..GgG
GgGGGGgG
GggggggG
GGGGGGGG
"""
LADDER = """
L......L
L......L
LLLLLLLL
L......L
L......L
L......L
LLLLLLLL
L......L
"""


def grid(text):
    rows = [r for r in text.strip("\n").split("\n")]
    w = len(rows[0])
    assert all(len(r) == w for r in rows), "ragged sprite"
    return [list(r) for r in rows]


def flip_h(g):
    return [list(reversed(r)) for r in g]


def shift(g, dx=0, dy=0):
    h, w = len(g), len(g[0])
    out = [["."] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w:
                out[ny][nx] = g[y][x]
    return out


def rotate(g):
    """90° clockwise; the grid must be square."""
    n = len(g)
    return [[g[n - 1 - x][y] for x in range(n)] for y in range(n)]


def recolor(g, mapping):
    return [[mapping.get(c, c) for c in r] for r in g]


def blank_rows(g, rows):
    return [["."] * len(r) if i in rows else list(r) for i, r in enumerate(g)]


def png_bytes(g):
    h, w = len(g), len(g[0])
    raw = b"".join(b"\x00" + b"".join(bytes(PALETTE[c]) for c in row) for row in g)

    def chunk(kind, data):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")


def sprites():
    stand, walk1, jump = grid(PLAYER_STAND), grid(PLAYER_WALK1), grid(PLAYER_JUMP)
    climb1, hammer1 = grid(PLAYER_CLIMB1), grid(PLAYER_HAMMER1)
    barrel = grid(BARREL)
    blue = recolor(barrel, {"N": "c", "n": "C"})
    out = {
        "player_stand": stand,
        "player_walk1": walk1,
        "player_walk2": shift(walk1, dy=1),
        "player_jump": jump,
        "player_climb1": climb1,
        "player_climb2": flip_h(climb1),
        "player_hammer1": hammer1,
        "player_hammer2": shift(hammer1, dy=2),
        "player_die": flip_h(shift(stand, dy=2)),
        "fireball_1": grid(FIREBALL_1),
        "fireball_2": flip_h(grid(FIREBALL_1)),
        "kong_idle": grid(KONG_IDLE),
        "kong_throw": shift(grid(KONG_IDLE), dx=2),
        "pauline_1": grid(PAULINE_1),
        "pauline_2": flip_h(grid(PAULINE_1)),
        "hammer": grid(HAMMER),
        "oil_drum": grid(OIL_DRUM),
        "girder": grid(GIRDER),
        "ladder": grid(LADDER),
        "ladder_broken": blank_rows(grid(LADDER), {3, 4, 5}),
    }
    for i in range(4):
        out[f"barrel_{i}"] = barrel
        out[f"barrel_blue_{i}"] = blue
        barrel, blue = rotate(barrel), rotate(blue)
    return out


def main(out_dir):
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    for name, g in sorted(sprites().items()):
        (out / f"{name}.png").write_bytes(png_bytes(g))
    print(f"wrote {len(sprites())} sprites to {out}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "App/Resources/sprites")
