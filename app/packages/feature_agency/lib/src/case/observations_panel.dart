import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_ui/uavr_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common/l10n.dart';
import '../common/labels.dart';
import '../common/run_action.dart';

class ObservationsPanel extends StatelessWidget {
  const ObservationsPanel({super.key, required this.observations});
  final List<ObservationView> observations;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Section(
      title: '${l.panelObservations} (${observations.length})',
      child: observations.isEmpty
          ? Text(l.none)
          : Column(children: [
              for (final o in observations.reversed) ...[ObservationTile(o), const Divider(height: 16)],
            ]),
    );
  }
}

class ObservationTile extends StatelessWidget {
  const ObservationTile(this.o, {super.key});
  final ObservationView o;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final t = Theme.of(context);
    final muted = t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant);
    final facts = [
      if (o.bearingDeg != null) '${l.bearing} ${o.bearingDeg!.round()}°${o.bearingAccuracyDeg != null ? ' ±${o.bearingAccuracyDeg!.round()}°' : ''}',
      if (o.elevationDeg != null) '${l.elevation} ${o.elevationDeg!.round()}°',
      if (o.altitudeM != null) '${l.altitude} ${o.altitudeM!.round()} m${o.altitudeSource != null ? ' (${o.altitudeSource})' : ''}',
      if (o.observerAccuracyM != null) '${l.gpsAccuracy} ±${o.observerAccuracyM!.round()} m',
      if (o.remoteIdSerial != null) '${l.remoteId} ${o.remoteIdSerial}',
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(sourceIcon(o.sourceType), size: 20),
        const SizedBox(width: 8),
        Text(sourceLabel(l, o.sourceType), style: const TextStyle(fontWeight: FontWeight.w600)),
        if (o.sourceId != null) ...[const SizedBox(width: 6), Text(o.sourceId!, style: muted)],
        const Spacer(),
        Text(dateTime(o.observedAt), style: muted),
      ]),
      const SizedBox(height: 4),
      Wrap(spacing: 6, runSpacing: 4, children: [
        Pill('${l.confidence} ${(o.confidence * 100).round()}%', color: UavrColors.brand),
        Pill('${l.spamScore} ${(o.spamScore * 100).round()}%', color: o.spamScore >= 0.5 ? UavrColors.critical : UavrColors.zoneOther),
        if (o.fidelity != null) Pill('${l.fidelity}: ${o.fidelity}', color: UavrColors.zoneInfra),
        if (o.attestation != null)
          Pill('${l.attestation}: ${o.attestation}',
              color: o.attestation == 'fail' || o.attestation == 'none' ? UavrColors.medium : UavrColors.low),
      ]),
      if (facts.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(facts.join(' · '))),
      if (o.craftDomain != 'aerial' || o.craftType != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${domainLabel(l, o.craftDomain)} · ${craftTypeLabel(l, o.craftType)}'),
        ),
      if ((o.interview?['answers'] as Map?)?.isNotEmpty ?? false)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '${l.interviewAnswers}: ${(o.interview!['answers'] as Map).entries.map((e) => '${e.key}=${e.value}').join(', ')}',
            style: muted,
          ),
        ),
      if (o.aiAssessment != null)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(children: [
            const Icon(Icons.auto_awesome_outlined, size: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'AI: ${craftTypeLabel(l, o.aiAssessment!['craft_type'] as String?)}'
                ' · ${o.aiAssessment!['silhouette'] ?? o.aiAssessment!['description'] ?? ''}',
                style: muted,
              ),
            ),
          ]),
        ),
      if (o.description != null && o.description!.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text('“${o.description}”${o.descriptionLang != null ? '  (${o.descriptionLang})' : ''}'),
        if (o.descriptionTranslated != null)
          Text('${l.machineTranslation}: ${o.descriptionTranslated}', style: muted?.copyWith(fontStyle: FontStyle.italic)),
      ],
      if (o.evidence.isNotEmpty) ...[
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final e in o.evidence) EvidenceTile(e)]),
      ],
    ]);
  }
}

/// One evidence item: hash badge, photo inline after fetching a presigned URL, video/audio in a new tab.
class EvidenceTile extends ConsumerStatefulWidget {
  const EvidenceTile(this.e, {super.key});
  final EvidenceInfo e;

  @override
  ConsumerState<EvidenceTile> createState() => _EvidenceTileState();
}

class _EvidenceTileState extends ConsumerState<EvidenceTile> {
  String? _url;
  bool _busy = false;

  Future<void> _view() async {
    setState(() => _busy = true);
    final r = await runAction(context, () => ref.read(staffApiProvider).evidenceUrl(widget.e.id));
    if (!mounted) return;
    setState(() => _busy = false);
    if (r == null) return;
    if (widget.e.kind == 'photo') {
      setState(() => _url = r.url);
    } else {
      await launchUrl(Uri.parse(r.url), webOnlyWindowName: '_blank');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final e = widget.e;
    final icon = switch (e.kind) {
      'video' => Icons.videocam_outlined,
      'audio' => Icons.mic_none,
      _ => Icons.photo_outlined,
    };
    final uploaded = e.uploadedAt != null;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Expanded(child: Text(e.mimeType ?? e.kind, overflow: TextOverflow.ellipsis)),
          Pill(evidenceStatusLabel(l, e.status), color: evidenceStatusColor(e.status)),
        ]),
        const SizedBox(height: 4),
        Text('${l.captured} ${clockTime(e.capturedAt)}${e.sizeBytes != null ? ' · ${(e.sizeBytes! / 1024).round()} KB' : ''}',
            style: Theme.of(context).textTheme.bodySmall),
        Tooltip(
          message: 'SHA-256 ${e.sha256}',
          child: Text('SHA-256 ${e.sha256.length > 12 ? e.sha256.substring(0, 12) : e.sha256}…',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
        ),
        if (_url != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(_url!, width: 204, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Text(l.imageFailed)),
            ),
          )
        else
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: !uploaded || _busy ? null : _view,
              icon: Icon(e.kind == 'photo' ? Icons.visibility_outlined : Icons.open_in_new, size: 16),
              label: Text(uploaded ? l.view : l.notUploaded),
            ),
          ),
      ]),
    );
  }
}
