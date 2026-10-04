import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';

import 'my_reports.dart';
import 'outbox.dart';
import 'sensors.dart';
import 'uploads.dart';

sealed class SendOutcome {
  const SendOutcome();
}

class SendSucceeded extends SendOutcome {
  const SendSucceeded(this.response);
  final ReportResponse response;
}

/// No connection (or the server is down): the report stays in the outbox and is retried.
class SendQueued extends SendOutcome {
  const SendQueued();
}

class SendRateLimited extends SendOutcome {
  const SendRateLimited();
}

class SendRejected extends SendOutcome {
  const SendRejected(this.message);
  final String message;
}

String sha256Hex(String s) => sha256.convert(utf8.encode(s)).toString();

/// Sends reports through the local outbox, so a dropped connection or a killed app never
/// loses a report and retries stay idempotent.
class ReportSender {
  ReportSender(this._ref);
  final Ref _ref;
  final _inFlight = <String>{};
  Future<int>? _flushing;

  static const attestationTimeout = Duration(seconds: 5);

  /// Persists [report] first, then sends it.
  Future<SendOutcome> submit(PendingReport report) async {
    await _ref.read(outboxProvider).put(report);
    return _attempt(report);
  }

  /// Retries everything in the outbox. Returns how many reports were delivered.
  Future<int> flushOutbox() => _flushing ??= _flush().whenComplete(() => _flushing = null);

  Future<int> _flush() async {
    var sent = 0;
    for (final p in await _ref.read(outboxProvider).all()) {
      final outcome = await _attempt(p);
      if (outcome is SendSucceeded) sent++;
      if (outcome is SendQueued) break; // still offline: try again later
    }
    return sent;
  }

  Future<SendOutcome> _attempt(PendingReport p) async {
    if (!_inFlight.add(p.id)) return const SendQueued();
    try {
      return await _send(p);
    } finally {
      _inFlight.remove(p.id);
    }
  }

  Future<SendOutcome> _send(PendingReport p) async {
    final outbox = _ref.read(outboxProvider);
    final request = await _withAttestation(p.request);
    final ReportResponse res;
    try {
      res = await _ref.read(publicApiProvider).submitReport(request);
    } on ApiException catch (e) {
      if (e.isNetwork || e.status >= 500) return const SendQueued();
      // Not retryable as-is: 429 (rate limit), 409 (id reused), 422 (validation, e.g. too old).
      await outbox.remove(p.id);
      return e.isRateLimited ? const SendRateLimited() : SendRejected(e.message);
    }
    await _ref.read(informantStoreProvider).add(
          StoredReport(caseNumber: res.caseNumber, token: res.token, sentAt: DateTime.now().toUtc(), lastStatus: res.status),
        );
    await startUploads(_ref.read(evidenceUploadsProvider), res.caseNumber, p.media, res.uploads);
    await outbox.remove(p.id);
    _ref.invalidate(myReportsProvider);
    return SendSucceeded(res);
  }

  /// Binds a fresh Play Integrity token to this exact packet (tokens are short-lived, so it is
  /// requested on every attempt and never stored).
  Future<ReportRequest> _withAttestation(ReportRequest r) async {
    final project = _ref.read(configProvider).playCloudProjectNumber;
    final sensors = _ref.read(informantSensorsProvider);
    if (project == null || sensors.platform != 'android') return r;
    try {
      final token = await sensors
          .integrityToken(sha256Hex(r.canonicalForHash()), project)
          .timeout(attestationTimeout, onTimeout: () => null);
      return token == null ? r : r.copyWith(attestationToken: token);
    } catch (_) {
      return r; // the server scores a missing attestation; it never blocks a report
    }
  }
}

final reportSenderProvider = Provider<ReportSender>(ReportSender.new);
