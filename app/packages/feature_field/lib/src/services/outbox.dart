import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_capture/uavr_capture.dart';
import 'package:uavr_core/uavr_core.dart';
import '../json_util.dart';

enum OutboxKind { remoteId, evidence }

/// A field observation (FieldObservationIn body) not yet accepted by the server.
///
/// The body - including its client_report_id - is fixed when the officer submits, so every
/// retry is the same request and the server de-duplicates it (409 = already received).
class OutboxEntry {
  OutboxEntry({
    required this.caseId,
    required this.caseNumber,
    required this.kind,
    required this.body,
    required this.createdAt,
    this.media = const [],
    this.attempts = 0,
    this.lastError,
    this.rejected = false,
  });

  final String caseId, caseNumber;
  final OutboxKind kind;
  final Json body;
  final List<CapturedMedia> media;
  final DateTime createdAt;
  int attempts;
  String? lastError;

  /// The server refused it for good (4xx other than 409): kept so the officer can see it.
  bool rejected;

  String get id => '${body['client_report_id']}';

  Json toJson() => {
        'case_id': caseId,
        'case_number': caseNumber,
        'kind': kind.name,
        'body': body,
        'created_at': createdAt.toUtc().toIso8601String(),
        'attempts': attempts,
        'last_error': lastError,
        'rejected': rejected,
        'media': [
          for (final m in media)
            {
              'slot': m.slot,
              'kind': m.kind.name,
              'mime_type': m.mimeType,
              'sha256': m.sha256,
              'size_bytes': m.sizeBytes,
              'captured_at': m.capturedAt.toUtc().toIso8601String(),
              'path': m.file.path,
            },
        ],
      };

  factory OutboxEntry.fromJson(Json j) => OutboxEntry(
        caseId: '${j['case_id']}',
        caseNumber: '${j['case_number']}',
        kind: OutboxKind.values.byName('${j['kind']}'),
        body: obj(j['body']) ?? {},
        createdAt: parseDate(j['created_at']) ?? DateTime.now().toUtc(),
        attempts: toInt(j['attempts']) ?? 0,
        lastError: j['last_error'] as String?,
        rejected: j['rejected'] == true,
        media: listOf(
          j['media'],
          (m) => CapturedMedia(
            slot: '${m['slot']}',
            kind: MediaKind.values.byName('${m['kind']}'),
            mimeType: '${m['mime_type']}',
            sha256: '${m['sha256']}',
            sizeBytes: toInt(m['size_bytes']) ?? 0,
            capturedAt: parseDate(m['captured_at']) ?? DateTime.now().toUtc(),
            file: XFile('${m['path']}'),
          ),
        ),
      );
}

abstract class OutboxStore {
  Future<List<Json>> load();
  Future<void> save(List<Json> entries);
}

class FileOutboxStore implements OutboxStore {
  Future<File> _file() async => File('${(await getApplicationSupportDirectory()).path}/field_outbox.json');

  @override
  Future<List<Json>> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return [];
      return listOf(jsonDecode(await f.readAsString()), (e) => e);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> save(List<Json> entries) async {
    final f = await _file();
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(jsonEncode(entries), flush: true);
    await tmp.rename(f.path);
  }
}

class MemoryOutboxStore implements OutboxStore {
  List<Json> saved = [];
  @override
  Future<List<Json>> load() async => [for (final e in saved) jsonDecode(jsonEncode(e)) as Json];
  @override
  Future<void> save(List<Json> entries) async => saved = [for (final e in entries) jsonDecode(jsonEncode(e)) as Json];
}

/// Hands evidence files to the shared resumable upload queue once the server issued tickets.
abstract class EvidenceUploader {
  Future<void> upload(String caseNumber, List<CapturedMedia> media, List<UploadTicket> tickets);
}

class QueueEvidenceUploader implements EvidenceUploader {
  QueueEvidenceUploader(this.queue);
  final UploadQueue queue;

  @override
  Future<void> upload(String caseNumber, List<CapturedMedia> media, List<UploadTicket> tickets) async {
    await queue.enqueue(caseNumber, media, tickets);
    unawaited(queue.run().catchError((_) {}));
    unawaited(kickBackgroundUploads().catchError((_) {}));
  }
}

