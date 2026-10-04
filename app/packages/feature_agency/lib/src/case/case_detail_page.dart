import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/l10n.dart';
import '../common/labels.dart';
import '../common/providers.dart';
import '../common/run_action.dart';
import 'action_bar.dart';
import 'case_providers.dart';
import 'cctv_panel.dart';
import 'maritime_ai_panels.dart';
import 'incident_panel.dart';
import 'map_panel.dart';
import 'observations_panel.dart';
import 'recommendations_panel.dart';
import 'timeline_panel.dart';

class CaseDetailPage extends ConsumerWidget {
  const CaseDetailPage({super.key, required this.caseId});
  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(caseDetailProvider(caseId));
    return d.when(
      skipLoadingOnRefresh: true,
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(errorText(e), onRetry: () => ref.invalidate(caseDetailProvider(caseId))),
      data: (detail) => CaseView(detail: detail, refreshing: d.isLoading),
    );
  }
}

class CaseView extends StatelessWidget {
  const CaseView({super.key, required this.detail, this.refreshing = false});
  final CaseDetail detail;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Column(children: [
      if (refreshing) const LinearProgressIndicator(minHeight: 2) else const SizedBox(height: 2),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CaseHeader(detail: detail),
          const SizedBox(height: 10),
          if (!detail.redacted) CaseActionBar(detail: detail),
        ]),
      ),
      const Divider(height: 1),
      Expanded(
        child: detail.redacted
            ? _RedactedBody(detail: detail)
            : LayoutBuilder(builder: (context, c) {
                final left = [
                  if (detail.summary.state != CaseState.resolved && detail.summary.state != CaseState.closed)
                    RecommendationsPanel(caseId: detail.summary.id),
                  IncidentPanel(detail: detail),
                  ObservationsPanel(observations: detail.observations),
                  TimelinePanel(events: detail.events),
                ];
                final right = [
                  CaseMapPanel(detail: detail),
                  if (detail.summary.isMaritime) MaritimePanel(summary: detail.summary),
                  AiPanel(summary: detail.summary),
                  if (detail.fieldOfficers.isNotEmpty) _FieldOfficers(detail: detail),
                  CctvPanel(summary: detail.summary),
                  if (detail.defenseNotes != null)
                    Section(
                      key: const Key('defense-notes'),
                      title: l.defenseNotes,
                      trailing: const Icon(Icons.enhanced_encryption_outlined, size: 18),
                      child: SelectableText(detail.defenseNotes!),
                    ),
                  if (detail.outcomeCode != null)
                    Section(
                      title: l.outcome,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        KeyValue(l.outcome, detail.outcomeCode),
                        KeyValue(l.internalNote, detail.outcomeNote),
                      ]),
                    ),
                ];
                Widget col(List<Widget> ws) => Column(children: [
                      for (final w in ws) ...[w, const SizedBox(height: 12)],
                    ]);
                if (c.maxWidth < 900) {
                  return ListView(padding: const EdgeInsets.all(16), children: [col([...right.take(1), ...left, ...right.skip(1)])]);
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: col(left)),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: col(right)),
                  ]),
                );
              }),
      ),
    ]);
  }
}

class CaseHeader extends ConsumerWidget {
  const CaseHeader({super.key, required this.detail});
  final CaseDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final c = detail.summary;
    final desk = ref.watch(desksByIdProvider)[c.deskId];
    final t = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        IconButton(
          tooltip: context.u.back,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/queue'),
        ),
        SelectableText(c.caseNumber, style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(width: 12),
        SeverityChip(c.severity),
        const SizedBox(width: 8),
        Pill(stateLabel(l, c.state), color: stateColor(c.state)),
        const SizedBox(width: 8),
        Pill(domainLabel(l, c.craftDomain), color: UavrColors.brand, icon: domainIcon(c.craftDomain)),
        const SizedBox(width: 8),
        Pill(classificationLabel(l, c.classification),
            color: classificationColor(c.classification), icon: c.classification > 0 ? Icons.lock_outline : null),
        const SizedBox(width: 12),
        if (c.state == CaseState.newCase && c.ackDeadline != null) ...[
          Text('${l.ackDue} '),
          Countdown(c.ackDeadline!, style: t.textTheme.titleMedium),
        ],
        const Spacer(),
        Flexible(
          child: Text(
            '${l.desk}: ${desk?.label(context.lang) ?? '#${c.deskId}'}',
            overflow: TextOverflow.ellipsis,
            style: t.textTheme.titleSmall,
          ),
        ),
      ]),
      if (detail.mergedIntoId != null)
        _Notice(
          icon: Icons.merge,
          text: l.mergedNotice,
          action: TextButton(onPressed: () => context.go('/cases/${detail.mergedIntoId}'), child: Text(l.openSurvivor)),
        ),
      if (detail.redacted)
        _Notice(key: const Key('redacted-notice'), icon: Icons.lock, text: l.redactedNotice, color: UavrColors.redacted)
      else if (!detail.canAct)
        _Notice(
          key: const Key('readonly-notice'),
          icon: Icons.visibility_outlined,
          text: l.readOnlyNotice(desk?.label(context.lang) ?? '#${c.deskId}'),
        ),
    ]);
  }
}

class _Notice extends StatelessWidget {
  const _Notice({super.key, required this.icon, required this.text, this.color, this.action});
  final IconData icon;
  final String text;
  final Color? color;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = color ?? UavrColors.brand;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(icon, color: c, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
        ?action,
      ]),
    );
  }
}

class _FieldOfficers extends StatelessWidget {
  const _FieldOfficers({required this.detail});
  final CaseDetail detail;

  @override
  Widget build(BuildContext context) => Section(
        title: context.l.assignedOfficers,
        child: Column(children: [
          for (final o in detail.fieldOfficers)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.local_police),
              title: Text(o.displayName),
              subtitle: Text(o.at == null ? context.l.noPosition : '${context.l.lastPosition} ${relativeTime(context.u, o.at!)}'),
            ),
        ]),
      );
}

/// Redacted: only location, time, severity, plus why.
class _RedactedBody extends StatelessWidget {
  const _RedactedBody({required this.detail});
  final CaseDetail detail;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final c = detail.summary;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Section(
        title: l.redactedTitle,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.redactedExplain),
          const SizedBox(height: 12),
          KeyValue(l.severity, severityLabel(context.u, c.severity)),
          KeyValue(l.firstSeen, c.firstSeen == null ? null : dateTime(c.firstSeen!)),
          KeyValue(l.lastSeen, c.lastSeen == null ? null : dateTime(c.lastSeen!)),
          KeyValue(l.location, c.position?.toString()),
        ]),
      ),
      const SizedBox(height: 12),
      if (c.position != null) CaseMapPanel(detail: detail, height: 320),
    ]);
  }
}
