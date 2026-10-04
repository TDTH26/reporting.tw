import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';

import 'config.dart';
import 'live_channel.dart';
import 'informant_store.dart';
import 'staff_auth.dart';

/// Overridden in each main_*.dart with AppConfig.fromEnvironment(flavor).
final configProvider = Provider<AppConfig>((ref) => throw UnimplementedError('override configProvider'));

/// Anonymous client (informant API, public endpoints).
final publicApiProvider = Provider<UavrApi>((ref) {
  final api = UavrApi(ref.watch(configProvider).apiBaseUrl);
  ref.onDispose(api.dispose);
  return api;
});

final informantStoreProvider = Provider<InformantStore>((ref) => InformantStore());

final staffAuthProvider = Provider<StaffAuth>((ref) => StaffAuth(ref.watch(configProvider)));

/// Authenticated client for staff builds.
final staffApiProvider = Provider<UavrApi>((ref) {
  final auth = ref.watch(staffAuthProvider);
  final api = UavrApi(ref.watch(configProvider).apiBaseUrl, accessToken: auth.accessToken);
  ref.onDispose(api.dispose);
  return api;
});

/// Signed-in staff member, or null. Refreshes when the signed-in user changes.
final meProvider = FutureProvider<Me?>((ref) async {
  final auth = ref.watch(staffAuthProvider);
  await auth.init();
  // Only a different signed-in user (or sign-out) refetches.
  final current = auth.userId;
  final sub = auth.changes.listen((u) {
    if (u != current) ref.invalidateSelf();
  });
  ref.onDispose(sub.cancel);
  if (!auth.isLoggedIn) return null;
  return ref.watch(staffApiProvider).me();
});

final liveChannelProvider = Provider<LiveChannel>((ref) {
  final ch = LiveChannel(ref.watch(staffApiProvider), ref.watch(staffAuthProvider).accessToken);
  ref.onDispose(ch.close);
  return ch;
});
