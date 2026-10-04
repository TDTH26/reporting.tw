import 'dart:async';
import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uavr_api/uavr_api.dart';

import 'io_dir_stub.dart' if (dart.library.io) 'io_dir.dart' as io;
import 'media.dart';
import 'tus.dart';

enum UploadStatus { pending, uploading, done, failed }

class UploadJob {
  UploadJob({
    required this.evidenceId,
    required this.uploadUrl,
    required this.uploadToken,
    required this.path,
    required this.sizeBytes,
    required this.mimeType,
    required this.caseNumber,
    this.location,
    this.sent = 0,
    this.status = UploadStatus.pending,
    this.error,
    this.attempts = 0,
  });

  final String evidenceId, uploadUrl, uploadToken, path, mimeType, caseNumber;
  final int sizeBytes;
  String? location;
  int sent;
  UploadStatus status;
  String? error;
  int attempts;

  Map<String, dynamic> toJson() => {
        'evidence_id': evidenceId,
        'upload_url': uploadUrl,
        'upload_token': uploadToken,
        'path': path,
        'size': sizeBytes,
        'mime': mimeType,
        'case_number': caseNumber,
        'location': location,
        'sent': sent,
        'status': status.name,
        'error': error,
        'attempts': attempts,
      };

  factory UploadJob.fromJson(Map<String, dynamic> j) => UploadJob(
        evidenceId: j['evidence_id'] as String,
        uploadUrl: j['upload_url'] as String,
        uploadToken: j['upload_token'] as String,
        path: j['path'] as String,
        sizeBytes: j['size'] as int,
        mimeType: j['mime'] as String,
        caseNumber: j['case_number'] as String,
        location: j['location'] as String?,
        sent: j['sent'] as int? ?? 0,
        status: UploadStatus.values.byName(j['status'] as String),
        error: j['error'] as String?,
        attempts: j['attempts'] as int? ?? 0,
      );
}

/// Persistent evidence upload queue. Metadata goes first (the report); media follows here.
///
/// On Android the queue survives app restarts and is also drained by a WorkManager task
/// ([registerBackgroundUploads]); on web jobs live in memory for the page session.
class UploadQueue {
  /// One shared queue per isolate, so screens never overwrite each other's persisted state.
  /// The WorkManager isolate has its own instance; [run] re-reads the persisted queue so the
  /// two stay consistent.
  factory UploadQueue({TusClient? tus}) => tus == null ? (_shared ??= UploadQueue._(TusClient())) : UploadQueue._(tus);
  UploadQueue._(this._tus);
  static UploadQueue? _shared;

  static const _key = 'uavr.upload_queue.v1';
  static const maxAttempts = 20;

  final TusClient _tus;
  final _jobs = <UploadJob>[];
  final _webFiles = <String, XFile>{};
  final _changes = StreamController<List<UploadJob>>.broadcast();
  bool _loaded = false;
  Future<void>? _running;

  Stream<List<UploadJob>> get changes => _changes.stream;
  List<UploadJob> get jobs => List.unmodifiable(_jobs);

  Future<void> _load({bool force = false}) async {
    if (_loaded && !force) return;
    _loaded = true;
    if (kIsWeb) return;
    final p = await SharedPreferences.getInstance();
    await p.reload(); // pick up changes made by the background isolate
    final raw = p.getString(_key);
    _jobs
      ..clear()
      ..addAll(raw == null
          ? const []
          : (jsonDecode(raw) as List).map((e) => UploadJob.fromJson(e as Map<String, dynamic>)));
  }

  Future<void> _save() async {
    _changes.add(jobs);
    if (kIsWeb) return;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(_jobs.where((j) => j.status != UploadStatus.done).map((j) => j.toJson()).toList()));
  }

  /// Queue every captured file against the upload tickets the API returned (matched by slot).
  Future<void> enqueue(String caseNumber, List<CapturedMedia> media, List<UploadTicket> tickets) async {
    await _load();
    for (final t in tickets) {
      final m = media.where((x) => x.slot == t.slot).firstOrNull;
      if (m == null || _jobs.any((j) => j.evidenceId == t.evidenceId)) continue;
      final key = kIsWeb ? 'web:${t.evidenceId}' : m.file.path;
      if (kIsWeb) _webFiles[key] = m.file;
      _jobs.add(UploadJob(
        evidenceId: t.evidenceId,
        uploadUrl: t.uploadUrl,
        uploadToken: t.uploadToken,
        path: key,
        sizeBytes: m.sizeBytes,
        mimeType: m.mimeType,
        caseNumber: caseNumber,
      ));
    }
    await _save();
  }

  /// Upload everything pending. Safe to call repeatedly; concurrent calls share one run.
  Future<void> run() => _running ??= _runAll().whenComplete(() => _running = null);

  Future<void> _runAll() async {
    await _load(force: true);
    for (final j in _jobs.where((j) => j.status != UploadStatus.done && j.attempts < maxAttempts).toList()) {
      await _runOne(j);
    }
    _jobs.removeWhere((j) => j.status == UploadStatus.done);
    await _save();
  }

  Future<void> _runOne(UploadJob j) async {
    final file = kIsWeb ? _webFiles[j.path] : XFile(j.path);
    if (file == null) {
      j.status = UploadStatus.failed;
      j.error = 'file no longer available';
      return;
    }
    j.status = UploadStatus.uploading;
    j.attempts++;
    await _save();
    try {
      j.location ??= await _tus.create(j.uploadUrl,
          length: j.sizeBytes, uploadToken: j.uploadToken, metadata: {'filetype': j.mimeType});
      await _save();
      final from = j.sent > 0 ? await _tus.offset(j.location!) : 0;
      await _tus.upload(j.location!, file, from: from, onProgress: (sent, _) {
        j.sent = sent;
        _changes.add(jobs);
      });
      j.status = UploadStatus.done;
      j.error = null;
      if (!kIsWeb) await io.deleteFile(j.path); // the server now holds the verified copy
    } on TusException catch (e) {
      j.error = e.message;
      if (e.permanent) {
        j.status = UploadStatus.failed;
        j.attempts = maxAttempts;
      } else {
        j.status = UploadStatus.pending;
        if (e.status == 404 || e.status == 410) {
          j.location = null; // expired upload: start over
          j.sent = 0;
        }
      }
    } catch (e) {
      j.status = UploadStatus.pending;
      j.error = '$e';
    }
    await _save();
  }

  int get pendingCount => _jobs.where((j) => j.status != UploadStatus.done && j.attempts < maxAttempts).length;
}
