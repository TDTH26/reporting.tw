import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/l10n.dart';
import 'charts.dart';
import 'dashboard_providers.dart';
import 'hotspot_card.dart';
import 'kpis.dart';
import 'tables.dart';

class DashboardsPage extends ConsumerWidget {
  const DashboardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(padding: const EdgeInsets.all(16), children: const [
      RangeBar(),
      SizedBox(height: 12),
      KpiRow(),
      SizedBox(height: 12),
      HotspotCard(),
      SizedBox(height: 12),
      TimeOfDayCard(),
      SizedBox(height: 12),
      ZonesCard(),
      SizedBox(height: 12),
      ResponseCard(),
      SizedBox(height: 12),
      SourceQualityCard(),
      SizedBox(height: 12),
      RepeatOffendersCard(),
    ]);
  }
}

class RangeBar extends ConsumerWidget {
  const RangeBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final r = ref.watch(dashboardRangeProvider);
    final set = ref.read(dashboardRangeProvider.notifier).set;
    return Row(children: [
      Text(l.navDashboards, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(width: 24),
      SegmentedButton<int>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: 7, label: Text(l.lastNDays(7))),
          ButtonSegment(value: 30, label: Text(l.lastNDays(30))),
          ButtonSegment(value: 90, label: Text(l.lastNDays(90))),
          ButtonSegment(value: 0, label: Text(l.customRange)),
        ],
        selected: {r.days ?? 0},
        onSelectionChanged: (v) async {
          final d = v.first;
          if (d > 0) {
            set(DateRange.lastDays(d));
            return;
          }
          final now = DateTime.now();
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2024),
            lastDate: now,
            initialDateRange: DateTimeRange(start: r.from, end: r.to.isAfter(now) ? now : r.to),
          );
          if (picked != null) {
            set(DateRange(picked.start, picked.end.add(const Duration(hours: 23, minutes: 59, seconds: 59))));
          }
        },
      ),
      const SizedBox(width: 16),
      Text('${dateTime(r.from)} – ${dateTime(r.to)}'),
      const Spacer(),
      IconButton(
        tooltip: l.refresh,
        icon: const Icon(Icons.refresh),
        onPressed: () {
          if (r.days != null) {
            set(DateRange.lastDays(r.days!));
            return;
          }
          for (final p in [
            summaryProvider,
            hotspotsProvider,
            timeOfDayProvider,
            zoneStatsProvider,
            responseStatsProvider,
            sourceQualityProvider,
            repeatOffendersProvider,
          ]) {
            ref.invalidate(p);
          }
        },
      ),
    ]);
  }
}
