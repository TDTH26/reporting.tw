import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_core/uavr_core.dart';

import 'sensors.dart';

class PositionShareState {
  const PositionShareState({this.enabled = true, this.openCases = 0, this.foreground = true, this.lastSent});

  /// Officer's toggle (app bar). Defaults to on.
  final bool enabled;

  /// Number of case screens currently open: sharing only runs while a case is open.
  final int openCases;
  final bool foreground;
  final DateTime? lastSent;

  bool get sharing => enabled && openCases > 0 && foreground;

  PositionShareState copyWith({bool? enabled, int? openCases, bool? foreground, DateTime? lastSent}) =>
      PositionShareState(
        enabled: enabled ?? this.enabled,
        openCases: openCases ?? this.openCases,
        foreground: foreground ?? this.foreground,
        lastSent: lastSent ?? this.lastSent,
      );
}

/// Posts the officer's GPS fix to /v1/field/position every 30 s while a case is open, the
/// toggle is on and the app is in the foreground.
class PositionSharing extends Notifier<PositionShareState> {
  static const interval = Duration(seconds: 30);
  Timer? _timer;

  @override
  PositionShareState build() {
    ref.onDispose(() => _timer?.cancel());
    return const PositionShareState();
  }

  void _set(PositionShareState s) {
    if (!ref.mounted) return;
    state = s;
    if (s.sharing && _timer == null) {
      _timer = Timer.periodic(interval, (_) => _post());
      _post();
    } else if (!s.sharing) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _update(PositionShareState Function(PositionShareState s) f) {
    if (ref.mounted) _set(f(state));
  }

  void toggle() => _update((s) => s.copyWith(enabled: !s.enabled));
  void caseOpened() => _update((s) => s.copyWith(openCases: s.openCases + 1));
  void caseClosed() => _update((s) => s.copyWith(openCases: s.openCases > 0 ? s.openCases - 1 : 0));
  void setForeground(bool fg) => _update((s) => s.copyWith(foreground: fg));

  Future<void> _post() async {
    if (!ref.mounted || !state.sharing) return;
    try {
      final fix = await ref.read(myFixProvider.notifier).current();
      if (fix == null || !ref.mounted) return;
      await ref.read(staffApiProvider).postPosition(fix.position, accuracyM: fix.accuracyM);
      if (ref.mounted) state = state.copyWith(lastSent: DateTime.now());
    } catch (_) {
      // Best effort; the next tick tries again.
    }
  }
}

final positionSharingProvider = NotifierProvider<PositionSharing, PositionShareState>(PositionSharing.new);
