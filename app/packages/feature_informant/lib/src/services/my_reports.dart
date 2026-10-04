import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';

import 'outbox.dart';
import 'settings.dart';

/// One report stored on this device, with its live status when the server was reachable.
class MyReport {
  const MyReport(this.stored, this.live);
  final StoredReport stored;
  final InformantCase? live;

  String get status => live?.status ?? stored.lastStatus ?? 'received';
  bool get isStale => live == null;
  bool get hasOpenRequest => live?.evidenceRequests.any((r) => r.isOpen) ?? false;
}

class MyReports {
  const MyReports(this.reports, this.pending);
  final List<MyReport> reports;

  /// Reports still waiting in the outbox.
  final List<PendingReport> pending;
}

InformantCase? _pick(List<InformantCase> cases, String caseNumber) =>
    cases.where((c) => c.caseNumber == caseNumber).firstOrNull ?? cases.firstOrNull;

/// Fetches the live case for [s] and remembers its status for offline display.
Future<InformantCase?> Function(StoredReport) _fetcher(Ref ref) {
  // Read dependencies before the first await: the provider may be disposed meanwhile.
  final api = ref.read(publicApiProvider);
  final store = ref.read(informantStoreProvider);
  final lang = ref.read(apiLanguageProvider);
  return (s) async {
    final c = _pick(await api.informantCases(s.token, lang: lang), s.caseNumber);
    if (c != null && c.status != s.lastStatus) await store.updateStatus(s.token, c.status);
    return c;
  };
}

final myReportsProvider = FutureProvider.autoDispose<MyReports>((ref) async {
  ref.watch(apiLanguageProvider); // outcome texts are localised by the server
  final store = ref.watch(informantStoreProvider);
  final outbox = ref.watch(outboxProvider);
  final fetch = _fetcher(ref);
  final stored = await store.reports();
  final pending = await outbox.all();
  final reports = await Future.wait(stored.map((s) async {
    try {
      return MyReport(s, await fetch(s));
    } on ApiException {
      return MyReport(s, null); // offline: show the last known status
    }
  }));
  return MyReports(reports, pending);
}, retry: noRetry);

/// One stored report and its current server view, for the case status screen.
class CaseLookup {
  const CaseLookup(this.stored, this.live);
  final StoredReport? stored;
  final InformantCase? live;
}

final informantCaseProvider = FutureProvider.autoDispose.family<CaseLookup, String>((ref, caseNumber) async {
  ref.watch(apiLanguageProvider);
  final fetch = _fetcher(ref);
  final stored = (await ref.read(informantStoreProvider).reports()).where((r) => r.caseNumber == caseNumber).firstOrNull;
  if (stored == null) return const CaseLookup(null, null);
  return CaseLookup(stored, await fetch(stored));
}, retry: noRetry);
