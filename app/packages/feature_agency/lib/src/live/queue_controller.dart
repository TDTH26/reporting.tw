import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';

import '../common/access.dart';
import '../common/providers.dart';
import 'alert_sound.dart';

enum QueueSort { severity, caseNumber, state, age, observations, confidence }

const defaultQueueStates = {CaseState.newCase, CaseState.acknowledged, CaseState.investigating};

class QueueAlert {
  QueueAlert({required this.caseId, required this.caseNumber, required this.severity, required this.kind, required this.at});
  final String caseId, caseNumber, kind;
  final int severity;
  final DateTime at;
}

class QueueState {
  const QueueState({
    this.loading = false,
    this.error,
    this.cases = const [],
    this.seq = 0,
    this.scope = 'desk',
    this.states = defaultQueueStates,
    this.highlighted = const {},
    this.alerts = const [],
    this.selectedId,
    this.sort = QueueSort.severity,
    this.ascending = false,
  });

  final bool loading;
  final Object? error;
  final List<CaseSummary> cases;
  final int seq;
  final String scope;
  final Set<CaseState> states;
  final Set<String> highlighted;
  final List<QueueAlert> alerts;
  final String? selectedId;
  final QueueSort sort;
  final bool ascending;

  static const _keep = Object();

  QueueState copyWith({
    bool? loading,
    Object? error = _keep,
    List<CaseSummary>? cases,
    int? seq,
    String? scope,
    Set<CaseState>? states,
    Set<String>? highlighted,
    List<QueueAlert>? alerts,
    Object? selectedId = _keep,
    QueueSort? sort,
    bool? ascending,
  }) =>
      QueueState(
        loading: loading ?? this.loading,
        error: identical(error, _keep) ? this.error : error,
        cases: cases ?? this.cases,
        seq: seq ?? this.seq,
        scope: scope ?? this.scope,
        states: states ?? this.states,
        highlighted: highlighted ?? this.highlighted,
        alerts: alerts ?? this.alerts,
        selectedId: identical(selectedId, _keep) ? this.selectedId : selectedId as String?,
        sort: sort ?? this.sort,
        ascending: ascending ?? this.ascending,
      );

  /// Cases in display order (default matches the backend: severity, ack deadline, newest).
  List<CaseSummary> get sorted {
    final l = [...cases];
    int defaultOrder(CaseSummary a, CaseSummary b) {
      final s = b.severity.compareTo(a.severity);
      if (s != 0) return s;
      final da = a.ackDeadline, db = b.ackDeadline;
      if (da != null && db != null && da != db) return da.compareTo(db);
      if (da != null && db == null) return -1;
      if (da == null && db != null) return 1;
      return (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0));
    }

    int cmp(CaseSummary a, CaseSummary b) {
      final r = switch (sort) {
        QueueSort.severity => -defaultOrder(a, b),
        QueueSort.caseNumber => a.caseNumber.compareTo(b.caseNumber),
        QueueSort.state => a.state.index.compareTo(b.state.index),
        QueueSort.age => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
        QueueSort.observations => a.observationCount.compareTo(b.observationCount),
        QueueSort.confidence => a.confidence.compareTo(b.confidence),
      };
      return ascending ? r : -r;
    }

    l.sort(cmp);
    return l;
  }

  CaseSummary? get selected => selectedId == null ? null : cases.where((c) => c.id == selectedId).firstOrNull;
}

/// The dispatcher's queue with live updates. Owns the live channel start: load REST -> seq ->
/// `liveChannel.start(fromSeq: seq)`.
class QueueController extends Notifier<QueueState> {
  StreamSubscription<LiveMessage>? _sub;
  Timer? _repeat;
  static final _started = Expando<bool>('liveStarted');

  @override
  QueueState build() {
    final meId = ref.watch(meProvider.select((a) => a.value?.id));
    ref.onDispose(() {
      _sub?.cancel();
      _repeat?.cancel();
    });
    final me = ref.read(meProvider).value;
    if (meId == null || me == null || !canReadCases(me)) return const QueueState();
    final scope = me.desk != null ? 'desk' : (me.has('national') ? 'all' : 'agency');
    _sub = ref.read(liveChannelProvider).events.listen(onLive);
    Future.microtask(() => reload(startLive: true));
    return QueueState(loading: true, scope: scope);
  }

  Me get _me => ref.read(meProvider).value!;
  UavrApi get _api => ref.read(staffApiProvider);

