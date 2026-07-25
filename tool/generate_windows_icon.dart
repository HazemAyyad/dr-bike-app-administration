import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

void main() {
  final source = File('assets/images/logo_no_name_dark.png');
  final output = File('windows/runner/resources/app_icon.ico');
  final sourceImage = img.decodeImage(source.readAsBytesSync());
  if (sourceImage == null) {
    throw StateError('Could not decode ${source.path}');
  }

  final sizes = <int>[16, 32, 48, 64, 128, 256];
  final pngEntries = sizes.map((size) {
    final resized = img.copyResize(
      sourceImage,
      width: size,
      height: size,
      interpolation: img.Interpolation.cubic,
    );
    return _IconEntry(size, Uint8List.fromList(img.encodePng(resized)));
  }).toList(growable: false);

  output.writeAsBytesSync(_buildIco(pngEntries));
  stdout.writeln('Generated ${output.path}');
}

Uint8List _buildIco(List<_IconEntry> entries) {
  final headerSize = 6 + entries.length * 16;
  final totalSize = headerSize +
      entries.fold<int>(0, (sum, entry) => sum + entry.pngBytes.length);
  final data = ByteData(totalSize);
  var offset = 0;

  void writeUint8(int value) => data.setUint8(offset++, value);
  void writeUint16(int value) {
    data.setUint16(offset, value, Endian.little);
    offset += 2;
  }

  void writeUint32(int value) {
    data.setUint32(offset, value, Endian.little);
    offset += 4;
  }

  writeUint16(0);
  writeUint16(1);
  writeUint16(entries.length);

  var imageOffset = headerSize;
  for (final entry in entries) {
    writeUint8(entry.size == 256 ? 0 : entry.size);
    writeUint8(entry.size == 256 ? 0 : entry.size);
    writeUint8(0);
    writeUint8(0);
    writeUint16(1);
    writeUint16(32);
    writeUint32(entry.pngBytes.length);
    writeUint32(imageOffset);
    imageOffset += entry.pngBytes.length;
  }

  final bytes = data.buffer.asUint8List();
  var pngOffset = headerSize;
  for (final entry in entries) {
    bytes.setRange(
        pngOffset, pngOffset + entry.pngBytes.length, entry.pngBytes);
    pngOffset += entry.pngBytes.length;
  }
  return bytes;
}

class _IconEntry {
  const _IconEntry(this.size, this.pngBytes);

  final int size;
  final Uint8List pngBytes;
}
