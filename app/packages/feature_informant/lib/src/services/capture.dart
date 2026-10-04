import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_capture/uavr_capture.dart';

/// Photo, video and rotor-sound capture. Every file is SHA-256 hashed at capture.
abstract class EvidenceCapture {
  Future<CapturedMedia?> photo();
  Future<CapturedMedia?> video();

  /// Starts recording; false if the microphone isn't available or allowed.
  Future<bool> startAudio();
  Future<CapturedMedia?> stopAudio();

  /// Input level 0..1 while recording.
  Stream<double> amplitude();

  /// Hashes and stores a file captured elsewhere (the aim-step photo).
  Future<CapturedMedia> ingest(XFile file, MediaKind kind, String slot);

  Future<void> dispose();
}

class DeviceCapture implements EvidenceCapture {
  final _capture = MediaCapture();

  @override
  Future<CapturedMedia?> photo() => _capture.photo();
  @override
  Future<CapturedMedia?> video() => _capture.video();

  @override
  Future<bool> startAudio() async {
    if (!await _capture.canRecordAudio) return false;
    await _capture.startAudio();
    return true;
  }

  @override
  Future<CapturedMedia?> stopAudio() => _capture.stopAudio();
  @override
  Stream<double> amplitude() => _capture.amplitude();
  @override
  Future<CapturedMedia> ingest(XFile file, MediaKind kind, String slot) => ingestCapture(file, kind, slot: slot);
  @override
  Future<void> dispose() => _capture.dispose();
}

final evidenceCaptureProvider = Provider.autoDispose<EvidenceCapture>((ref) {
  final c = DeviceCapture();
  ref.onDispose(c.dispose);
  return c;
});
