import 'package:flutter/material.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/l10n.dart';
import '../common/labels.dart';

/// Shared dialog frame; the confirm button has key `dialog-confirm`.
class ActionDialog extends StatelessWidget {
  const ActionDialog({
    super.key,
    required this.title,
    required this.child,
    required this.onConfirm,
    this.confirmLabel,
    this.width = 480,
  });
  final String title;
  final Widget child;
  final VoidCallback? onConfirm;
  final String? confirmLabel;
  final double width;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(title),
        content: SizedBox(width: width, child: SingleChildScrollView(child: child)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.u.cancel)),
          FilledButton(
            key: const Key('dialog-confirm'),
            onPressed: onConfirm,
            child: Text(confirmLabel ?? context.u.ok),
          ),
        ],
      );
}

class _Info extends StatelessWidget {
  const _Info(this.text, {this.icon = Icons.info_outline, this.color});
  final String text;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ]),
    );
  }
}

/// Shows the zh-TW and English text of a template (what informants will receive).
class TemplateTexts extends StatelessWidget {
  const TemplateTexts(this.t, {super.key});
  final Template t;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 48, right: 8, bottom: 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('中文：${t.texts['zh-TW'] ?? '—'}', style: Theme.of(context).textTheme.bodySmall),
          Text('EN: ${t.texts['en'] ?? '—'}', style: Theme.of(context).textTheme.bodySmall),
        ]),
      );
}

// ---------------------------------------------------------------- transfer

class TransferDialog extends StatefulWidget {
  const TransferDialog({super.key, required this.desks, required this.current});
  final List<Desk> desks;
  final CaseSummary current;

  @override
  State<TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<TransferDialog> {
  int? _desk;
  final _reason = TextEditingController();
  bool _tried = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final lang = context.lang;
    final options = widget.desks
        .where((d) => d.id != widget.current.deskId && d.clearance >= widget.current.classification)
        .toList();
    return ActionDialog(
      title: l.actTransfer,
      confirmLabel: l.actTransfer,
      onConfirm: () {
        setState(() => _tried = true);
        if (_desk != null && _reason.text.trim().isNotEmpty) Navigator.pop(context, (deskId: _desk!, reason: _reason.text.trim()));
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        DropdownButtonFormField<int>(
          key: const Key('transfer-desk'),
          initialValue: _desk,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l.targetDesk,
            errorText: _tried && _desk == null ? l.required : null,
          ),
          items: [
            for (final d in options)
              DropdownMenuItem(value: d.id, child: Text('${d.label(lang)} (${d.agencyCode})', overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => setState(() => _desk = v),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('transfer-reason'),
          controller: _reason,
          maxLines: 2,
          maxLength: 500,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: l.reason,
            errorText: _tried && _reason.text.trim().isEmpty ? l.reasonRequired : null,
          ),
        ),
        _Info(l.transferHint(classificationLabel(l, widget.current.classification))),
      ]),
    );
  }
}

// ---------------------------------------------------------------- merge

class MergeDialog extends StatefulWidget {
  const MergeDialog({super.key, required this.current, required this.candidates});
  final CaseSummary current;
  final List<CaseSummary> candidates;

  @override
  State<MergeDialog> createState() => _MergeDialogState();
}

