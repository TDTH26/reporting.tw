import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';

import 'live.dart';
import 'offline_cache.dart';

class AssignmentsState {
  const AssignmentsState({this.cases, this.loading = false, this.offline = false, this.updatedAt, this.error});
  final List<CaseSummary>? cases;
  final bool loading;

  /// Showing the cached list because the server could not be reached.
  final bool offline;
  final DateTime? updatedAt;
  final Object? error;
}

/// The officer's assigned open cases, cached for offline use and reloaded on live events.
class Assignments extends Notifier<AssignmentsState> {
  StreamSubscription<LiveMessage>? _sub;
  Timer? _debounce;

  @override
  AssignmentsState build() {
    final live = ref.watch(fieldLiveProvider);
    _sub = live.events.listen(_onLive, onError: (_) {});
    live.start();
    ref.onDispose(() {
      _sub?.cancel();
      _debounce?.cancel();
    });
    Future.microtask(load);
    return const AssignmentsState(loading: true);
  }

  void _onLive(LiveMessage m) {
    // The hub only forwards case events for cases this officer is assigned to (field_user_ids),
    // so any case event - or a resync - means the list may have changed.
    final relevant = m.type == 'resync_required' || m.kind == 'case.field_assigned' || liveCaseId(m) != null;
    if (!relevant) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), load);
  }

  Future<void> load() async {
    if (!ref.mounted) return;
    final api = ref.read(staffApiProvider);
    final cache = ref.read(offlineCacheProvider);
    state = AssignmentsState(cases: state.cases, loading: true, offline: state.offline, updatedAt: state.updatedAt);
    try {
      final cases = await api.assignments();
      await cache.writeAssignments(cases);
      if (!ref.mounted) return;
      state = AssignmentsState(cases: cases, updatedAt: DateTime.now());
    } catch (e) {
      final cached = await cache.readAssignments();
      if (!ref.mounted) return;
      if (cached != null) {
        state = AssignmentsState(cases: cached.value, offline: true, updatedAt: cached.savedAt, error: e);
      } else {
        state = AssignmentsState(cases: state.cases, offline: true, updatedAt: state.updatedAt, error: e);
      }
    }
  }
}

final assignmentsProvider = NotifierProvider<Assignments, AssignmentsState>(Assignments.new);
