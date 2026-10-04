import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_core/uavr_core.dart';

final liveStateProvider = StreamProvider<LiveState>((ref) async* {
  final ch = ref.watch(liveChannelProvider);
  yield ch.state;
  yield* ch.states;
});

/// On-duty flag of the signed-in dispatcher (starts from /me, updated by the toggle).
class DutyController extends Notifier<bool> {
  @override
  bool build() => ref.watch(meProvider.select((a) => a.value?.onDuty ?? false));

  Future<void> set(bool v) async {
    final r = await ref.read(staffApiProvider).setDuty(v);
    state = r;
  }
}

final dutyProvider = NotifierProvider<DutyController, bool>(DutyController.new);
