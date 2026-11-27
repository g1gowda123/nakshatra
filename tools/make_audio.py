#!/usr/bin/env python3
"""Generate Nakshatra's ambient bed and UI sounds. All original, license-free."""
import numpy as np, os, wave
from scipy.signal import butter, sosfilt

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "nakshatra", "audio")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(7)


def write_wav(name, data):
    data = np.clip(data, -1.0, 1.0)
    pcm = (data * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(pcm.tobytes())


def env(n, attack=0.01, decay=0.2, sustain=0.0):
    a = max(1, int(attack * SR))
    d = max(1, int(decay * SR))
    e = np.ones(n) * sustain
    e[:min(a, n)] = np.linspace(0, 1, min(a, n))
    if d < n:
        e[a:a + d] *= np.exp(-np.linspace(0, 5, min(d, n - a)))
    return e


def lowpass(x, cutoff, order=4):
    sos = butter(order, cutoff / (SR / 2), btype="low", output="sos")
    return sosfilt(sos, x)


def highpass(x, cutoff, order=4):
    sos = butter(order, cutoff / (SR / 2), btype="high", output="sos")
    return sosfilt(sos, x)


def note(freq, dur, amp=0.2, detune=0.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    sig = (np.sin(2 * np.pi * freq * t) * 0.6 +
           np.sin(2 * np.pi * freq * 1.003 * t + 0.4) * 0.25 +
           np.sin(2 * np.pi * freq * 0.501 * t) * 0.15)
    return sig * env(n, 0.02, dur * 0.9, 0.0) * amp


# ---------- ambient 60s seamless-ish loop ----------
DUR = 60.0
n = int(DUR * SR)
t = np.arange(n) / SR
pad = np.zeros(n)
root = 73.42  # D2
ratios = [1.0, 1.4983, 1.5, 2.0, 2.9966, 3.0, 4.0, 4.5]
for k, r in enumerate(ratios):
    lfo = 0.55 + 0.45 * np.sin(2 * np.pi * t / (15 + k * 0.0) + k * 1.7)
    pad += np.sin(2 * np.pi * root * r * t + k) * (0.10 / (1 + k * 0.35)) * lfo
pad = lowpass(pad, 1800)

wind = lowpass(rng.normal(0, 1, n), 500)
wind *= 0.035 * (0.55 + 0.45 * np.sin(2 * np.pi * t / 30 + 0.5))
amb = pad * 0.55 + wind

# distant bells, slow and sparse
for at, f in [(6.0, 587.33), (17.5, 880.0), (31.0, 659.25), (44.0, 783.99), (53.0, 587.33)]:
    i = int(at * SR)
    b = note(f, 4.0, 0.035) + note(f * 2.01, 4.0, 0.015)
    m = min(n, i + len(b))
    amb[i:m] += b[:m - i]

# make the loop click-free
xf = int(2.0 * SR)
amb[:xf] = amb[:xf] * np.linspace(0, 1, xf) + amb[-xf:] * np.linspace(1, 0, xf)
amb[-xf:] = amb[:xf][::-1] * 0.0 + amb[-xf:] * 0.0
# simpler: fade ends and rely on gentle loop
fade = int(1.5 * SR)
amb[:fade] *= np.linspace(0.0, 1.0, fade)
amb[-fade:] *= np.linspace(1.0, 0.0, fade)
amb = amb / max(np.abs(amb).max(), 0.01) * 0.7
write_wav("ambient.wav", amb)


def tone(freq, dur=0.36, amp=0.5, kind="bell"):
    n = int(dur * SR)
    t = np.arange(n) / SR
    if kind == "bell":
        sig = (np.sin(2 * np.pi * freq * t) * 0.6 +
               np.sin(2 * np.pi * freq * 2.76 * t) * 0.25 +
               np.sin(2 * np.pi * freq * 5.4 * t) * 0.1)
        e = np.exp(-t * 7.0)
    elif kind == "soft":
        sig = np.sin(2 * np.pi * freq * t) + 0.3 * np.sin(2 * np.pi * freq * 2 * t)
        e = np.exp(-t * 9.0)
    else:
        sig = np.sin(2 * np.pi * freq * t)
        e = np.exp(-t * 5.0)
    return sig * e * amp


def mix(*signals):
    n = max(len(s) for s in signals)
    out = np.zeros(n)
    for s in signals:
        out[:len(s)] += s
    return out


write_wav("click.wav", tone(720, 0.09, 0.35, "soft"))
write_wav("chime.wav", mix(tone(880, 0.8, 0.3), tone(1320, 0.7, 0.18), tone(1760, 0.5, 0.08)))
write_wav("success.wav", mix(tone(523.25, 0.5, 0.3), tone(659.25, 0.5, 0.26), tone(783.99, 0.55, 0.22), tone(1046.5, 0.8, 0.18)))
write_wav("soft_error.wav", mix(tone(196, 0.35, 0.25, "soft"), tone(174.6, 0.3, 0.18, "soft")))
# lantern: warm swell + sparkle
n = int(0.9 * SR)
t = np.arange(n) / SR
swell = np.sin(2 * np.pi * 146.83 * t) * np.exp(-t * 3.2) * 0.3
spark = np.zeros(n)
for f, at in [(1046, 0.05), (1318, 0.12), (1568, 0.2), (2093, 0.3)]:
    s = tone(f, 0.5, 0.09)
    i = int(at * SR)
    spark[i:i + len(s)] += s[:n - i] if i + len(s) > n else s
write_wav("lantern.wav", mix(swell, spark))
# whoosh
n = int(0.6 * SR)
noise = rng.normal(0, 1, n)
sos = butter(2, [300 / (SR / 2), 2400 / (SR / 2)], btype="band", output="sos")
w = sosfilt(sos, noise) * np.exp(-np.linspace(0, 4, n)) * 0.25
write_wav("whoosh.wav", w)

print("wrote", sorted(os.listdir(OUT)))
