import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Reliable short haptic on physical devices (emulators often silent).
class HapticHelper {
  static final AudioPlayer _tickPlayer = AudioPlayer(playerId: 'picker_tick');
  static Uint8List? _tickBytes;
  static bool _tickPlayerReady = false;
  static DateTime? _lastTickAt;

  static void selection({bool sound = false}) {
    try {
      HapticFeedback.selectionClick();
      HapticFeedback.lightImpact();
      if (sound) {
        _playTick();
      }
    } catch (_) {}
  }

  static void confirm() {
    try {
      HapticFeedback.mediumImpact();
      HapticFeedback.vibrate();
    } catch (_) {}
  }

  static void _playTick() {
    final now = DateTime.now();
    final last = _lastTickAt;
    if (last != null && now.difference(last).inMilliseconds < 45) return;
    _lastTickAt = now;

    () async {
      try {
        if (!_tickPlayerReady) {
          await _tickPlayer.setPlayerMode(PlayerMode.lowLatency);
          await _tickPlayer.setReleaseMode(ReleaseMode.stop);
          _tickPlayerReady = true;
        }
        await _tickPlayer.stop();
        await _tickPlayer.play(
          BytesSource(_tickBytes ??= _buildTickWav()),
          volume: 0.45,
        );
      } catch (_) {}
    }();
  }

  static Uint8List _buildTickWav() {
    const sampleRate = 22050;
    const durationMs = 26;
    const frequency = 1400.0;
    const amplitude = 0.42;
    final sampleCount = sampleRate * durationMs ~/ 1000;
    final dataSize = sampleCount * 2;
    final bytes = Uint8List(44 + dataSize);
    final data = ByteData.view(bytes.buffer);

    void writeAscii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        bytes[offset + i] = value.codeUnitAt(i);
      }
    }

    writeAscii(0, 'RIFF');
    data.setUint32(4, 36 + dataSize, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    writeAscii(36, 'data');
    data.setUint32(40, dataSize, Endian.little);

    for (var i = 0; i < sampleCount; i++) {
      final progress = i / sampleCount;
      final envelope = math.sin(math.pi * progress);
      final sample = math.sin(2 * math.pi * frequency * i / sampleRate) *
          envelope *
          amplitude;
      data.setInt16(44 + i * 2, (sample * 32767).round(), Endian.little);
    }

    return bytes;
  }
}
