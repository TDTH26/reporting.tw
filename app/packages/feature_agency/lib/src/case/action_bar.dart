import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';

import '../common/access.dart';
import '../common/l10n.dart';
import '../common/providers.dart';
import '../common/run_action.dart';
import '../live/queue_controller.dart';
import 'case_providers.dart';
import 'dialogs.dart';

/// Dispatcher actions. Every button is disabled unless the viewer can act on the case
/// (backend abac.can_act) and the case state allows the transition.
class CaseActionBar extends ConsumerWidget {
  const CaseActionBar({super.key, required this.detail});
  final CaseDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final c = detail.summary;
    final me = ref.watch(meProvider).value!;
    final act = detail.canAct && !detail.redacted;
    final open = c.state.isOpen;
    final api = ref.read(staffApiProvider);

    Future<void> done(Future<CaseSummary?> Function() f, {String? success}) async {
      final s = await runAction(context, f, success: success);
      if (s != null) {
        if (canReadCases(me)) ref.read(queueProvider.notifier).upsert(s);
        ref.invalidate(caseDetailProvider(c.id));
      }
    }

    Future<void> transfer() async {
      final desks = await ref.read(desksProvider.future);
      if (!context.mounted) return;
      final r = await showDialog<({int deskId, String reason})>(
          context: context, builder: (_) => TransferDialog(desks: desks, current: c));
      if (r != null && context.mounted) await done(() => api.transfer(c.id, r.deskId, r.reason), success: l.transferred);
    }

    Future<void> merge() async {
      final q = canReadCases(me) ? ref.read(queueProvider).cases : const <CaseSummary>[];
      final candidates = q.where((x) => x.id != c.id && x.state.isOpen && !x.redacted).toList();
      final r = await showDialog<({String otherId, String reason})>(
          context: context, builder: (_) => MergeDialog(current: c, candidates: candidates));
      if (r != null && context.mounted) await done(() => api.merge(c.id, r.otherId, r.reason), success: l.merged);
    }

    Future<void> severity() async {
      final r = await showDialog<({int level, String reason})>(
          context: context, builder: (_) => SeverityDialog(current: c.severity));
      if (r != null && context.mounted) await done(() => api.setSeverity(c.id, r.level, r.reason));
    }

    Future<void> evidence() async {
      final ts = await ref.read(templatesProvider.future);
      if (!context.mounted) return;
      final code = await showDialog<String>(context: context, builder: (_) => EvidenceRequestDialog(templates: ts));
      if (code == null || !context.mounted) return;
      final n = await runAction(context, () => api.requestEvidence(c.id, code));
      if (n != null) {
        ref.invalidate(caseDetailProvider(c.id));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.evidenceRequested(n))));
        }
      }
    }

    Future<void> field() async {
      final roster = await runAction(context, () => ref.read(rosterProvider.future));
      if (roster == null || !context.mounted) return;
      final r = await showDialog<List<String>>(
        context: context,
        builder: (_) => FieldAssignDialog(roster: roster, assigned: {for (final o in detail.fieldOfficers) o.id}),
      );
      if (r != null && context.mounted) await done(() => api.assignField(c.id, r), success: l.fieldAssigned);
    }

    Future<void> resolve() async {
      final ts = await ref.read(templatesProvider.future);
      if (!context.mounted) return;
      final r = await showDialog<({String code, String? note})>(
        context: context,
        builder: (_) => ResolveDialog(templates: ts, defenseCase: c.classification >= 2),
      );
      if (r != null && context.mounted) await done(() => api.resolve(c.id, r.code, note: r.note), success: l.resolved);
    }

    Future<void> closeCase() async {
      if (await confirmDialog(context, l.actClose, l.closeConfirm(c.caseNumber)) && context.mounted) {
        await done(() => api.closeCase(c.id));
      }
    }

    Future<void> note() async {
      final r = await showDialog<({String text, bool defense})>(
          context: context, builder: (_) => NoteDialog(allowDefense: me.clearance >= 2));
      if (r != null && context.mounted) await done(() => api.addNote(c.id, r.text, defense: r.defense), success: l.noteAdded);
    }

    Widget btn(String key, IconData icon, String label, bool enabled, VoidCallback f, {bool primary = false}) {
      final onPressed = enabled ? f : null;
      return primary
          ? FilledButton.icon(key: Key('action-$key'), onPressed: onPressed, icon: Icon(icon, size: 18), label: Text(label))
          : OutlinedButton.icon(key: Key('action-$key'), onPressed: onPressed, icon: Icon(icon, size: 18), label: Text(label));
    }

    final investigating = c.state == CaseState.acknowledged || c.state == CaseState.investigating;
    return Wrap(spacing: 8, runSpacing: 8, children: [
      btn('acknowledge', Icons.check_circle_outline, l.actAcknowledge, act && c.state == CaseState.newCase,
          () => done(() => api.acknowledge(c.id), success: l.acknowledged(c.caseNumber)),
          primary: true),
      btn('investigate', Icons.manage_search, l.actInvestigate, act && c.state == CaseState.acknowledged,
          () => done(() => api.investigate(c.id))),
      btn('transfer', Icons.swap_horiz, l.actTransfer, act && open, transfer),
      btn('merge', Icons.merge, l.actMerge, act && open, merge),
      btn('severity', Icons.unfold_more, l.actSeverity, act && open, severity),
      btn('evidence', Icons.add_a_photo_outlined, l.actRequestEvidence, act && open, evidence),
      btn('field', Icons.local_police_outlined, l.actAssignField, act && open, field),
      btn('resolve', Icons.task_alt, l.actResolve, act && investigating, resolve),
      btn('close', Icons.lock_outline, l.actClose,
          act && c.state == CaseState.resolved && (me.has('dispatcher') || me.has('supervisor')), closeCase),
      // Notes need full access (not desk ownership) on the backend.
      btn('note', Icons.sticky_note_2_outlined, l.actNote, !detail.redacted && canDispatch(me) && me.clearance >= c.classification,
          note),
    ]);
  }
}
