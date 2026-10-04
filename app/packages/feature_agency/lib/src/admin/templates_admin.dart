import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/l10n.dart';
import '../common/providers.dart';
import '../common/run_action.dart';

/// All six informant languages are mandatory (backend rejects partial templates).
const templateLanguages = ['zh-TW', 'en', 'vi', 'id', 'th', 'fil', 'de', 'fr'];

class TemplatesAdmin extends ConsumerWidget {
  const TemplatesAdmin({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final ts = ref.watch(templatesProvider);
    Future<void> edit(Template? t) async {
      final saved = await showDialog<bool>(context: context, builder: (_) => TemplateDialog(template: t));
      if (saved == true) ref.invalidate(templatesProvider);
    }

    return ts.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(errorText(e), onRetry: () => ref.invalidate(templatesProvider)),
      data: (list) => ListView(padding: const EdgeInsets.all(12), children: [
        Row(children: [
          Expanded(child: Text(l.templatesHint)),
          FilledButton.icon(onPressed: () => edit(null), icon: const Icon(Icons.add), label: Text(l.newTemplate)),
        ]),
        const SizedBox(height: 8),
        for (final kind in ['outcome', 'evidence_request']) ...[
          Text(kind == 'outcome' ? l.outcomeTemplates : l.evidenceTemplates, style: Theme.of(context).textTheme.titleSmall),
          for (final t in list.where((t) => t.kind == kind))
            ListTile(
              leading: Icon(kind == 'outcome' ? Icons.task_alt : Icons.add_a_photo_outlined),
              title: Text('${t.code} · ${t.text(context.lang)}'),
              subtitle: Text([
                '${l.languages}: ${templateLanguages.where((x) => (t.texts[x] ?? '').isNotEmpty).length}/6',
                if (t.requestedKinds.isNotEmpty) t.requestedKinds.join(', '),
                if (t.countsAsFalseReport) l.countsAsFalseReport,
              ].join(' · ')),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => edit(t),
            ),
          const SizedBox(height: 12),
        ],
      ]),
    );
  }
}

class TemplateDialog extends ConsumerStatefulWidget {
  const TemplateDialog({super.key, this.template});
  final Template? template;

  @override
  ConsumerState<TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends ConsumerState<TemplateDialog> {
  late final t = widget.template;
  late final _code = TextEditingController(text: t?.code ?? '');
  late final _texts = {for (final lang in templateLanguages) lang: TextEditingController(text: t?.texts[lang] ?? '')};
  late String _kind = t?.kind ?? 'outcome';
  late final Set<String> _kinds = {...?t?.requestedKinds};
  late bool _false = t?.countsAsFalseReport ?? false;
  bool _tried = false, _saving = false;

  @override
  void dispose() {
    _code.dispose();
    for (final c in _texts.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid => _code.text.trim().isNotEmpty && _texts.values.every((c) => c.text.trim().isNotEmpty);

  Future<void> _save() async {
    setState(() => _tried = true);
    if (!_valid) return;
    setState(() => _saving = true);
    final tpl = Template(
      code: _code.text.trim(),
      kind: _kind,
      texts: {for (final e in _texts.entries) e.key: e.value.text.trim()},
      requestedKinds: _kind == 'evidence_request' ? _kinds.toList() : const [],
      countsAsFalseReport: _kind == 'outcome' && _false,
    );
    final ok = await runAction(context, () async {
      await ref.read(staffApiProvider).upsertTemplate(tpl);
      return true;
    }, success: context.l.saved);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok == true) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final names = {'zh-TW': '繁體中文', 'en': 'English', 'vi': 'Tiếng Việt', 'id': 'Bahasa Indonesia', 'th': 'ภาษาไทย', 'fil': 'Filipino', 'de': 'Deutsch', 'fr': 'Français'};
    return AlertDialog(
      title: Text(t == null ? l.newTemplate : '${l.editTemplate}: ${t!.code}'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(children: [
            TextField(
              controller: _code,
              enabled: t == null,
              decoration: InputDecoration(labelText: l.code, errorText: _tried && _code.text.trim().isEmpty ? l.required : null),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'outcome', label: Text(l.outcomeTemplates)),
                ButtonSegment(value: 'evidence_request', label: Text(l.evidenceTemplates)),
              ],
              selected: {_kind},
              onSelectionChanged: t == null ? (v) => setState(() => _kind = v.first) : null,
            ),
            if (_kind == 'evidence_request')
              Wrap(spacing: 8, children: [
                for (final k in ['photo', 'video', 'audio'])
                  FilterChip(
                    label: Text(k),
                    selected: _kinds.contains(k),
                    onSelected: (v) => setState(() => v ? _kinds.add(k) : _kinds.remove(k)),
                  ),
              ]),
            if (_kind == 'outcome')
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _false,
                onChanged: (v) => setState(() => _false = v ?? false),
                title: Text(l.countsAsFalseReport),
              ),
            const SizedBox(height: 8),
            for (final lang in templateLanguages)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  key: Key('tpl-$lang'),
                  controller: _texts[lang],
                  maxLines: 2,
                  onChanged: (_) => _tried ? setState(() {}) : null,
                  decoration: InputDecoration(
                    labelText: '${names[lang]} ($lang)',
                    errorText: _tried && _texts[lang]!.text.trim().isEmpty ? l.required : null,
                  ),
                ),
              ),
            Text(l.allLanguagesRequired, style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.u.cancel)),
        FilledButton(onPressed: _saving ? null : _save, child: Text(context.u.save)),
      ],
    );
  }
}