final outboxStoreProvider = Provider<OutboxStore>((ref) => FileOutboxStore());
final uploadQueueProvider = Provider<UploadQueue>((ref) => UploadQueue());
final evidenceUploaderProvider =
    Provider<EvidenceUploader>((ref) => QueueEvidenceUploader(ref.watch(uploadQueueProvider)));

enum SubmitResult { sent, queued, duplicate, rejected }

/// Persistent outbox for field observations. Every submit is written to disk before it is sent;
/// failures stay queued and are retried on app resume and every 30 s while the app is open.
class Outbox extends Notifier<List<OutboxEntry>> {
  static const retryInterval = Duration(seconds: 30);

  late Future<void> _ready;
  Timer? _timer;
  bool _retrying = false;

  @override
  List<OutboxEntry> build() {
    _ready = _load();
    _timer = Timer.periodic(retryInterval, (_) => retryAll());
    ref.onDispose(() => _timer?.cancel());
    return const [];
  }

  OutboxStore get _store => ref.read(outboxStoreProvider);

  Future<void> _load() async {
    final loaded = (await _store.load()).map(OutboxEntry.fromJson).toList();
    if (!ref.mounted) return;
    state = [...loaded, ...state.where((e) => !loaded.any((l) => l.id == e.id))];
  }

  Future<void> _persist() => _store.save([for (final e in state) e.toJson()]);

  int get pendingCount => state.where((e) => !e.rejected).length;

  /// Store and try to send now.
  Future<SubmitResult> submit(OutboxEntry e) async {
    await _ready;
    state = [...state, e];
    await _persist();
    return _send(e);
  }

  final _inFlight = <String>{};

  Future<SubmitResult> _send(OutboxEntry e) async {
    if (!_inFlight.add(e.id)) return SubmitResult.queued;
    try {
      return await _sendOnce(e);
    } finally {
      _inFlight.remove(e.id);
    }
  }

  Future<SubmitResult> _sendOnce(OutboxEntry e) async {
    final api = ref.read(staffApiProvider);
    e.attempts++;
    try {
      final tickets = await api.postFieldObservation(e.caseId, e.body);
      if (e.media.isNotEmpty && tickets.isNotEmpty) {
        await ref.read(evidenceUploaderProvider).upload(e.caseNumber, e.media, tickets);
      }
      await _remove(e.id);
      return SubmitResult.sent;
    } on ApiException catch (x) {
      if (x.isConflict) {
        await _remove(e.id); // already received (or the case closed meanwhile)
        return SubmitResult.duplicate;
      }
      e.lastError = x.isNetwork ? 'network' : '${x.status} ${x.message}';
      final transient = x.isNetwork || x.status >= 500 || x.isRateLimited || x.isUnauthorized || x.status == 408;
      if (!transient) e.rejected = true;
      await _update();
      return transient ? SubmitResult.queued : SubmitResult.rejected;
    } catch (x) {
      e.lastError = '$x';
      await _update();
      return SubmitResult.queued;
    }
  }

  Future<void> _update() async {
    if (!ref.mounted) return;
    state = [...state];
    await _persist();
  }

  Future<void> _remove(String id) async {
    if (!ref.mounted) return;
    state = state.where((x) => x.id != id).toList();
    await _persist();
  }

  /// Retry every pending (not rejected) entry, oldest first. Re-entrant calls are ignored.
  Future<void> retryAll() async {
    if (_retrying || !ref.mounted) return;
    _retrying = true;
    try {
      await _ready;
      for (final e in state.where((e) => !e.rejected).toList()) {
        if (!ref.mounted) return;
        final r = await _send(e);
        if (r == SubmitResult.queued && e.lastError == 'network') break; // still offline
      }
    } finally {
      _retrying = false;
    }
  }

  Future<void> discard(String id) => _remove(id);

  Future<void> clear() async {
    state = const [];
    await _persist();
  }
}

final outboxProvider = NotifierProvider<Outbox, List<OutboxEntry>>(Outbox.new);
