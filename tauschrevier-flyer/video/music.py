"""Eigener, lizenzfreier Soundtrack für den TauschRevier-Clip.

120 BPM, D-Dur, 11 Takte (22 s). Aufbau passend zu den Szenen:
Takt 1-2 Intro (Pad + Pluck), 3-4 Beat setzt ein + Riser, 5-8 Drop mit
Melodie, 9-10 Endkarte, 11 Schlussakkord. Dazu dezente UI-Sounds.
"""
import numpy as np
from scipy.signal import butter, sosfilt, fftconvolve
from scipy.io import wavfile

SR = 44100
BPM = 120
BEAT = 60 / BPM
BAR = 4 * BEAT
BARS = 11
DUR = BARS * BAR
N = int(DUR * SR)
rng = np.random.default_rng(7)


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def lp(x, fc, order=2):
    return sosfilt(butter(order, fc, 'low', fs=SR, output='sos'), x)


def hp(x, fc, order=2):
    return sosfilt(butter(order, fc, 'high', fs=SR, output='sos'), x)


def bp(x, lo, hi, order=2):
    return sosfilt(butter(order, [lo, hi], 'band', fs=SR, output='sos'), x)


def saw(f, t):
    return 2 * ((f * t) % 1.0) - 1


def tri(f, t):
    return 2 * np.abs(saw(f, t)) - 1


def add(buf, start, sig, gain=1.0, pan=0.0):
    i = int(start * SR)
    if i >= N:
        return
    sig = sig[: N - i]
    l = np.cos((pan + 1) * np.pi / 4) * gain
    r = np.sin((pan + 1) * np.pi / 4) * gain
    buf[0, i:i + len(sig)] += sig * l
    buf[1, i:i + len(sig)] += sig * r


def env_adsr(n, a, d, s, r, sustain_len):
    a_n, d_n, r_n = int(a * SR), int(d * SR), int(r * SR)
    s_n = max(0, int(sustain_len * SR) - a_n - d_n)
    e = np.concatenate([
        np.linspace(0, 1, max(a_n, 1)),
        np.linspace(1, s, max(d_n, 1)),
        np.full(s_n, s),
        np.linspace(s, 0, max(r_n, 1)),
    ])
    return e[:n] if len(e) >= n else np.pad(e, (0, n - len(e)))


def reverb(x, secs=2.2, decay=0.55, seed=1):
    r = np.random.default_rng(seed)
    n = int(secs * SR)
    t = np.arange(n) / SR
    ir = r.standard_normal(n) * np.exp(-t / decay)
    ir = lp(ir, 6000)
    ir[: int(0.012 * SR)] = 0
    ir /= np.sqrt(np.sum(ir ** 2))
    return fftconvolve(x, ir)[: len(x)]


# ---------------------------------------------------------------- Harmonie
CHORDS = {
    'D':  ([62, 66, 69, 76], 38),
    'A':  ([61, 64, 69, 71], 33),
    'Bm': ([59, 62, 66, 69], 35),
    'G':  ([59, 62, 67, 74], 31),
}
PROG = ['D', 'A', 'Bm', 'G', 'D', 'A', 'Bm', 'G', 'G', 'A', 'D']

music = np.zeros((2, N))
pad_bus = np.zeros((2, N))
pluck_bus = np.zeros((2, N))
drum_bus = np.zeros((2, N))
lead_bus = np.zeros((2, N))
bass_bus = np.zeros((2, N))

# Pad: drei verstimmte Sägezähne je Ton, weich gefiltert
for b, name in enumerate(PROG):
    notes, _ = CHORDS[name]
    length = BAR * (2.2 if b == BARS - 1 else 1.05)
    n = int(length * SR)
    t = np.arange(n) / SR
    sig = np.zeros(n)
    for k, m in enumerate(notes):
        for det in (-0.08, 0.0, 0.08):
            sig += saw(midi(m + det), t + k * 0.13)
    sig = lp(sig, 1500 if b < 4 else 2200, order=2)
    e = env_adsr(n, 0.35, 0.4, 0.8, 0.6 if b < BARS - 1 else 2.0, length - 0.5)
    add(pad_bus, b * BAR, sig * e * 0.045, pan=-0.25)
    add(pad_bus, b * BAR + 0.011, sig * e * 0.045, pan=0.25)

# Pluck-Arpeggio in Achteln, Ping-Pong-Delay
ARP = [0, 1, 2, 3, 2, 1, 2, 3]
for b, name in enumerate(PROG[:-1]):
    notes, _ = CHORDS[name]
    for s in range(8):
        m = notes[ARP[s]] + 12
        n = int(0.5 * SR)
        t = np.arange(n) / SR
        sig = 0.6 * tri(midi(m), t) + 0.4 * saw(midi(m), t)
        sig = lp(sig * np.exp(-t / 0.11), 3200)
        vel = 0.9 if s % 2 == 0 else 0.7
        start = b * BAR + s * BEAT / 2
        add(pluck_bus, start, sig * 0.09 * vel, pan=(-0.35 if s % 2 else 0.35))
