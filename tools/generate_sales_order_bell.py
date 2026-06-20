"""Synthesize church-bell style WAV for sales order status notifications."""

from __future__ import annotations

import math
import os
import struct
import wave


def _bell_strike(freq: float, duration: float, rate: int, volume: float = 0.85) -> list[int]:
    total = int(rate * duration)
    samples: list[int] = []
    for i in range(total):
        t = i / rate
        env = math.exp(-4.2 * t / duration)
        partials = (
            math.sin(2 * math.pi * freq * t) * 0.55
            + math.sin(2 * math.pi * freq * 2.01 * t) * 0.28
            + math.sin(2 * math.pi * freq * 2.62 * t) * 0.12
            + math.sin(2 * math.pi * freq * 3.91 * t) * 0.05
        )
        sample = int(max(-32767, min(32767, partials * env * volume * 32767)))
        samples.append(sample)
    return samples


def _silence(seconds: float, rate: int) -> list[int]:
    return [0] * int(rate * seconds)


def build_church_bell(rate: int = 44100) -> list[int]:
    return (
        _bell_strike(523.25, 1.15, rate, 0.82)
        + _silence(0.12, rate)
        + _bell_strike(659.25, 1.35, rate, 0.88)
        + _silence(0.18, rate)
        + _bell_strike(783.99, 1.6, rate, 0.75)
    )


def write_wav(path: str, samples: list[int], rate: int) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, 'w') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(rate)
        wf.writeframes(b''.join(struct.pack('<h', s) for s in samples))


def main() -> None:
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    rate = 44100
    samples = build_church_bell(rate)
    outputs = [
        os.path.join(root, 'android/app/src/main/res/raw/sales_order_church_bell.wav'),
        os.path.join(root, 'ios/Runner/sales_order_church_bell.wav'),
    ]
    for path in outputs:
        write_wav(path, samples, rate)
        print('Wrote', path)


if __name__ == '__main__':
    main()