class _MergeDialogState extends State<MergeDialog> {
  String? _other;
  final _reason = TextEditingController(text: '');
  bool _tried = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  double? _dist(CaseSummary c) =>
      c.position == null || widget.current.position == null ? null : widget.current.position!.distanceTo(c.position!);

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final list = [...widget.candidates]..sort((a, b) => (_dist(a) ?? 1e12).compareTo(_dist(b) ?? 1e12));
    return ActionDialog(
      title: l.actMerge,
      confirmLabel: l.actMerge,
      width: 560,
      onConfirm: () {
        setState(() => _tried = true);
        if (_other != null && _reason.text.trim().isNotEmpty) Navigator.pop(context, (otherId: _other!, reason: _reason.text.trim()));
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.mergeHint(widget.current.caseNumber)),
        const SizedBox(height: 8),
        if (list.isEmpty) Text(l.mergeNoCandidates),
        RadioGroup<String>(
          groupValue: _other,
          onChanged: (v) => setState(() => _other = v),
          child: Column(children: [
            for (final c in list.take(20))
              RadioListTile<String>(
                value: c.id,
                dense: true,
                title: Row(children: [
                  SeverityChip(c.severity, compact: true),
                  const SizedBox(width: 8),
                  Text(c.caseNumber),
                  const SizedBox(width: 8),
                  if ((_dist(c) ?? 1e12) < 3000) Pill(l.nearby, color: UavrColors.medium),
                ]),
                subtitle: Text([
                  stateLabel(l, c.state),
                  if (_dist(c) != null) distanceLabel(_dist(c)!),
                  if (c.firstSeen != null) dateTime(c.firstSeen!),
                ].join(' · ')),
              ),
          ]),
        ),
        if (_tried && _other == null) Text(l.mergeChoose, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        TextField(
          key: const Key('merge-reason'),
          controller: _reason,
          maxLength: 500,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: l.reason,
            hintText: l.mergeReasonHint,
            errorText: _tried && _reason.text.trim().isEmpty ? l.reasonRequired : null,
          ),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------- severity

class SeverityDialog extends StatefulWidget {
  const SeverityDialog({super.key, required this.current});
  final int current;

  @override
  State<SeverityDialog> createState() => _SeverityDialogState();
}

class _SeverityDialogState extends State<SeverityDialog> {
  late int _level = widget.current;
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _downgrade => _level < widget.current;

  void _confirm() {
    final l = context.l;
    if (_level == widget.current) {
      setState(() => _error = l.severityUnchanged);
      return;
    }
    if (_downgrade && _reason.text.trim().isEmpty) {
      setState(() => _error = l.downgradeReasonRequired);
      return;
    }
    Navigator.pop(context, (level: _level, reason: _reason.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final u = context.u;
    return ActionDialog(
      title: l.actSeverity,
      onConfirm: _confirm,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text('${l.currentSeverity}: '), SeverityChip(widget.current)]),
        const SizedBox(height: 12),
        SegmentedButton<int>(
          segments: [
            for (final s in [1, 2, 3]) ButtonSegment(value: s, label: Text(severityLabel(u, s), key: Key('sev-$s'))),
          ],
          selected: {_level},
          onSelectionChanged: (v) => setState(() {
            _level = v.first;
            _error = null;
          }),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('severity-reason'),
          controller: _reason,
          maxLines: 2,
          maxLength: 500,
          onChanged: (_) => setState(() => _error = null),
          decoration: InputDecoration(
            labelText: _downgrade ? l.reasonMandatory : l.reasonOptional,
            errorText: _error,
          ),
        ),
        _Info(_downgrade ? l.downgradeExplain : l.upgradeExplain,
            icon: _downgrade ? Icons.gpp_maybe_outlined : Icons.info_outline,
            color: _downgrade ? UavrColors.medium : null),
      ]),
    );
  }
}

// ---------------------------------------------------------------- evidence request

class EvidenceRequestDialog extends StatefulWidget {
  const EvidenceRequestDialog({super.key, required this.templates});
  final List<Template> templates;

  @override
  State<EvidenceRequestDialog> createState() => _EvidenceRequestDialogState();
}

class _EvidenceRequestDialogState extends State<EvidenceRequestDialog> {
  String? _code;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final list = widget.templates.where((t) => t.kind == 'evidence_request').toList();
    return ActionDialog(
      title: l.actRequestEvidence,
      confirmLabel: l.send,
      width: 560,
      onConfirm: _code == null ? null : () => Navigator.pop(context, _code),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (list.isEmpty) Text(l.noTemplates),
        RadioGroup<String>(
          groupValue: _code,
          onChanged: (v) => setState(() => _code = v),
          child: Column(children: [
            for (final t in list) ...[
              RadioListTile<String>(
                value: t.code,
                dense: true,
                title: Text(t.text(context.lang)),
                subtitle: Text([t.code, if (t.requestedKinds.isNotEmpty) t.requestedKinds.join(', ')].join(' · ')),
              ),
              TemplateTexts(t),
            ],
          ]),
        ),
        _Info(l.evidenceRequestHint),
      ]),
    );
  }
}

// ---------------------------------------------------------------- field officers