dl = int(0.375 * SR)
for rep, g in enumerate((0.38, 0.2, 0.1)):
    d = dl * (rep + 1)
    ch = rep % 2
    pluck_bus[1 - ch, d:] += pluck_bus[ch, :-d] * g * 0.6

# Bass: Grundton in Achteln ab Takt 3, Sub + weicher Mitten-Anteil
for b, name in enumerate(PROG):
    if b < 2:
        continue
    _, root = CHORDS[name]
    steps = [0] if b == BARS - 1 else range(8)
    for s in steps:
        length = BAR * 1.5 if b == BARS - 1 else BEAT / 2 * 0.92
        n = int(length * SR)
        t = np.arange(n) / SR
        f = midi(root + 12)
        sig = np.sin(2 * np.pi * f * t) + 0.35 * lp(saw(f * 2, t), 900)
        e = env_adsr(n, 0.005, 0.08, 0.7, 0.04, length - 0.04)
        add(bass_bus, b * BAR + s * BEAT / 2, sig * e * (0.16 if s % 2 else 0.2))

# Drums
def kick():
    n = int(0.45 * SR)
    t = np.arange(n) / SR
    f = 45 + 95 * np.exp(-t / 0.045)
    ph = 2 * np.pi * np.cumsum(f) / SR
    s = np.sin(ph) * np.exp(-t / 0.22)
    s[: int(0.004 * SR)] += rng.standard_normal(int(0.004 * SR)) * 0.3
    return s


def clap():
    n = int(0.35 * SR)
    t = np.arange(n) / SR
    noise = bp(rng.standard_normal(n), 900, 3500)
    e = np.zeros(n)
    for off in (0, 0.009, 0.019):
        i = int(off * SR)
        e[i:] += np.exp(-(t[: n - i]) / 0.018)
    e += 0.5 * np.exp(-t / 0.12)
    return noise * e * 0.5


def hat(open_=False):
    n = int((0.25 if open_ else 0.06) * SR)
    t = np.arange(n) / SR
    s = hp(rng.standard_normal(n), 7000) * np.exp(-t / (0.08 if open_ else 0.018))
    return s


K, C = kick(), clap()
kick_times = []
for b in range(2, BARS - 1):
    beats = (0, 2) if b < 4 else (0, 1, 2, 3)
    if b == 9:
        beats = (0, 2)
    for q in beats:
        tt = b * BAR + q * BEAT
        add(drum_bus, tt, K, 0.55)
        kick_times.append(tt)
    for q in (1, 3):
        if b >= 2:
            add(drum_bus, b * BAR + q * BEAT, C, 0.22, pan=0.05)
for b in range(1, BARS - 1):
    for s in range(8):
        if s % 2 == 1:
            add(drum_bus, b * BAR + s * BEAT / 2, hat(open_=(b >= 4 and b < 9)), 0.07, pan=0.3)
        elif b >= 4 and b < 9:
            add(drum_bus, b * BAR + s * BEAT / 2, hat(), 0.04, pan=-0.3)
# Snare-Wirbel vor dem Drop (letzte 2 Schläge Takt 4)
for i in range(8):
    tt = 3 * BAR + 2 * BEAT + i * BEAT / 4
    add(drum_bus, tt, C * 0.8, 0.06 + 0.02 * i)

# Riser vor dem Drop
rn = int(BAR * SR)
t = np.arange(rn) / SR
riser = rng.standard_normal(rn)
frames = 64
out = np.zeros(rn)
seg = rn // frames
for i in range(frames):
    fc = 400 * (40 ** (i / frames))
    chunk = hp(riser[i * seg:(i + 1) * seg + 2000], fc)[:seg]
    out[i * seg:i * seg + len(chunk)] = chunk
out *= (t / t[-1]) ** 2.2 * 0.18
add(music, 3 * BAR, out, pan=0.0)

# Lead-Melodie (weiche FM-Glocke) im Drop
MEL = {
    4: [(0, 78, 2), (2, 81, 1), (3, 78, 2), (5, 76, 1), (6, 74, 2)],
    5: [(0, 76, 2), (2, 73, 1), (3, 76, 2), (5, 81, 3)],
    6: [(0, 74, 2), (2, 78, 1), (3, 83, 2), (5, 81, 1), (6, 78, 2)],
    7: [(0, 79, 2), (2, 78, 1), (3, 76, 1), (4, 74, 2), (6, 76, 2)],
    8: [(0, 74, 2), (2, 71, 1), (3, 74, 2), (5, 79, 3)],
    9: [(0, 76, 2), (2, 73, 1), (3, 76, 1), (4, 81, 4)],
    10: [(0, 86, 8)],
}


