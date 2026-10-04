import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/l10n.dart';
import '../common/labels.dart';
import '../common/providers.dart';

class TimelinePanel extends ConsumerWidget {
  const TimelinePanel({super.key, required this.events});
  final List<CaseEventView> events;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final desks = ref.watch(desksByIdProvider);
    final lang = context.lang;
    String desk(int? id) => id == null ? '—' : (desks[id]?.label(lang) ?? '#$id');
    final muted = Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

    String details(CaseEventView e) {
      final d = e.data;
      final parts = <String>[
        if (e.fromState != null && e.toState != null && e.fromState != e.toState)
          '${stateWireLabel(l, e.fromState)} → ${stateWireLabel(l, e.toState)}',
        if (e.fromDeskId != null || e.toDeskId != null) '${desk(e.fromDeskId)} → ${desk(e.toDeskId)}',
        if (d['from'] is int && d['to'] is int)
          '${severityLabel(context.u, d['from'] as int)} → ${severityLabel(context.u, d['to'] as int)}',
        if (d['into'] != null) l.mergedInto('${d['into']}'),
        if (d['from'] is String) l.mergedFrom('${d['from']}'),
        if (d['outcome'] != null) '${l.outcome}: ${d['outcome']}',
        if (d['template'] != null) '${l.template}: ${d['template']} (${d['informants'] ?? 0})',
        if (d['officers'] is List) l.officersCount((d['officers'] as List).length),
        if (d['defense'] == true) l.defenseNoteAdded,
      ];
      return parts.join(' · ');
    }

    return Section(
      title: l.panelTimeline,
      child: events.isEmpty
          ? Text(l.none)
          : Column(children: [
              for (final e in events.reversed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(eventIcon(e.action), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(eventLabel(l, e.action), style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (details(e).isNotEmpty) Text(details(e)),
                        if (e.reason != null && e.reason!.isNotEmpty) Text('${l.reason}: ${e.reason}'),
                        Text('${dateTime(e.at)} · ${e.actorType == 'system' ? l.system : (e.actorType == 'user' ? l.user : e.actorType)}',
                            style: muted),
                      ]),
                    ),
                  ]),
                ),
            ]),
    );
  }
}
