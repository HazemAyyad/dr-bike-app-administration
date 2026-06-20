"""Build Shiply delivered notification: metallic coins + end whistle."""

from __future__ import annotations

import os
import struct
import urllib.request
import wave

import miniaudio

COINS_URL = 'https://assets.mixkit.co/active_storage/sfx/1993/1993-preview.mp3'
WHISTLE_URL = 'https://assets.mixkit.co/active_storage/sfx/614/614-preview.mp3'
GAP_MS = 90
MAX_COINS_SECONDS = 1.0
MAX_WHISTLE_SECONDS = 1.4
OUTPUTS = [
    r'android/app/src/main/res/raw/shiply_delivered.wav',
    r'ios/Runner/shiply_delivered.wav',
]


def download(url: str, path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    urllib.request.urlretrieve(url, path)


def decode_mp3(path: str, max_seconds: float | None = None) -> tuple[list[int], int]:
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

    if max_seconds is not None:
        samples = samples[: int(rate * max_seconds)]

    return samples, rate


def resample(samples: list[int], from_rate: int, to_rate: int) -> list[int]:
    if from_rate == to_rate or not samples:
        return samples

    out_len = int(len(samples) * to_rate / from_rate)
    if out_len <= 0:
        return []

    out: list[int] = []
    for i in range(out_len):
        src_pos = i * from_rate / to_rate
        left = int(src_pos)
        right = min(left + 1, len(samples) - 1)
        frac = src_pos - left
        value = samples[left] * (1 - frac) + samples[right] * frac
        out.append(int(value))
    return out


def normalize(samples: list[int], peak_target: int = 32000) -> list[int]:
    peak = max(abs(s) for s in samples) or 1
    return [int(max(-32767, min(32767, s / peak * peak_target))) for s in samples]


def mix_overlay(base: list[int], overlay: list[int], start_index: int, overlay_gain: float = 0.95) -> list[int]:
    out = base[:]
    for i, sample in enumerate(overlay):
        idx = start_index + i
        if idx >= len(out):
            out.append(int(sample * overlay_gain))
        else:
            mixed = out[idx] + int(sample * overlay_gain)
            out[idx] = max(-32767, min(32767, mixed))
    if start_index + len(overlay) > len(out):
        out.extend(int(s * overlay_gain) for s in overlay[len(out) - start_index :])
    return out


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
    coins_mp3 = os.path.join(tools, 'mixkit_clinking_coins.mp3')
    whistle_mp3 = os.path.join(tools, 'mixkit_end_whistle.mp3')

    if not os.path.exists(coins_mp3):
        download(COINS_URL, coins_mp3)
    download(WHISTLE_URL, whistle_mp3)

    coins, coins_rate = decode_mp3(coins_mp3, MAX_COINS_SECONDS)
    whistle, whistle_rate = decode_mp3(whistle_mp3, MAX_WHISTLE_SECONDS)

    target_rate = coins_rate
    whistle = resample(whistle, whistle_rate, target_rate)

    coins = normalize(coins, 30000)
    whistle = normalize(whistle, 28000)

    gap = [0] * int(target_rate * (GAP_MS / 1000))
    combined = coins + gap + whistle

    # Slight overlap: whistle starts during last coin tail for a "together" feel.
    overlap_start = max(0, len(coins) - int(target_rate * 0.12))
    combined = mix_overlay(coins + gap + [0] * len(whistle), whistle, overlap_start, overlay_gain=0.85)
    combined = normalize(combined, 32000)

    for rel in OUTPUTS:
        out = os.path.join(root, rel)
        write_wav(out, combined, target_rate)
        print(f'Wrote {out} ({len(combined) / target_rate:.2f}s)')


if __name__ == '__main__':
    main()
