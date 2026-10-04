import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// A report this device has sent: the case number and the secret follow-up token.
class StoredReport {
  StoredReport({required this.caseNumber, required this.token, required this.sentAt, this.lastStatus});
  final String caseNumber;
  final String token;
  final DateTime sentAt;
  final String? lastStatus;

  StoredReport copyWith({String? lastStatus}) =>
      StoredReport(caseNumber: caseNumber, token: token, sentAt: sentAt, lastStatus: lastStatus ?? this.lastStatus);

  Map<String, dynamic> toJson() =>
      {'case_number': caseNumber, 'token': token, 'sent_at': sentAt.toIso8601String(), 'last_status': lastStatus};

  factory StoredReport.fromJson(Map<String, dynamic> j) => StoredReport(
        caseNumber: j['case_number'] as String,
        token: j['token'] as String,
        sentAt: DateTime.parse(j['sent_at'] as String),
        lastStatus: j['last_status'] as String?,
      );
}

/// Secret storage for anonymous follow-up. Nothing here identifies the person: the device id
/// is a random per-install value, never a hardware id.
class InformantStore {
  InformantStore([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _s;

  static const _reportsKey = 'uavr.reports.v1';
  static const _deviceKey = 'uavr.device_id.v1';

  Future<String> deviceId() async {
    final existing = await _s.read(key: _deviceKey);
    if (existing != null) return existing;
    final id = const Uuid().v4();
    await _s.write(key: _deviceKey, value: id);
    return id;
  }

  /// 43-char URL-safe secret generated on the device and stored *before* the report is sent,
  /// so a retry after a dropped connection stays idempotent.
  static String newSecret() {
    final r = Random.secure();
    return base64Url.encode(List<int>.generate(32, (_) => r.nextInt(256))).replaceAll('=', '');
  }

  Future<List<StoredReport>> reports() async {
    final raw = await _s.read(key: _reportsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => StoredReport.fromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  Future<void> add(StoredReport r) async {
    final all = await reports();
    all.removeWhere((x) => x.token == r.token);
    all.add(r);
    await _s.write(key: _reportsKey, value: jsonEncode(all.map((e) => e.toJson()).toList()));
  }

  Future<void> updateStatus(String token, String status) async {
    final all = await reports();
    final i = all.indexWhere((x) => x.token == token);
    if (i < 0) return;
    all[i] = all[i].copyWith(lastStatus: status);
    await _s.write(key: _reportsKey, value: jsonEncode(all.map((e) => e.toJson()).toList()));
  }

  Future<void> remove(String token) async {
    final all = await reports()..removeWhere((x) => x.token == token);
    await _s.write(key: _reportsKey, value: jsonEncode(all.map((e) => e.toJson()).toList()));
  }
}
