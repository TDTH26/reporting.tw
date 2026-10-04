import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_maps/uavr_maps.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../services/sensors.dart';
import '../services/settings.dart';
import '../widgets/common.dart';

final publicZonesProvider =
    FutureProvider.autoDispose<List<Zone>>((ref) => ref.watch(publicApiProvider).publicZones(), retry: noRetry);

final _myLocationProvider =
    StreamProvider.autoDispose<LocationFix>((ref) => ref.watch(informantSensorsProvider).locationFixes(), retry: noRetry);

/// Published CAA drone zones with a legend and the informant's position.
class ZonesScreen extends ConsumerStatefulWidget {
  const ZonesScreen({super.key});

  @override
  ConsumerState<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends ConsumerState<ZonesScreen> {
  final _map = MapController();
  bool _centered = false;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configProvider);
    final zones = ref.watch(publicZonesProvider);
    final me = ref.watch(_myLocationProvider).value;
    ref.listen(_myLocationProvider, (_, next) {
      final fix = next.value;
      if (fix != null && !_centered) {
        _centered = true;
        _map.move(ll(fix.position), 12);
      }
    });
    final list = zones.value ?? const <Zone>[];
    return Scaffold(
      appBar: AppBar(title: Text(context.l.zonesTitle)),
      body: Stack(children: [
        UavrMap(
          controller: _map,
          tileUrlTemplate: config.tileUrlTemplate,
          attribution: config.tileAttribution,
          children: [
            ZonesLayer(list),
            if (me != null) PointsLayer([me.position], icon: Icons.my_location, color: UavrColors.brand),
          ],
        ),
        if (zones.isLoading) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator()),
        if (zones.hasError)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_off),
                title: Text(context.u.errorNetwork),
                trailing: TextButton(
                  onPressed: () => ref.invalidate(publicZonesProvider),
                  child: Text(context.u.retry),
                ),
              ),
            ),
          ),
        Positioned(left: 12, right: 12, bottom: 28, child: _Legend(list)),
      ]),
      floatingActionButton: me == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 160),
              child: FloatingActionButton.small(
                tooltip: context.l.zonesMyLocation,
                onPressed: () => _map.move(ll(me.position), 14),
                child: const Icon(Icons.my_location),
              ),
            ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.zones);
  final List<Zone> zones;

  @override
  Widget build(BuildContext context) {
    final types = {for (final z in zones) if (z.zoneType != 'jurisdiction') z.zoneType}.toList()..sort();
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surface.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.l.zonesLegend, style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(spacing: 12, runSpacing: 6, children: [
            for (final t in types)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: UavrColors.zone(t).withValues(alpha: 0.35),
                    border: Border.all(color: UavrColors.zone(t), width: 1.5),
                  ),
                ),
                const SizedBox(width: 6),
                Text(zoneTypeLabel(context.u, t)),
              ]),
          ]),
          const SizedBox(height: 6),
          Text(context.l.zonesNote, style: theme.textTheme.bodySmall),
        ]),
      ),
    );
  }
}
