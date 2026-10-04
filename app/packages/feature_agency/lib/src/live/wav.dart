import 'dart:math' as math;
import 'dart:typed_data';

/// Generates a short 16-bit mono PCM WAV of sine beeps (no audio asset files needed).
Uint8List beepWav({
  List<double> freqs = const [880, 660],
  double toneSec = 0.16,
  double gapSec = 0.06,
  int sampleRate = 22050,
  double volume = 0.55,
}) {
  final toneN = (toneSec * sampleRate).round(), gapN = (gapSec * sampleRate).round();
  final total = freqs.length * (toneN + gapN);
  final data = ByteData(44 + total * 2);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  data.setUint32(4, 36 + total * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  str(36, 'data');
  data.setUint32(40, total * 2, Endian.little);
  var o = 44;
  for (final f in freqs) {
    for (var i = 0; i < toneN; i++) {
      // Short linear fade in/out avoids clicks.
      final env = math.min(1.0, math.min(i, toneN - i) / (sampleRate * 0.01));
      final v = math.sin(2 * math.pi * f * i / sampleRate) * volume * env;
      data.setInt16(o, (v * 32767).round(), Endian.little);
      o += 2;
    }
    for (var i = 0; i < gapN; i++) {
      data.setInt16(o, 0, Endian.little);
      o += 2;
    }
  }
  return data.buffer.asUint8List();
}
