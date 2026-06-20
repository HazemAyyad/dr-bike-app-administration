"""Download and build Shiply admin notification sounds (Mixkit previews)."""

from __future__ import annotations

import os
import struct
import urllib.request
import wave

import miniaudio

# Mixkit preview URLs (Mixkit License — notification SFX).
MIXKIT = {
    'motorcycle': 'https://assets.mixkit.co/active_storage/sfx/2724/2724-preview.mp3',
    'stuck_crash': 'https://assets.mixkit.co/active_storage/sfx/2811/2811-preview.mp3',
    'ambulance': 'https://assets.mixkit.co/active_storage/sfx/1642/1642-preview.mp3',
}

MAX_SECONDS = {
    'motorcycle': 1.4,
    'stuck_crash': 1.6,
    'ambulance': 2.0,
}

OUTPUTS = {
    'motorcycle': [
        r'android/app/src/main/res/raw/shiply_motorcycle.wav',
        r'ios/Runner/shiply_motorcycle.wav',
    ],
    'stuck_crash': [
        r'android/app/src/main/res/raw/shiply_stuck.wav',
        r'ios/Runner/shiply_stuck.wav',
    ],
    'ambulance': [
        r'android/app/src/main/res/raw/shiply_returned.wav',
        r'ios/Runner/shiply_returned.wav',
    ],
}


def download(url: str, path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    urllib.request.urlretrieve(url, path)


def decode_mp3(path: str, max_seconds: float) -> tuple[list[int], int]:
    decoded = miniaudio.decode_file(path, output_format=miniaudio.SampleFormat.SIGNED16)
    samples = list(decoded.samples)
    channels = decoded.nchannels
    rate = decoded.sample_rate

    if channels > 1:
        mono: list[int] = []
        for i in range(0, len(samples), channels):
            chunk = samples[i : i + channels]
            mono.append(int(sum(chunk) / len(chunk)))
        samples = mono

    samples = samples[: int(rate * max_seconds)]
    peak = max(abs(s) for s in samples) or 1
    samples = [int(max(-32767, min(32767, s / peak * 32000))) for s in samples]

    return samples, rate


def write_wav(path: str, samples: list[int], rate: int) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, 'w') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(rate)
        wf.writeframes(b''.join(struct.pack('<h', s) for s in samples))


def main() -> None:
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    tools = os.path.dirname(__file__)

    for key, url in MIXKIT.items():
        mp3 = os.path.join(tools, f'mixkit_{key}.mp3')
        download(url, mp3)
        samples, rate = decode_mp3(mp3, MAX_SECONDS[key])
        for rel in OUTPUTS[key]:
            out = os.path.join(root, rel)
            write_wav(out, samples, rate)
            print(f'Wrote {out} ({len(samples) / rate:.2f}s)')


if __name__ == '__main__':
    main()
