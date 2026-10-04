import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';

import 'offline_cache.dart';

const roleFieldOfficer = 'field_officer';

/// The signed-in officer. When the server is unreachable but a login session exists, the last
/// known profile from the offline cache is used so cached assignments stay readable.
class FieldSession {
  const FieldSession(this.me, {this.offline = false});
  final Me? me;
  final bool offline;
  bool get signedIn => me != null;
  bool get isFieldOfficer => me?.has(roleFieldOfficer) == true;
}

final fieldSessionProvider = FutureProvider<FieldSession>((ref) async {
  final cache = ref.watch(offlineCacheProvider);
  try {
    final me = await ref.watch(meProvider.future);
    if (me != null) await cache.writeMe(me);
    return FieldSession(me);
  } on ApiException catch (e) {
    if (e.isNetwork || e.status >= 500) {
      final cached = await cache.readMe();
      if (cached != null) return FieldSession(cached, offline: true);
    }
    rethrow;
  }
}, retry: (_, _) => null);
