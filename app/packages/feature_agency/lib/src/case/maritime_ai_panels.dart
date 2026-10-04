import 'package:flutter/material.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/l10n.dart';
import '../common/labels.dart';

/// Advisory AI triage of the incident's photos / camera frames (Featherless, Qwen3-VL).
class AiPanel extends StatelessWidget {
  const AiPanel({super.key, required this.summary});
  final CaseSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final a = summary.aiAssessment;
    String pct(Object? v) => v is num ? '${(v * 100).round()}%' : '—';
    return Section(
      key: const Key('ai-panel'),
      title: l.panelAi,
      trailing: const Icon(Icons.auto_awesome_outlined, size: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (a == null)
          Text(l.aiNone)
        else ...[
          Row(children: [
            Text(l.aiThreat),
            const SizedBox(width: 8),
            SeverityChip((a['threat_level'] as num?)?.toInt() ?? 1, compact: true),
          ]),
          const SizedBox(height: 6),
          KeyValue(l.aiCraft, craftTypeLabel(l, a['craft_type'] as String?)),
          KeyValue(l.aiSilhouette, a['silhouette'] as String? ?? a['description'] as String?),
          if (a['unmanned_likelihood'] != null) KeyValue(l.aiUnmanned, pct(a['unmanned_likelihood'])),
          if (a['matches_report'] != null) KeyValue(l.aiMatchesReport, a['matches_report'] == true ? '✓' : '✗'),
          if (a['spam_likelihood'] != null) KeyValue(l.aiSpam, pct(a['spam_likelihood'])),
          KeyValue(l.aiConfidence, pct(a['confidence'])),
          for (final r in (a['threat_reasons'] as List? ?? const []))
            Row(children: [const Icon(Icons.chevron_right, size: 16), Expanded(child: Text('$r'))]),
          KeyValue(l.aiModel, '${a['model'] ?? ''} · ${a['prompt_version'] ?? ''}', mono: true),
        ],
        const SizedBox(height: 8),
        Text(l.aiAdvisoryNote, style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}

/// AIS identity / dark-vessel status and any non-cooperative MDA track near a surface contact.
class MaritimePanel extends StatelessWidget {
  const MaritimePanel({super.key, required this.summary});
  final CaseSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final vm = summary.vesselMatch ?? const {};
    final mda = vm['mda_track'] as Map?;
    return Section(
      key: const Key('maritime-panel'),
      title: l.panelMaritime,
      trailing: Icon(domainIcon(summary.craftDomain), size: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        KeyValue(l.craftDomain, '${domainLabel(l, summary.craftDomain)} · ${craftTypeLabel(l, summary.craftType)}'),
        if (vm['mmsi'] != null) ...[
          Text(l.vesselAis, style: Theme.of(context).textTheme.labelLarge),
          KeyValue('MMSI', '${vm['mmsi']}', mono: true),
          KeyValue('Name', vm['name'] as String?),
          if (vm['callsign'] != null) KeyValue('Call sign', '${vm['callsign']}', mono: true),
          if (vm['distance_m'] != null) KeyValue('Δ', '${vm['distance_m']} m'),
        ] else if (vm['dark'] == true)
          Pill(l.darkVessel, color: UavrColors.critical, icon: Icons.portable_wifi_off)
        else if (vm['coverage'] == false)
          Text(l.noAisCoverage),
        if (mda != null) ...[
          const SizedBox(height: 8),
          Text(l.mdaTrack, style: Theme.of(context).textTheme.labelLarge),
          KeyValue('Track', '${mda['track_id']}', mono: true),
          KeyValue('Role', '${mda['role'] ?? '—'} (${mda['role_confidence'] ?? '—'})'),
          if (mda['distance_m'] != null) KeyValue('Δ', '${mda['distance_m']} m'),
        ],
      ]),
    );
  }
}
