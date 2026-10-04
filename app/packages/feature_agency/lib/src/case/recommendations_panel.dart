import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart' hide TimeOfDay;
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/l10n.dart';
import '../common/run_action.dart';
import 'case_providers.dart';

final recommendationsProvider = FutureProvider.autoDispose.family<({List<Recommendation> items, bool canAct}), String>(
  (ref, caseId) => ref.watch(staffApiProvider).caseRecommendations(caseId),
  retry: (_, _) => null,
);

/// Suggested responses with accept / reject / modify. Decision support only.
class RecommendationsPanel extends ConsumerWidget {
  const RecommendationsPanel({super.key, required this.caseId});
  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final data = ref.watch(recommendationsProvider(caseId));
    return Section(
      key: const Key('recommendations'),
      title: l.recTitle,
      trailing: const Icon(Icons.rule, size: 18),
      child: switch (data) {
        AsyncData(:final value) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.recIntro, style: Theme.of(context).textTheme.bodySmall),
            if (!value.canAct)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(l.recReadOnly, style: Theme.of(context).textTheme.bodySmall),
              ),
            const SizedBox(height: 6),
            if (value.items.isEmpty) Text(l.recNone),
            for (final r in value.items) _RecTile(caseId: caseId, r: r, canAct: value.canAct),
          ],
        ),
        AsyncError(:final error) => ErrorView(error, onRetry: () => ref.invalidate(recommendationsProvider(caseId))),
        _ => const Padding(padding: EdgeInsets.all(12), child: LoadingView()),
      },
    );
  }
}

class _RecTile extends ConsumerWidget {
  const _RecTile({required this.caseId, required this.r, required this.canAct});
  final String caseId;
  final Recommendation r;
  final bool canAct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final t = Theme.of(context);
    final loc = MaterialLocalizations.of(context);

    Future<void> decide(String decision, {String? text, String? note}) async {
      await runAction(
        context,
        () => ref.read(staffApiProvider).decideRecommendation(caseId, r.id, decision, text: text, note: note),
      );
      ref.invalidate(recommendationsProvider(caseId));
      ref.invalidate(caseDetailProvider(caseId));
    }

    final (statusText, statusColor) = switch (r.status) {
      'accepted' => (l.recAccepted, const Color(0xFF2E7D32)),
      'rejected' => (l.recRejected, t.colorScheme.outline),
      'modified' => (l.recModified, const Color(0xFF1565C0)),
      _ => (null, null),
    };
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    r.shownText,
                    style: t.textTheme.titleSmall?.copyWith(
                      decoration: r.status == 'rejected' ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (statusText != null) Pill(statusText, color: statusColor),
              ],
            ),
            const SizedBox(height: 2),
            Text(r.reason, style: t.textTheme.bodySmall),
            if (r.finalText != null)
              Text(r.text, style: t.textTheme.bodySmall?.copyWith(decoration: TextDecoration.lineThrough)),
            if (r.decidedBy != null)
              Text(
                l.recBy(
                      r.decidedBy!,
                      r.decidedAt == null
                          ? ''
                          : loc.formatTimeOfDay(
                              TimeOfDay.fromDateTime(r.decidedAt!.toLocal()),
                              alwaysUse24HourFormat: true,
                            ),
                    ) +
                    (r.note == null ? '' : ' · ${r.note}'),
                style: t.textTheme.bodySmall,
              ),
            if (canAct && r.isOpen)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => decide('accept'),
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(l.recAccept),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final m = await _modifyDialog(context, l, r.text);
                        if (m != null) await decide('modify', text: m.text, note: m.note);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(l.recModify),
                    ),
                    TextButton.icon(
                      onPressed: () => decide('reject'),
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(l.recReject),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<({String text, String? note})?> _modifyDialog(BuildContext context, AgencyL10n l, String initial) {
  final text = TextEditingController(text: initial);
  final note = TextEditingController();
  return showDialog<({String text, String? note})>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.recModifyTitle),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: text,
              maxLines: 3,
              decoration: InputDecoration(labelText: l.recNewText),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              maxLines: 2,
              decoration: InputDecoration(labelText: l.recNote),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel)),
        FilledButton(
          onPressed: () {
            if (text.text.trim().isEmpty) return;
            Navigator.pop(ctx, (text: text.text.trim(), note: note.text.trim().isEmpty ? null : note.text.trim()));
          },
          child: Text(l.recModify),
        ),
      ],
    ),
  );
}
