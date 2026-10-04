import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';

/// Full case detail; refreshes itself when a live event for this case arrives.
final caseDetailProvider = FutureProvider.autoDispose.family<CaseDetail, String>((ref, id) async {
  final sub = ref.watch(liveChannelProvider).events.listen((m) {
    final c = m.payload['case'];
    if (m.type == 'resync_required' || (c is Map && c['id'] == id)) ref.invalidateSelf();
  });
  ref.onDispose(sub.cancel);
  return ref.watch(staffApiProvider).caseDetail(id);
}, retry: (_, _) => null);
