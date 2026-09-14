#!/usr/bin/env python3
"""Synthesizes short square-wave arcade sounds as 16-bit mono WAV. Stdlib only. Deterministic."""
import math, struct, sys, wave
from pathlib import Path

RATE = 22050


def square(freq, seconds, volume=0.3, duty=0.5):
    n = int(RATE * seconds)
    period = RATE / freq
    return [volume if (i % period) < period * duty else -volume for i in range(n)]


def sweep(f0, f1, seconds, volume=0.3):
    n = int(RATE * seconds)
    out, phase = [], 0.0
    for i in range(n):
        f = f0 + (f1 - f0) * i / n
        phase += f / RATE
        out.append(volume if (phase % 1.0) < 0.5 else -volume)
    return out


def silence(seconds):
    return [0.0] * int(RATE * seconds)


def envelope(samples, attack=0.005, release=0.03):
    n = len(samples)
    a, r = int(RATE * attack), int(RATE * release)
    out = []
    for i, s in enumerate(samples):
        g = min(1.0, i / a if a else 1.0, (n - i) / r if r else 1.0)
        out.append(s * max(0.0, g))
    return out


SOUNDS = {
    "jump":   lambda: envelope(sweep(300, 900, 0.12)),
    "barrel": lambda: envelope(square(110, 0.05, 0.2)),
    "hammer": lambda: envelope(square(220, 0.04) + square(330, 0.04)),
    "die":    lambda: envelope(sweep(600, 80, 0.6, 0.35)),
    "clear":  lambda: envelope(sum((square(f, 0.12) + silence(0.02) for f in (523, 659, 784, 1046)), [])),
    "pickup": lambda: envelope(sweep(400, 1200, 0.08)),
    "bonus":  lambda: envelope(square(1500, 0.02, 0.15)),
}


def write_wav(path, samples):
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32767)) for s in samples))


def main(out_dir):
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    for name, make in SOUNDS.items():
        write_wav(out / f"{name}.wav", make())
    print(f"wrote {len(SOUNDS)} sounds to {out}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "App/Resources/sounds")
