"""Synthesises the four bundled cues into assets/sounds/. Pure python.

    python3 tool/sounds.py

- tick: a soft "tun" on the three buttons (Mark as paid, Undo, Done).
- roll: a dry ratchet clack per wheel detent.
- thud: the "kpum" as the rubber meets the paper.
- ding: three rising notes, C6 E6 G6, as the stamp lifts away.
"""
import math
import random
import struct
import wave

SR = 44100


def write(name, samples):
    with wave.open(f'assets/sounds/{name}.wav', 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b''.join(
            struct.pack('<h', int(max(-1, min(1, x)) * 32767)) for x in samples))


def env(t, attack, decay):
    return min(1.0, t / attack) * math.exp(-t / decay)


def tone(f, t, partials=((1, 1.0),)):
    return sum(a * math.sin(2 * math.pi * f * r * t) for r, a in partials)


def tick():
    random.seed(5)
    out = []
    for i in range(int(SR * 0.028)):
        t = i / SR
        body = math.sin(2 * math.pi * 1700 * t) * math.exp(-t / 0.006)
        body += 0.35 * math.sin(2 * math.pi * 900 * t) * math.exp(-t / 0.009)
        click = (random.random() * 2 - 1) * math.exp(-t / 0.0012) * 0.4
        out.append(math.tanh((body + click) * 1.2) * 0.38)
    write('tick', out)


def roll():
    random.seed(11)
    out = []
    for i in range(int(SR * 0.016)):
        t = i / SR
        body = 0.6 * math.sin(2 * math.pi * 2600 * t) * math.exp(-t / 0.0015)
        body += 0.5 * math.sin(2 * math.pi * 520 * t) * math.exp(-t / 0.005)
        snap = (random.random() * 2 - 1) * math.exp(-t / 0.0009) * 0.9
        out.append(math.tanh((body + snap) * 1.3) * 0.5)
    write('roll', out)


def thud():
    random.seed(3)
    out = []
    for i in range(int(SR * 0.17)):
        t = i / SR
        # Body: 115 Hz falling to 42 Hz, decaying, with a touch of second
        # harmonic. Slap: 7 ms of noise with a very fast decay.
        phase = 2 * math.pi * (42 * t + (115 - 42) * 0.035 * (1 - math.exp(-t / 0.035)))
        body = math.sin(phase) * math.exp(-t / 0.048)
        body += 0.25 * math.sin(2 * phase) * math.exp(-t / 0.03)
        slap = (random.random() * 2 - 1) * math.exp(-t / 0.0035) * 0.9
        out.append(math.tanh((0.85 * body + slap) * 1.4) * 0.82)
    write('thud', out)


def ding():
    out = []
    notes = [(0.0, 1046.5), (0.06, 1318.5), (0.12, 1568.0)]
    for i in range(int(SR * 0.34)):
        t = i / SR
        x = 0.0
        for t0, f in notes:
            if t >= t0:
                x += tone(f, t - t0, ((1, 1), (2, .25), (3, .08))) * env(t - t0, 0.003, 0.09)
        out.append(math.tanh(x * 0.6) * 0.5)
    write('ding', out)


if __name__ == '__main__':
    tick()
    roll()
    thud()
    ding()
    print('wrote tick, roll, thud, ding')
