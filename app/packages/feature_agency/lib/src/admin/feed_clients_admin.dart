import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/l10n.dart';
import '../common/labels.dart';
import '../common/run_action.dart';
import '../case/dialogs.dart';

const feedSources = ['sensor-track', 'remote-id', 'adsb', 'ais', 'weather', 'registry', 'permit', 'cctv', 'video-feed', 'atreides'];

final feedClientsProvider =
    FutureProvider.autoDispose<List<StatRow>>((ref) => ref.watch(staffApiProvider).feedClients(), retry: (_, _) => null);

class FeedClientsAdmin extends ConsumerWidget {
  const FeedClientsAdmin({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final fc = ref.watch(feedClientsProvider);

    Future<void> create() async {
      final r = await showDialog<({String name, List<String> sources, int classification})>(
          context: context, builder: (_) => const FeedClientDialog());
      if (r == null || !context.mounted) return;
      final res = await runAction(
          context, () => ref.read(staffApiProvider).createFeedClient(r.name, r.sources, classification: r.classification));
      ref.invalidate(feedClientsProvider);
      if (res != null && context.mounted) {
        await showDialog<void>(context: context, barrierDismissible: false, builder: (_) => FeedKeyDialog(keyText: res.key));
      }
    }

    Future<void> revoke(StatRow r) async {
      if (!await confirmDialog(context, l.revoke, l.revokeConfirm(r.s('name')))) return;
      if (!context.mounted) return;
      await runAction(context, () => ref.read(staffApiProvider).revokeFeedClient(r.i('id')), success: l.revoked);
      ref.invalidate(feedClientsProvider);
    }

    return fc.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(errorText(e), onRetry: () => ref.invalidate(feedClientsProvider)),
      data: (rows) => ListView(padding: const EdgeInsets.all(12), children: [
        Row(children: [
          Expanded(child: Text(l.feedClientsHint)),
          FilledButton.icon(onPressed: create, icon: const Icon(Icons.add), label: Text(l.newFeedClient)),
        ]),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              const DataColumn(label: Text('ID')),
              DataColumn(label: Text(l.name)),
              DataColumn(label: Text(l.sources)),
              DataColumn(label: Text(l.classification)),
              DataColumn(label: Text(l.status)),
              DataColumn(label: Text(l.lastUsed)),
              const DataColumn(label: Text('')),
            ],
            rows: [
              for (final r in rows)
                DataRow(cells: [
                  DataCell(Text('${r.i('id')}')),
                  DataCell(Text(r.s('name'))),
                  DataCell(Text(r.raw['sources'] is List ? (r.raw['sources'] as List).join(', ') : '')),
                  DataCell(Text(classificationLabel(l, r.i('classification')))),
                  DataCell(r.raw['active'] == true
                      ? Pill(l.active, color: UavrColors.low)
                      : Pill(l.revoked, color: UavrColors.redacted)),
                  DataCell(Text(DateTime.tryParse(r.s('last_used')) == null ? '—' : dateTime(DateTime.parse(r.s('last_used'))))),
                  DataCell(r.raw['active'] == true
                      ? TextButton(onPressed: () => revoke(r), child: Text(l.revoke))
                      : const SizedBox.shrink()),
                ]),
            ],
          ),
        ),
      ]),
    );
  }
}

class FeedClientDialog extends ConsumerStatefulWidget {
  const FeedClientDialog({super.key});
  @override
  ConsumerState<FeedClientDialog> createState() => _FeedClientDialogState();
}

class _FeedClientDialogState extends ConsumerState<FeedClientDialog> {
  final _name = TextEditingController();
  final Set<String> _sources = {};
  int _class = 0;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final me = ref.watch(meProvider).value!;
    final valid = _name.text.trim().isNotEmpty && _sources.isNotEmpty;
    return ActionDialog(
      title: l.newFeedClient,
      onConfirm: valid
          ? () => Navigator.pop(context, (name: _name.text.trim(), sources: _sources.toList(), classification: _class))
          : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(controller: _name, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: l.name)),
        const SizedBox(height: 12),
        Text(l.sources, style: Theme.of(context).textTheme.labelLarge),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final s in feedSources)
            FilterChip(
              label: Text(s),
              selected: _sources.contains(s),
              onSelected: (v) => setState(() => v ? _sources.add(s) : _sources.remove(s)),
            ),
        ]),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _class,
          decoration: InputDecoration(labelText: l.classification),
          items: [
            for (var c = 0; c <= 2; c++)
              DropdownMenuItem(value: c, enabled: c <= me.clearance, child: Text('$c · ${classificationLabel(l, c)}')),
          ],
          onChanged: (v) => setState(() => _class = v ?? 0),
        ),
      ]),
    );
  }
}

/// The feed key is returned exactly once by the backend.
class FeedKeyDialog extends StatelessWidget {
  const FeedKeyDialog({super.key, required this.keyText});
  final String keyText;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return AlertDialog(
      title: Text(l.feedKeyTitle),
      content: SizedBox(
        width: 520,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.feedKeyOnce),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Expanded(child: SelectableText(keyText, style: const TextStyle(fontFamily: 'monospace'))),
              IconButton(
                tooltip: l.copy,
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: keyText));
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.copied)));
                },
              ),
            ]),
          ),
        ]),
      ),
      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.keyStored))],
    );
  }
}
