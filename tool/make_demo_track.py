#!/usr/bin/env python3
"""Synthesizes the app's bundled demo track, "Three Bands".

The track is original: every sound is generated here from sine waves and
noise, with no samples or third-party material, and it is released into the
public domain (CC0 1.0). It is arranged to make the equalizer easy to hear:

    Low  (< 500 Hz):  kick drum and bass line
    Mid  (500-2000):  chord pad and snare body
    High (> 2000 Hz): hi-hats, snare noise and a bell arpeggio

Standard library only. Writes a 16-bit WAV; encode it for the app with
macOS's built-in encoder:

    python3 tool/make_demo_track.py /tmp/three_bands.wav
    afconvert -f m4af -d aac -b 160000 /tmp/three_bands.wav \
        assets/audio/three_bands.m4a
"""

import math
import random
import struct
import sys
import wave
from array import array

SR = 44100
BPM = 96
BEAT = 60 / BPM
BAR = 4 * BEAT
BARS = 24  # 60 seconds
N = int(BARS * BAR * SR) + SR  # one second of tail

random.seed(7)  # same output every run
left = array("f", bytes(4 * N))
right = array("f", bytes(4 * N))


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def add(start, samples, gain=1.0, pan=0.0):
    """Mixes mono [samples] in at time [start] (seconds), pan -1..1."""
    i0 = int(start * SR)
    gl = gain * math.cos((pan + 1) * math.pi / 4)
    gr = gain * math.sin((pan + 1) * math.pi / 4)
    for k, s in enumerate(samples):
        i = i0 + k
        if i >= N:
            break
        left[i] += s * gl
        right[i] += s * gr


def kick():
    out, phase = [], 0.0
    for k in range(int(0.45 * SR)):
        t = k / SR
        f = 45 + 75 * math.exp(-t * 28)  # pitch drop 120 -> 45 Hz
        phase += 2 * math.pi * f / SR
        out.append(math.sin(phase) * math.exp(-t * 7))
    return out


def bass(midi, length):
    f = hz(midi)
    out = []
    for k in range(int(length * SR)):
        t = k / SR
        env = min(1.0, t / 0.01) * math.exp(-t * 2.2)
        s = math.sin(2 * math.pi * f * t) + 0.3 * math.sin(4 * math.pi * f * t)
        out.append(s * env)
    return out


def noise_burst(length, decay, highpass):
    """Noise with a one-pole high-pass; [highpass] 0..1, higher = brighter."""
    out, low = [], 0.0
    for k in range(int(length * SR)):
        x = random.uniform(-1, 1)
        low += (x - low) * (1 - highpass)
        out.append((x - low) * math.exp(-k / SR * decay))
    return out


def snare():
    body = [
        math.sin(2 * math.pi * 190 * k / SR) * math.exp(-k / SR * 30)
        for k in range(int(0.2 * SR))
    ]
    hiss = noise_burst(0.2, 18, 0.6)
    return [0.6 * b + 0.5 * h for b, h in zip(body, hiss)]


def pad(midis, length):
    """Soft chord: a few odd harmonics per note, slow attack and release."""
    out = []
    freqs = [hz(m) for m in midis]
    for k in range(int(length * SR)):
        t = k / SR
        env = min(1.0, t / 0.6) * min(1.0, (length - t) / 0.8)
        s = 0.0
        for i, f in enumerate(freqs):
            vib = 1 + 0.002 * math.sin(2 * math.pi * 5 * t + i)
            w = 2 * math.pi * f * vib * t
            s += math.sin(w) + math.sin(3 * w) / 9 + math.sin(5 * w) / 25
        out.append(s * env / len(freqs))
    return out


def bell(midi):
    f = hz(midi)
    out = []
    for k in range(int(0.9 * SR)):
        t = k / SR
        env = min(1.0, t / 0.003) * math.exp(-t * 5)
        s = math.sin(2 * math.pi * f * t) + 0.4 * math.sin(2 * math.pi * f * 2.76 * t)
        out.append(s * env)
    return out


# Am - F - C - G, two bars each: (bass root, pad voicing, bell tones)
CHORDS = [
    (33, [57, 60, 64], [76, 79, 81, 84]),
    (29, [57, 60, 65], [77, 81, 84, 81]),
    (36, [55, 60, 64], [76, 79, 84, 79]),
    (31, [55, 59, 62], [74, 79, 83, 79]),
]

KICK, SNARE = kick(), snare()
HAT_CLOSED = noise_burst(0.05, 70, 0.97)
HAT_OPEN = noise_burst(0.18, 16, 0.97)
BELLS = {m: bell(m) for c in CHORDS for m in c[2]}

for bar in range(BARS):
    t0 = bar * BAR
    root, voicing, tones = CHORDS[(bar // 2) % len(CHORDS)]
    intro, outro = bar < 4, bar >= BARS - 2
    drums = not intro and not outro

    if bar % 2 == 0:
        add(t0, pad(voicing, 2 * BAR), 0.22)

    if bar >= 2 and not outro:
        add(t0, bass(root, 1.6 * BEAT), 0.40)
        add(t0 + 2 * BEAT, bass(root, 1.1 * BEAT), 0.36)
        add(t0 + 3.5 * BEAT, bass(root + 12, 0.45 * BEAT), 0.28)

    if drums:
        for beat in (0, 2):
            add(t0 + beat * BEAT, KICK, 0.55)
        for beat in (1, 3):
            add(t0 + beat * BEAT, SNARE, 0.30)
        for eighth in range(8):
            hat = HAT_OPEN if eighth == 7 else HAT_CLOSED
            add(t0 + eighth * BEAT / 2, hat, 0.16 if eighth % 2 else 0.10, 0.35)

    if bar >= 4 or intro:
        for eighth in range(8):
            midi = tones[eighth % 4]
            gain = 0.09 if intro else 0.12
            add(t0 + eighth * BEAT / 2, BELLS[midi], gain, -0.4 + 0.1 * (eighth % 4))

# Fade in and out, then a gentle tanh limiter.
fade_in, fade_out = int(1.0 * SR), int(4.0 * SR)
end = int(BARS * BAR * SR)
peak = max(max(abs(x) for x in left), max(abs(x) for x in right))
drive = 1.4 / peak
frames = bytearray()
for i in range(N):
    g = min(1.0, i / fade_in) * max(0.0, min(1.0, (end + SR - i) / fade_out))
    for ch in (left, right):
        s = math.tanh(ch[i] * drive) * 0.89 * g
        frames += struct.pack("<h", int(s * 32767))

out = sys.argv[1] if len(sys.argv) > 1 else "three_bands.wav"
with wave.open(out, "wb") as w:
    w.setnchannels(2)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(bytes(frames))
print(f"wrote {out}: {N / SR:.1f} s")