def bell(f, length):
    n = int(length * SR)
    t = np.arange(n) / SR
    mod = np.sin(2 * np.pi * f * 2 * t) * 1.4 * np.exp(-t / 0.35)
    s = np.sin(2 * np.pi * f * t + mod) * np.exp(-t / (0.5 + length * 0.2))
    a = int(0.004 * SR)
    s[:a] *= np.linspace(0, 1, a)
    return s


for b, evs in MEL.items():
    for pos, m, dur8 in evs:
        length = dur8 * BEAT / 2 + 0.6
        add(lead_bus, b * BAR + pos * BEAT / 2, bell(midi(m), length), 0.12)

# Sidechain: Pad, Pluck und Bass ducken nach jeder Bassdrum
duck = np.ones(N)
for tt in kick_times:
    i = int(tt * SR)
    n = int(0.3 * SR)
    seg_t = np.arange(n) / SR
    curve = 1 - 0.55 * np.exp(-seg_t / 0.09)
    duck[i:i + n] = np.minimum(duck[i:i + n], curve[: len(duck[i:i + n])])
for bus in (pad_bus, pluck_bus, bass_bus):
    bus *= duck

# Hall
for bus, amt, seed in ((pad_bus, 0.35, 1), (pluck_bus, 0.3, 2), (lead_bus, 0.45, 3), (drum_bus, 0.08, 4)):
    wet = np.stack([reverb(bus[0], seed=seed), reverb(bus[1], seed=seed + 10)])
    bus += wet * amt

music += pad_bus + pluck_bus + bass_bus + drum_bus + lead_bus

# ---------------------------------------------------------------- UI-Sounds
sfx = np.zeros((2, N))


def tap(freq=1800, dec=0.03):
    n = int(0.12 * SR)
    t = np.arange(n) / SR
    return (np.sin(2 * np.pi * freq * t) * 0.6 + bp(rng.standard_normal(n), 1500, 6000) * 0.4) * np.exp(-t / dec)


def whoosh(length=0.6, up=True):
    n = int(length * SR)
    t = np.arange(n) / SR
    s = rng.standard_normal(n)
    out = np.zeros(n)
    k = 24
    seg = n // k
    for i in range(k):
        x = i / k if up else 1 - i / k
        fc = 600 * (8 ** x)
        chunk = bp(s[i * seg:(i + 1) * seg + 1500], fc * 0.6, min(fc * 1.6, 18000))[:seg]
        out[i * seg:i * seg + len(chunk)] = chunk
    e = np.sin(np.pi * t / length) ** 2
    return out * e


def chime():
    a = bell(midi(86), 1.2)
    b = bell(midi(93), 1.4)
    s = np.zeros(len(b) + int(0.11 * SR))
    s[: len(a)] += a
    s[int(0.11 * SR): int(0.11 * SR) + len(b)] += b * 0.9
    return s


EVENTS = [
    (0.10, whoosh(0.9), 0.10, 0.0),
    (5.75, whoosh(0.5, up=False), 0.08, 0.0),
    (6.00, whoosh(0.5), 0.10, -0.4),
    (6.25, whoosh(0.5), 0.10, 0.4),
    (7.00, tap(1400, 0.025), 0.35, 0.0),
    (8.00, chime(), 0.22, 0.0),
    (10.00, tap(2200), 0.25, -0.3),
    (10.50, tap(2400), 0.25, 0.3),
    (11.00, tap(2600), 0.25, 0.0),
    (12.00, tap(1800), 0.28, -0.2),
    (12.50, tap(1900), 0.28, 0.2),
    (13.00, tap(2000), 0.28, -0.2),
    (13.50, tap(2100), 0.28, 0.2),
    (13.80, whoosh(0.5), 0.09, 0.0),
    (15.70, whoosh(0.6), 0.10, 0.0),
    (17.00, tap(1600, 0.035), 0.3, 0.0),
    (17.50, tap(1800, 0.035), 0.25, 0.0),
]
for tt, sig, g, pan in EVENTS:
    add(sfx, tt, sig, g, pan)
sfx = sfx + np.stack([reverb(sfx[0], 1.2, 0.3, 21), reverb(sfx[1], 1.2, 0.3, 22)]) * 0.2

mix = music + sfx * 0.9
# Master: sanfte Sättigung, Normalisierung, Ausblenden
mix = np.tanh(mix * 1.6) / 1.6
mix /= np.max(np.abs(mix)) / 0.89
fade = int(1.2 * SR)
mix[:, -fade:] *= np.linspace(1, 0, fade) ** 2
fin = int(0.01 * SR)
mix[:, :fin] *= np.linspace(0, 1, fin)

wavfile.write('soundtrack.wav', SR, (mix.T * 32767).astype(np.int16))
print('ok', DUR, 's')
