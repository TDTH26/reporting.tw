import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/l10n.dart';
import '../common/run_action.dart';
import '../live/queue_controller.dart';

String alertKindLabel(AgencyL10n l, String kind) => switch (kind) {
      'case.created' => l.alertCreated,
      'case.severity' => l.alertSeverity,
      'case.rerouted' => l.alertRerouted,
      'case.realert' => l.alertRealert,
      'case.transferred' => l.alertTransferred,
      _ => kind,
    };

/// Live alerts for cases arriving at (or escalating on) my desk.
class AlertBanner extends ConsumerWidget {
  const AlertBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(queueProvider.select((s) => s.alerts));
    if (alerts.isEmpty) return const SizedBox.shrink();
    final l = context.l;
    final q = ref.read(queueProvider.notifier);
    final critical = alerts.any((a) => a.severity >= 3);
    final c = critical ? UavrColors.critical : UavrColors.medium;
    return Material(
      key: const Key('alert-banner'),
      color: c.withValues(alpha: 0.12),
      child: Container(
        decoration: BoxDecoration(border: Border(left: BorderSide(color: c, width: 6))),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(children: [
          for (final a in alerts.take(4))
            Row(children: [
              Icon(Icons.notifications_active, color: UavrColors.severity(a.severity)),
              const SizedBox(width: 8),
              SeverityChip(a.severity, compact: true),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${alertKindLabel(l, a.kind)} · ${a.caseNumber} · ${clockTime(a.at)}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              TextButton(onPressed: () => context.go('/cases/${a.caseId}'), child: Text(l.open)),
              TextButton(
                onPressed: () => runAction(context, () => q.acknowledge(a.caseId)),
                child: Text(l.actAcknowledge),
              ),
              IconButton(
                tooltip: l.dismiss,
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => q.dismissAlert(a.caseId),
              ),
            ]),
          if (alerts.length > 4)
            Row(children: [
              Text(l.moreAlerts(alerts.length - 4)),
              const Spacer(),
              TextButton(onPressed: q.dismissAll, child: Text(l.dismissAll)),
            ]),
        ]),
      ),
    );
  }
}
