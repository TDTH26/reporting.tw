import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/l10n.dart';
import '../common/labels.dart';
import 'async_card.dart';
import 'charts.dart';
import 'dashboard_providers.dart';

class SourceQualityCard extends ConsumerWidget {
  const SourceQualityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    return AsyncSection<List<StatRow>>(
      title: l.sourceQuality,
      value: ref.watch(sourceQualityProvider),
      builder: (rows) => rows.isEmpty
          ? Text(l.noData)
          : DashTable(
              headers: [l.source, l.kpiIncidents, l.sensorConfirmedShare, l.falseReportRate, l.kpiRemoteIdCoverage],
              rows: [
                for (final r in rows)
                  [
                    sourceLabel(l, r.s('source_type')),
                    '${r.i('incidents')}',
                    percent(r.d('sensor_confirmed_share')),
                    percent(r.d('false_report_rate')),
                    percent(r.d('remote_id_coverage')),
                  ],
              ],
            ),
    );
  }
}

class RepeatOffendersCard extends ConsumerWidget {
  const RepeatOffendersCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    String last(StatRow r) {
      final t = DateTime.tryParse(r.s('last_seen'));
      return t == null ? '—' : dateTime(t);
    }

    return AsyncSection<({List<StatRow> bySerial, List<StatRow> byOwner})>(
      title: l.repeatOffenders,
      value: ref.watch(repeatOffendersProvider),
      builder: (v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.bySerial, style: Theme.of(context).textTheme.labelLarge),
        if (v.bySerial.isEmpty)
          Text(l.noData)
        else
          DashTable(
            headers: [l.serial, l.kpiIncidents, l.unauthorized, l.lastSeen, l.caseNumbers],
            rows: [
              for (final r in v.bySerial)
                [
                  r.s('serial'),
                  '${r.i('incidents')}',
                  '${r.i('unauthorized')}',
                  last(r),
                  (r.raw['cases'] is List ? (r.raw['cases'] as List).take(8).join(', ') : ''),
                ],
            ],
          ),
        const SizedBox(height: 12),
        Text(l.byOwner, style: Theme.of(context).textTheme.labelLarge),
        if (v.byOwner.isEmpty)
          Text(l.noData)
        else
          DashTable(
            headers: [l.owner, l.ownerRef, l.kpiIncidents, l.drones, l.unauthorized, l.lastSeen],
            rows: [
              for (final r in v.byOwner)
                [r.s('owner_name'), r.s('owner_ref'), '${r.i('incidents')}', '${r.i('drones')}', '${r.i('unauthorized')}', last(r)],
            ],
          ),
        const SizedBox(height: 6),
        Text(l.repeatOffendersAudited, style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}
