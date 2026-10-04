import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/l10n.dart';
import '../common/labels.dart';
import '../common/run_action.dart';
import 'dashboard_providers.dart';

class KpiRow extends ConsumerWidget {
  const KpiRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final u = context.u;
    final s = ref.watch(summaryProvider);
    return s.when(
      loading: () => const SizedBox(height: 96, child: LoadingView()),
      error: (e, _) => SizedBox(height: 120, child: ErrorView(errorText(e), onRetry: () => ref.invalidate(summaryProvider))),
      data: (a) {
        double? share(int n) => a.incidents == 0 ? null : n / a.incidents;
        final tiles = <Widget>[
          KpiTile(label: l.kpiIncidents, value: '${a.incidents}', sub: l.kpiObservations(a.observations)),
          KpiTile(label: u.severityCritical, value: '${a.critical}', sub: percent(share(a.critical)), accent: UavrColors.critical),
          KpiTile(label: u.severityMedium, value: '${a.medium}', sub: percent(share(a.medium)), accent: UavrColors.medium),
          KpiTile(label: u.severityLow, value: '${a.low}', sub: percent(share(a.low)), accent: UavrColors.low),
          KpiTile(label: l.kpiAuthorizedShare, value: percent(share(a.authorized)), sub: '${a.authorized}'),
          KpiTile(label: l.kpiRemoteIdCoverage, value: percent(share(a.withRemoteId)), sub: '${a.withRemoteId}'),
          KpiTile(label: l.kpiSensorConfirmed, value: '${a.sensorConfirmed}', sub: percent(share(a.sensorConfirmed))),
          KpiTile(label: l.kpiFalseReports, value: '${a.falseReports}', sub: percent(share(a.falseReports))),
          KpiTile(label: l.kpiAckP50, value: durationLabel(a.ackP50), sub: l.minSec),
          KpiTile(label: l.kpiAckP90, value: durationLabel(a.ackP90), sub: l.minSec),
        ];
        return Wrap(spacing: 12, runSpacing: 12, children: tiles);
      },
    );
  }
}

/// Stat tile: label, hero number, one secondary line. Status accent is a bar + the label, never colour alone.
class KpiTile extends StatelessWidget {
  const KpiTile({super.key, required this.label, required this.value, this.sub, this.accent});
  final String label, value;
  final String? sub;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SizedBox(
      width: 168,
      child: Card(
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: accent == null
              ? null
              : BoxDecoration(border: Border(left: BorderSide(color: accent!, width: 4))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: t.textTheme.labelMedium?.copyWith(color: t.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(value, style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()])),
            if (sub != null) Text(sub!, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}