  Future<void> reload({bool startLive = false}) async {
    if (!ref.mounted) return;
    state = state.copyWith(loading: true);
    try {
      final res = await _api.queue(scope: state.scope, states: state.states.map((s) => s.wire).toList());
      if (!ref.mounted) return;
      state = state.copyWith(loading: false, error: null, cases: res.cases, seq: res.seq);
      final live = ref.read(liveChannelProvider);
      if (startLive && _started[live] != true) {
        _started[live] = true;
        live.start(fromSeq: res.seq);
      }
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(loading: false, error: e);
    }
  }

  void setScope(String scope) {
    if (scope == state.scope) return;
    state = state.copyWith(scope: scope);
    reload();
  }

  void toggleState(CaseState s) {
    final next = {...state.states};
    if (!next.remove(s)) next.add(s);
    if (next.isEmpty) return;
    state = state.copyWith(states: next);
    reload();
  }

  void setSort(QueueSort s) {
    state = s == state.sort ? state.copyWith(ascending: !state.ascending) : state.copyWith(sort: s, ascending: false);
  }

  void select(String? id) {
    final hl = {...state.highlighted}..remove(id);
    state = state.copyWith(selectedId: id, highlighted: hl);
  }

  /// Move selection by [delta] rows in display order.
  void moveSelection(int delta) {
    final list = state.sorted;
    if (list.isEmpty) return;
    final i = list.indexWhere((c) => c.id == state.selectedId);
    final next = i < 0 ? (delta > 0 ? 0 : list.length - 1) : (i + delta).clamp(0, list.length - 1);
    select(list[next].id);
  }

  bool _inScope(Me me, CaseSummary c) {
    if (state.scope == 'desk' && me.desk != null) return c.deskId == me.desk!.id || c.redacted;
    return true;
  }

  /// Insert/replace/drop one case according to the current filter.
  void upsert(CaseSummary raw, {bool remove = false}) {
    final me = _me;
    final c = raw.withCanAct(computeCanAct(me, raw));
    final cases = [...state.cases];
    final i = cases.indexWhere((x) => x.id == c.id);
    final keep = !remove && state.states.contains(c.state) && _inScope(me, c);
    if (i >= 0) {
      if (keep) {
        cases[i] = c;
      } else {
        cases.removeAt(i);
      }
    } else if (keep) {
      cases.add(c);
    }
    var alerts = state.alerts;
    var hl = state.highlighted;
    if (!keep || c.state != CaseState.newCase) {
      alerts = alerts.where((a) => a.caseId != c.id).toList();
      if (!keep) hl = {...hl}..remove(c.id);
    }
    state = state.copyWith(cases: cases, alerts: alerts, highlighted: hl);
    _syncRepeat();
  }

  void onLive(LiveMessage m) {
    if (!ref.mounted) return;
    if (m.type == 'resync_required') {
      reload();
      return;
    }
    if (m.type != 'event') return;
    if (m.kind == 'zones.changed') {
      ref.invalidate(staffZonesProvider);
      return;
    }
    final raw = m.payload['case'];
    if (raw is! Map) return;
    final c = CaseSummary.fromJson(Map<String, dynamic>.from(raw));
    upsert(c, remove: m.kind == 'case.merged');
    final me = _me;
    if (m.isAlert && me.desk != null && c.deskId == me.desk!.id && state.cases.any((x) => x.id == c.id)) {
      final alert = QueueAlert(caseId: c.id, caseNumber: c.caseNumber, severity: c.severity, kind: m.kind!, at: DateTime.now());
      state = state.copyWith(
        alerts: [alert, ...state.alerts.where((a) => a.caseId != c.id)],
        highlighted: {...state.highlighted, c.id},
      );
      ref.read(alertSoundProvider).play(critical: c.severity >= 3);
      _syncRepeat();
    }
  }

  /// Critical alerts repeat until acknowledged or dismissed.
  void _syncRepeat() {
    final critical = state.alerts.any((a) => a.severity >= 3);
    if (critical && _repeat == null) {
      _repeat = Timer.periodic(const Duration(seconds: 5), (_) {
        if (ref.mounted) ref.read(alertSoundProvider).play(critical: true);
      });
    } else if (!critical) {
      _repeat?.cancel();
      _repeat = null;
    }
  }

  void dismissAlert(String caseId) {
    state = state.copyWith(alerts: state.alerts.where((a) => a.caseId != caseId).toList());
    _syncRepeat();
  }

  void dismissAll() {
    state = state.copyWith(alerts: const []);
    _syncRepeat();
  }

  Future<CaseSummary> acknowledge(String caseId) async {
    final s = await _api.acknowledge(caseId);
    upsert(s);
    dismissAlert(caseId);
    state = state.copyWith(highlighted: {...state.highlighted}..remove(caseId));
    return s;
  }
}

final queueProvider = NotifierProvider<QueueController, QueueState>(QueueController.new);