class FieldAssignDialog extends StatefulWidget {
  const FieldAssignDialog({super.key, required this.roster, required this.assigned});
  final List<RosterEntry> roster;
  final Set<String> assigned;

  @override
  State<FieldAssignDialog> createState() => _FieldAssignDialogState();
}

class _FieldAssignDialogState extends State<FieldAssignDialog> {
  late final Set<String> _sel = {...widget.assigned};

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final officers = widget.roster.where((r) => r.isFieldOfficer).toList()
      ..sort((a, b) => (b.onDuty ? 1 : 0).compareTo(a.onDuty ? 1 : 0));
    return ActionDialog(
      title: l.actAssignField,
      onConfirm: () => Navigator.pop(context, _sel.toList()),
      child: Column(children: [
        if (officers.isEmpty) Text(l.noFieldOfficers),
        for (final o in officers)
          CheckboxListTile(
            dense: true,
            value: _sel.contains(o.id),
            onChanged: (v) => setState(() => v == true ? _sel.add(o.id) : _sel.remove(o.id)),
            title: Text(o.displayName.isEmpty ? o.username : o.displayName),
            subtitle: Text([
              o.username,
              o.onDuty ? l.onDuty : l.offDuty,
              if (o.lastPositionAt != null) '${l.lastPosition} ${relativeTime(context.u, o.lastPositionAt!)}',
            ].join(' · ')),
          ),
      ]),
    );
  }
}

// ---------------------------------------------------------------- resolve

class ResolveDialog extends StatefulWidget {
  const ResolveDialog({super.key, required this.templates, required this.defenseCase});
  final List<Template> templates;
  final bool defenseCase;

  @override
  State<ResolveDialog> createState() => _ResolveDialogState();
}

class _ResolveDialogState extends State<ResolveDialog> {
  String? _code;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final list = widget.templates.where((t) => t.isOutcome).toList();
    return ActionDialog(
      title: l.actResolve,
      confirmLabel: l.actResolve,
      width: 560,
      onConfirm: _code == null
          ? null
          : () => Navigator.pop(context, (code: _code!, note: _note.text.trim().isEmpty ? null : _note.text.trim())),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.outcome, style: Theme.of(context).textTheme.titleSmall),
        RadioGroup<String>(
          groupValue: _code,
          onChanged: (v) => setState(() => _code = v),
          child: Column(children: [
            for (final t in list) ...[
              RadioListTile<String>(
                key: Key('outcome-${t.code}'),
                value: t.code,
                dense: true,
                title: Text(t.text(context.lang)),
                subtitle: Text([t.code, if (t.countsAsFalseReport) l.countsAsFalseReport].join(' · ')),
              ),
              TemplateTexts(t),
            ],
          ]),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('resolve-note'),
          controller: _note,
          maxLines: 3,
          maxLength: 4000,
          decoration: InputDecoration(labelText: l.internalNote, helperText: l.internalNoteHint),
        ),
        _Info(l.resolveInformantHint),
        if (widget.defenseCase) _Info(l.defenseOutcomeHint, icon: Icons.shield_outlined, color: UavrColors.zoneMilitary),
      ]),
    );
  }
}

// ---------------------------------------------------------------- note

class NoteDialog extends StatefulWidget {
  const NoteDialog({super.key, required this.allowDefense});
  final bool allowDefense;

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  final _text = TextEditingController();
  bool _defense = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return ActionDialog(
      title: l.actNote,
      onConfirm: _text.text.trim().isEmpty ? null : () => Navigator.pop(context, (text: _text.text.trim(), defense: _defense)),
      child: Column(children: [
        TextField(
          key: const Key('note-text'),
          controller: _text,
          maxLines: 4,
          maxLength: 4000,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l.noteText, helperText: l.noteInternalHint),
        ),
        if (widget.allowDefense)
          CheckboxListTile(
            value: _defense,
            onChanged: (v) => setState(() => _defense = v ?? false),
            title: Text(l.defenseNote),
            subtitle: Text(l.defenseNoteHint),
            secondary: const Icon(Icons.enhanced_encryption_outlined),
          ),
      ]),
    );
  }
}

Future<bool> confirmDialog(BuildContext context, String title, String body) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => ActionDialog(title: title, onConfirm: () => Navigator.pop(c, true), child: Text(body)),
    ) ==
    true;
