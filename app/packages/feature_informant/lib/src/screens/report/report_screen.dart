import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../../services/capture.dart';
import '../../services/report_sender.dart';
import '../../widgets/common.dart';
import '../sent.dart';
import 'aim_step.dart';
import 'details_step.dart';
import 'evidence_step.dart';
import 'report_controller.dart';
import 'status_strip.dart';

/// The report flow: aim → details → evidence, with "Send report now" available throughout
/// once there is a location fix.
class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(reportFlowProvider.select((d) => d.step));
    ref.watch(evidenceCaptureProvider); // one capture session (and slot numbering) per report
    final flow = ref.read(reportFlowProvider.notifier);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard(context) && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l.reportTitle),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: SegmentedButton<ReportStep>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: ReportStep.aim, label: Text(context.l.stepAim), icon: const Icon(Icons.explore)),
                  ButtonSegment(
                      value: ReportStep.details, label: Text(context.l.stepDetails), icon: const Icon(Icons.tune)),
                  ButtonSegment(
                      value: ReportStep.evidence,
                      label: Text(context.l.stepEvidence),
                      icon: const Icon(Icons.perm_media_outlined)),
                ],
                selected: {step},
                onSelectionChanged: (s) => flow.goTo(s.first),
              ),
            ),
          ),
        ),
        body: Column(children: [
          const StatusStrip(),
          Expanded(
            child: switch (step) {
              ReportStep.aim => const AimStep(),
              ReportStep.details => const DetailsStep(),
              ReportStep.evidence => const EvidenceStep(),
            },
          ),
        ]),
        bottomNavigationBar: const _SendBar(),
      ),
    );
  }
}

Future<bool> _confirmDiscard(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l.discardTitle),
        content: Text(ctx.l.discardBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.u.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.l.discard)),
        ],
      ),
    ) ??
    false;

class _SendBar extends ConsumerWidget {
  const _SendBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(reportFlowProvider);
    final flow = ref.read(reportFlowProvider.notifier);
    final next = switch (draft.step) {
      ReportStep.details => ReportStep.evidence,
      _ => null,
    };
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(children: [
          if (next != null) ...[
            OutlinedButton(onPressed: () => flow.goTo(next), child: Text(context.u.next)),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: SizedBox(
              height: 60,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: UavrColors.critical, foregroundColor: Colors.white),
                onPressed: draft.canSend ? () => _send(context, ref) : null,
                icon: draft.sending
                    ? const SizedBox.square(
                        dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send),
                label: Text(draft.sending ? context.l.sending : context.l.sendNow),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _send(BuildContext context, WidgetRef ref) async {
    final language = apiLanguage(Localizations.localeOf(context));
    final outcome = await ref.read(reportFlowProvider.notifier).send(language: language);
    if (!context.mounted) return;
    final l = context.l;
    switch (outcome) {
      case SendSucceeded(:final response):
        context.go('/sent', extra: SentArgs.fromResponse(response));
      case SendQueued():
        await _info(context, l.sendQueuedTitle, l.sendQueuedBody);
        if (context.mounted) context.go('/');
      case SendRateLimited():
        await _info(context, l.sendFailedTitle, l.sendRateLimited);
      case SendRejected(:final message):
        await _info(context, l.sendFailedTitle, l.sendRejected(message));
    }
  }

  Future<void> _info(BuildContext context, String title, String body) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.u.ok))],
        ),
      );
}
