import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_maps/uavr_maps.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/console_map.dart';
import '../common/l10n.dart';
import 'async_card.dart';
import 'dashboard_providers.dart';

List<String> dowLabels(AgencyL10n l) => [l.dowMon, l.dowTue, l.dowWed, l.dowThu, l.dowFri, l.dowSat, l.dowSun];

class HotspotCard extends ConsumerWidget {
  const HotspotCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final u = context.u;
    final f = ref.watch(hotspotFilterProvider);
    final set = ref.read(hotspotFilterProvider.notifier).set;
    final cells = ref.watch(hotspotsProvider);
    final dows = dowLabels(l);
    final filters = Wrap(spacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
      DropdownButton<int>(
        value: f.severityMin,
        items: [
          DropdownMenuItem(value: 1, child: Text(l.allSeverities)),
          DropdownMenuItem(value: 2, child: Text('≥ ${u.severityMedium}')),
          DropdownMenuItem(value: 3, child: Text(u.severityCritical)),
        ],
        onChanged: (v) => set(HotspotFilter(severityMin: v ?? 1, hour: f.hour, dow: f.dow)),
      ),
      DropdownButton<int?>(
        value: f.hour,
        items: [
          DropdownMenuItem(value: null, child: Text(l.allHours)),
          for (var h = 0; h < 24; h++) DropdownMenuItem(value: h, child: Text('${h.toString().padLeft(2, '0')}:00')),
        ],
        onChanged: (v) => set(HotspotFilter(severityMin: f.severityMin, hour: v, dow: f.dow)),
      ),
      DropdownButton<int?>(
        value: f.dow,
        items: [
          DropdownMenuItem(value: null, child: Text(l.allDays)),
          for (var d = 1; d <= 7; d++) DropdownMenuItem(value: d, child: Text(dows[d - 1])),
        ],
        onChanged: (v) => set(HotspotFilter(severityMin: f.severityMin, hour: f.hour, dow: v)),
      ),
    ]);
    return AsyncSection(
      title: l.hotspots,
      trailing: filters,
      value: cells,
      minHeight: 420,
      builder: (cs) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 420,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ConsoleMap(children: [HeatmapLayer(cs)]),
          ),
        ),
        const SizedBox(height: 6),
        Text(l.hotspotLegend(cs.length, cs.fold<int>(0, (a, c) => a + c.count))),
      ]),
    );
  }
}
