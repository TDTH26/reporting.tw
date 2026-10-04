import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';

/// Tests turn the tiled maps off (no network in widget tests).
final consoleMapsEnabledProvider = Provider<bool>((ref) => true);

final desksProvider = FutureProvider<List<Desk>>((ref) => ref.watch(staffApiProvider).desks(), retry: (_, _) => null);

final desksByIdProvider = Provider<Map<int, Desk>>((ref) {
  final desks = ref.watch(desksProvider).value ?? const <Desk>[];
  return {for (final d in desks) d.id: d};
});

final templatesProvider =
    FutureProvider<List<Template>>((ref) => ref.watch(staffApiProvider).templates(), retry: (_, _) => null);

final staffZonesProvider =
    FutureProvider<List<Zone>>((ref) => ref.watch(staffApiProvider).staffZones(), retry: (_, _) => null);

final rosterProvider = FutureProvider.autoDispose<List<RosterEntry>>((ref) => ref.watch(staffApiProvider).roster(),
    retry: (_, _) => null);
