import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../services/outbox.dart';
import '../widgets/common.dart';

class OutboxScreen extends ConsumerStatefulWidget {
  const OutboxScreen({super.key});
  @override
  ConsumerState<OutboxScreen> createState() => _OutboxScreenState();
}

class _OutboxScreenState extends ConsumerState<OutboxScreen> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    try {
      await ref.read(outboxProvider.notifier).retryAll();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  Future<void> _discard(OutboxEntry e) async {
    final l = context.f;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(l.discardConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(UavrL10n.of(c).cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.discard)),
        ],
      ),
    );
    if (ok == true) await ref.read(outboxProvider.notifier).discard(e.id);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.f;
    final u = UavrL10n.of(context);
    final entries = ref.watch(outboxProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.outboxTitle)),
      floatingActionButton: entries.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _retrying ? null : _retry,
              icon: const Icon(Icons.sync),
              label: Text(l.retryNow),
            ),
      body: entries.isEmpty
          ? EmptyView(l.outboxEmpty, icon: Icons.cloud_done_outlined)
          : ListView(padding: const EdgeInsets.all(12), children: [
              Text(l.outboxExplanation, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              for (final e in entries)
                Card(
                  child: ListTile(
                    leading: Icon(
                      e.rejected
                          ? Icons.error_outline
                          : (e.kind == OutboxKind.remoteId ? Icons.wifi_tethering : Icons.photo_camera),
                      color: e.rejected ? UavrColors.critical : null,
                    ),
                    title: Text('${e.caseNumber} · ${e.kind == OutboxKind.remoteId ? l.remoteIdScan : l.captureEvidence}'),
                    subtitle: Text([
                      relativeTime(u, e.createdAt),
                      l.attempts(e.attempts),
                      if (e.media.isNotEmpty) l.mediaCount(e.media.length),
                      if (e.rejected) l.rejected,
                      if (e.lastError != null) e.lastError == 'network' ? u.errorNetwork : e.lastError!,
                    ].join(' · ')),
                    trailing: IconButton(
                      tooltip: l.discard,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _discard(e),
                    ),
                  ),
                ),
            ]),
    );
  }
}
