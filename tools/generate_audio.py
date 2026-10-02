"""Rebuild O Farol's original music and ambience using Python's standard library.

All notes and sounds are synthesized here; no recordings or third-party samples.
Music tails wrap around the buffer so the tracks can loop continuously.
"""
from array import array
from pathlib import Path
import math
import random
import wave

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio"
TAU = math.tau


def write(name, left, right):
    peak = max(max(map(abs, left)), max(map(abs, right)), 0.001)
    gain = min(1.0, 0.78 / peak)
    pcm = array("h")
    for a, b in zip(left, right):
        pcm.extend((int(a * gain * 32767), int(b * gain * 32767)))
    with wave.open(str(OUT / f"{name}.wav"), "wb") as file:
        file.setparams((2, 2, RATE, 0, "NONE", "not compressed"))
        file.writeframes(pcm.tobytes())
    print(f"{name}: {len(left) / RATE:.1f}s, peak {peak * gain:.3f}")


def note(left, right, midi, start, duration, gain, pan=0.0, bell=False):
    frequency = 440 * 2 ** ((midi - 69) / 12)
    offset = int(start * RATE)
    size = len(left)
    for i in range(int(duration * RATE)):
        t = i / RATE
        if bell:
            envelope = min(t / 0.015, 1) * math.exp(-t * 2.6)
            envelope *= min((duration - t) / 0.15, 1)
            tone = math.sin(TAU * frequency * t)
            tone += 0.22 * math.sin(TAU * frequency * 2 * t) * math.exp(-t * 4)
        else:
            envelope = math.sin(math.pi * t / duration) ** 2
            tone = math.sin(TAU * frequency * t)
            tone += 0.16 * math.sin(TAU * frequency * 2.003 * t)
            tone += 0.08 * math.sin(TAU * frequency * 0.998 * t)
        sample = tone * envelope * gain
        at = (offset + i) % size
        left[at] += sample * (1 - pan * 0.5)
        right[at] += sample * (1 + pan * 0.5)
        if bell:
            # Quiet echoes give the lonely motif space without imported effects.
            left[(at + int(RATE * 0.375)) % size] += sample * 0.22
            right[(at + int(RATE * 0.75)) % size] += sample * 0.15


def music(name, chords, melody, tense=False):
    size = RATE * 32
    left, right = array("f", [0]) * size, array("f", [0]) * size
    for bar, chord in enumerate(chords):
        for voice, pitch in enumerate(chord):
            note(left, right, pitch, bar * 4, 6, 0.062, (voice - 1) * 0.45)
        note(left, right, chord[0] - 12, bar * 4, 4, 0.075)
    for beat, pitch in enumerate(melody):
        if pitch:
            note(left, right, pitch, beat * 2 + 0.5, 2.8, 0.12, (-1) ** beat * 0.4, True)
    if tense:
        for beat in range(64):
            note(left, right, 38 if beat % 4 == 0 else 50, beat * 0.5, 0.32,
                 0.065 if beat % 4 == 0 else 0.025, bell=True)
    write(name, left, right)


def ambience(name, fire=False):
    rng = random.Random(812 if fire else 402)
    size = RATE * 12
    left, right = array("f", [0]) * size, array("f", [0]) * size
    filters = [0.0, 0.0]
    crackle = 0.0
    for i in range(size):
        t = i / RATE
        swell = 0.55 + 0.35 * math.sin(TAU * t / 6) + 0.1 * math.sin(TAU * t / 3)
        if fire and rng.random() < 0.0006:
            crackle = rng.uniform(0.08, 0.28)
        crackle *= 0.992
        for channel, target in enumerate((left, right)):
            noise = rng.uniform(-1, 1)
            filters[channel] += (noise - filters[channel]) * (0.12 if fire else 0.028)
            target[i] = filters[channel] * (0.26 if fire else 0.65) * swell
            if fire:
                target[i] += noise * crackle
    # Blend the seam rather than fading to silence each time the loop repeats.
    seam = RATE // 2
    for target in (left, right):
        for i in range(seam):
            amount = i / seam
            target[size - seam + i] = target[size - seam + i] * (1 - amount) + target[i] * amount
        del target[:seam]
    write(name, left, right)


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    music("day", [(50, 57, 65), (46, 53, 62), (53, 60, 69), (48, 55, 64)] * 2,
          [74, 0, 77, 76, 69, 0, 72, 0, 74, 77, 81, 0, 79, 76, 72, 0])
    music("night", [(38, 45, 53), (39, 46, 57), (46, 53, 60), (45, 52, 58)] * 2,
          [74, 0, 0, 75, 69, 0, 70, 0, 74, 0, 77, 75, 69, 0, 0, 73], True)
    music("rescue", [(53, 60, 69), (48, 55, 64), (50, 57, 65), (46, 53, 62)] * 2,
          [77, 81, 84, 0, 79, 76, 72, 0, 77, 81, 86, 84, 82, 81, 77, 0])
    ambience("ocean")
    ambience("campfire", True)
