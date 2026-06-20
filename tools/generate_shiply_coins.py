"""Regenerate Shiply notification coin sound (Mixkit — Clinking coins #1993)."""

from __future__ import annotations

import os
import struct
import urllib.request
import wave

import miniaudio

MIXKIT_URL = 'https://assets.mixkit.co/active_storage/sfx/1993/1993-preview.mp3'
MAX_SECONDS = 1.2
OUTPUTS = [
    r'android/app/src/main/res/raw/shiply_coins.wav',
    r'ios/Runner/shiply_coins.wav',
]


def to_mono(samples: list[int], channels: int) -> list[int]:
    if channels == 1:
        return samples
    mono: list[int] = []
    for i in range(0, len(samples), channels):
        chunk = samples[i : i + channels]
        mono.append(int(sum(chunk) / len(chunk)))
    return mono


def normalize(samples: list[int]) -> list[int]:
    peak = max(abs(s) for s in samples) or 1
    return [int(max(-32767, min(32767, s / peak * 32000))) for s in samples]


def write_wav(path: str, samples: list[int], rate: int) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, 'w') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(rate)
        wf.writeframes(b''.join(struct.pack('<h', s) for s in samples))


def main() -> None:
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    tmp_mp3 = os.path.join(os.path.dirname(__file__), 'mixkit_clinking_coins.mp3')
    urllib.request.urlretrieve(MIXKIT_URL, tmp_mp3)

    decoded = miniaudio.decode_file(tmp_mp3, output_format=miniaudio.SampleFormat.SIGNED16)
    samples = to_mono(list(decoded.samples), decoded.nchannels)
    max_samples = int(decoded.sample_rate * MAX_SECONDS)
    samples = normalize(samples[:max_samples])

    for rel in OUTPUTS:
        out = os.path.join(root, rel)
        write_wav(out, samples, decoded.sample_rate)
        print(f'Wrote {out} ({len(samples)} samples @ {decoded.sample_rate} Hz)')


if __name__ == '__main__':
    main()
