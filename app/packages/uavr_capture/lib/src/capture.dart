import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uavr_api/uavr_api.dart';

import 'media.dart';

/// Photo / video via the system camera (image_picker; on web a file input with capture),
/// rotor audio via `record`.
class MediaCapture {
  MediaCapture({ImagePicker? picker}) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;
  final AudioRecorder _recorder = AudioRecorder();
  int _n = 0;

  String _slot(MediaKind k) => '${k.name}${++_n}';

  Future<CapturedMedia?> photo({bool fromGallery = false}) async {
    final f = await _picker.pickImage(
      source: fromGallery ? ImageSource.gallery : ImageSource.camera,
      requestFullMetadata: true,
    );
    return f == null ? null : ingestCapture(f, MediaKind.photo, slot: _slot(MediaKind.photo));
  }

  Future<CapturedMedia?> video({bool fromGallery = false, Duration max = const Duration(minutes: 3)}) async {
    final f = await _picker.pickVideo(source: fromGallery ? ImageSource.gallery : ImageSource.camera, maxDuration: max);
    return f == null ? null : ingestCapture(f, MediaKind.video, slot: _slot(MediaKind.video));
  }

  Future<bool> get canRecordAudio => _recorder.hasPermission();
  Future<bool> get isRecording => _recorder.isRecording();

  DateTime? _audioStart;

  Future<void> startAudio() async {
    _audioStart = DateTime.now();
    // 48 kHz AAC: enough bandwidth for rotor harmonics used by the future drone classifier.
    const cfg = RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 48000, bitRate: 128000, numChannels: 1);
    if (kIsWeb) {
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.opus), path: '');
    } else {
      final dir = await getTemporaryDirectory();
      await _recorder.start(cfg, path: '${dir.path}/rotor_${DateTime.now().millisecondsSinceEpoch}.m4a');
    }
  }

  Future<CapturedMedia?> stopAudio() async {
    final path = await _recorder.stop();
    if (path == null) return null;
    final f = kIsWeb ? XFile(path, mimeType: 'audio/webm', name: 'rotor.webm') : XFile(path);
    return ingestCapture(f, MediaKind.audio, slot: _slot(MediaKind.audio), capturedAt: _audioStart);
  }

  Stream<double> amplitude() =>
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 150)).map((a) => ((a.current + 50) / 50).clamp(0, 1));

  Future<void> dispose() => _recorder.dispose();
}
