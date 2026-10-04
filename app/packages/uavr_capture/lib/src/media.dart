import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uavr_api/uavr_api.dart';

import 'io_dir_stub.dart' if (dart.library.io) 'io_dir.dart' as io;

/// A piece of evidence captured on this device. The SHA-256 is computed at capture time over the
/// exact bytes that will be uploaded; the server re-hashes after upload (chain of custody).
class CapturedMedia {
  CapturedMedia({
    required this.slot,
    required this.kind,
    required this.mimeType,
    required this.sha256,
    required this.sizeBytes,
    required this.capturedAt,
    required this.file,
  });

  final String slot;
  final MediaKind kind;
  final String mimeType;
  final String sha256;
  final int sizeBytes;
  final DateTime capturedAt;

  /// On Android a path inside the app's private evidence folder; on web a blob-backed XFile.
  final XFile file;

  MediaDeclaration toDeclaration() => MediaDeclaration(
        slot: slot,
        kind: kind,
        mimeType: mimeType,
        sha256: sha256,
        sizeBytes: sizeBytes,
        capturedAt: capturedAt,
      );
}

Future<String> sha256OfStream(Stream<List<int>> s) async {
  final out = _DigestSink();
  final input = sha256.startChunkedConversion(out);
  await for (final chunk in s) {
    input.add(chunk);
  }
  input.close();
  return out.value.toString();
}

class _DigestSink implements Sink<Digest> {
  late Digest value;
  @override
  void add(Digest data) => value = data;
  @override
  void close() {}
}

String mimeFor(MediaKind kind, String name) {
  final ext = name.split('.').last.toLowerCase();
  return switch (ext) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'heic' => 'image/heic',
    'webp' => 'image/webp',
    'mp4' => 'video/mp4',
    'mov' => 'video/quicktime',
    'webm' => kind == MediaKind.audio ? 'audio/webm' : 'video/webm',
    'm4a' || 'aac' => 'audio/mp4',
    'wav' => 'audio/wav',
    'ogg' || 'opus' => 'audio/ogg',
    _ => switch (kind) {
        MediaKind.photo => 'image/jpeg',
        MediaKind.video => 'video/mp4',
        MediaKind.audio => 'audio/mp4',
      },
  };
}

/// Moves a freshly captured file into the private evidence folder (so the OS cache cleaner
/// can't delete it before upload) and hashes it.
Future<CapturedMedia> ingestCapture(XFile src, MediaKind kind, {required String slot, DateTime? capturedAt}) async {
  final at = (capturedAt ?? DateTime.now()).toUtc();
  XFile file = src;
  if (!kIsWeb) {
    final dir = await getApplicationSupportDirectory();
    final name = '${at.millisecondsSinceEpoch}_$slot.${src.name.split('.').last}';
    final dest = '${dir.path}/evidence/$name';
    await _ensureDir('${dir.path}/evidence');
    await src.saveTo(dest);
    file = XFile(dest, name: name);
  }
  final digest = await sha256OfStream(file.openRead());
  return CapturedMedia(
    slot: slot,
    kind: kind,
    mimeType: src.mimeType ?? mimeFor(kind, src.name.isEmpty ? src.path : src.name),
    sha256: digest,
    sizeBytes: await file.length(),
    capturedAt: at,
    file: file,
  );
}

Future<CapturedMedia> ingestBytes(Uint8List bytes, MediaKind kind, String mimeType, {required String slot}) async {
  final at = DateTime.now().toUtc();
  return CapturedMedia(
    slot: slot,
    kind: kind,
    mimeType: mimeType,
    sha256: sha256.convert(bytes).toString(),
    sizeBytes: bytes.length,
    capturedAt: at,
    file: XFile.fromData(bytes, mimeType: mimeType, name: '$slot.bin'),
  );
}

Future<void> _ensureDir(String path) => io.ensureDir(path);
