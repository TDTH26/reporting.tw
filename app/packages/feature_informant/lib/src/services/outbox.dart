import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_capture/uavr_capture.dart';

/// A report persisted before it is sent. Retrying with the same client_report_id and
/// token_secret is idempotent: the backend returns the same case.
class PendingReport {
  PendingReport({required this.request, required this.media, required this.createdAt});

  final ReportRequest request;
  final List<CapturedMedia> media;
  final DateTime createdAt;

  String get id => request.clientReportId;

  Map<String, dynamic> toJson() => {
        'request': request.toJson(),
        'created_at': createdAt.toUtc().toIso8601String(),
        'media': [
          for (final m in media)
            {
              ...m.toDeclaration().toJson(),
              'path': m.file.path,
              'name': m.file.name,
            },
        ],
      };

  factory PendingReport.fromJson(Map<String, dynamic> j) => PendingReport(
        request: ReportRequest.fromJson((j['request'] as Map).cast<String, dynamic>()),
        createdAt: DateTime.parse(j['created_at'] as String),
        media: [
          for (final m in (j['media'] as List? ?? const []).cast<Map>())
            _media(m.cast<String, dynamic>()),
        ],
      );

  static CapturedMedia _media(Map<String, dynamic> m) {
    final d = MediaDeclaration.fromJson(m);
    return CapturedMedia(
      slot: d.slot,
      kind: d.kind,
      mimeType: d.mimeType,
      sha256: d.sha256,
      sizeBytes: d.sizeBytes,
      capturedAt: d.capturedAt,
      file: XFile(m['path'] as String, name: m['name'] as String?, mimeType: d.mimeType),
    );
  }
}

/// Local queue of reports that have not reached the server yet.
abstract class Outbox {
  Future<List<PendingReport>> all();
  Future<void> put(PendingReport report);
  Future<void> remove(String clientReportId);
}

/// Outbox in secure storage (it holds the follow-up secrets). Captured files stay referenced
/// in memory too, because on web a blob URL can't be restored from storage after a reload.
class SecureOutbox implements Outbox {
  SecureOutbox([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _s;
  final _liveMedia = <String, List<CapturedMedia>>{};

  static const _key = 'uavr.informant.outbox.v1';

  @override
  Future<List<PendingReport>> all() async {
    final raw = await _s.read(key: _key);
    if (raw == null) return [];
    final list = <PendingReport>[];
    for (final e in jsonDecode(raw) as List) {
      try {
        final p = PendingReport.fromJson((e as Map).cast<String, dynamic>());
        final live = _liveMedia[p.id];
        list.add(live == null ? p : PendingReport(request: p.request, media: live, createdAt: p.createdAt));
      } catch (_) {
        // A corrupt entry must not block the rest of the queue.
      }
    }
    return list;
  }

  @override
  Future<void> put(PendingReport report) async {
    _liveMedia[report.id] = report.media;
    final list = (await all())..removeWhere((p) => p.id == report.id);
    await _write([...list, report]);
  }

  @override
  Future<void> remove(String clientReportId) async {
    _liveMedia.remove(clientReportId);
    await _write((await all())..removeWhere((p) => p.id == clientReportId));
  }

  Future<void> _write(List<PendingReport> list) =>
      _s.write(key: _key, value: jsonEncode(list.map((p) => p.toJson()).toList()));
}

final outboxProvider = Provider<Outbox>((ref) => SecureOutbox());
