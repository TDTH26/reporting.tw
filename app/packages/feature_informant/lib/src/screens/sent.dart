import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_capture/uavr_capture.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../services/sensors.dart';
import '../services/uploads.dart';
import '../widgets/common.dart';

class SentArgs {
  const SentArgs({
    required this.caseNumber,
    required this.status,
    required this.uploadCount,
    required this.suggestAndroidApp,
  });

  factory SentArgs.fromResponse(ReportResponse r) => SentArgs(
        caseNumber: r.caseNumber,
        status: r.status,
        uploadCount: r.uploads.length,
        suggestAndroidApp: r.suggestAndroidApp,
      );

  final String caseNumber;
  final String status;
  final int uploadCount;
  final bool suggestAndroidApp;
}

class SentScreen extends ConsumerWidget {
  const SentScreen(this.args, {super.key});
  final SentArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final web = ref.watch(informantSensorsProvider).platform == 'web';
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.sentTitle), automaticallyImplyLeading: false),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(padding: const EdgeInsets.all(20), children: [
            const Icon(Icons.check_circle, color: UavrColors.low, size: 72),
            const SizedBox(height: 12),
            Text(l.sentBody, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
            const SizedBox(height: 24),
            Text(l.caseNumberLabel, textAlign: TextAlign.center, style: theme.textTheme.labelLarge),
            SelectableText(
              args.caseNumber,
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
            Center(
              child: IconButton(
                icon: const Icon(Icons.copy),
                tooltip: MaterialLocalizations.of(context).copyButtonLabel,
                onPressed: () => Clipboard.setData(ClipboardData(text: args.caseNumber)),
              ),
            ),
            Center(child: Pill(informantStatusLabel(context.u, args.status), color: statusColor(args.status))),
            const SizedBox(height: 20),
            if (args.uploadCount > 0) _UploadProgress(args.caseNumber, args.uploadCount, web: web),
            const SizedBox(height: 12),
            IconLine(Icons.key, web ? l.sentKeyNoteWeb : l.sentKeyNote),
            if (args.suggestAndroidApp) IconLine(Icons.android, l.sentAndroidHint),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/case/${Uri.encodeComponent(args.caseNumber)}'),
              child: Text(l.sentViewStatus),
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => context.go('/'), child: Text(l.sentBackHome)),
          ]),
        ),
      ),
    );
  }
}

class _UploadProgress extends ConsumerWidget {
  const _UploadProgress(this.caseNumber, this.total, {required this.web});
  final String caseNumber;
  final int total;
  final bool web;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploads = ref.watch(evidenceUploadsProvider);
    return StreamBuilder<List<UploadJob>>(
      stream: uploads.changes,
      initialData: uploads.jobs,
      builder: (context, snap) {
        final mine = (snap.data ?? const <UploadJob>[]).where((j) => j.caseNumber == caseNumber).toList();
        // Finished jobs leave the queue, so anything not listed has been uploaded.
        final open = mine.where((j) => j.status != UploadStatus.done).toList();
        final done = (total - open.length).clamp(0, total);
        final partial = open.fold<double>(0, (s, j) => s + (j.sizeBytes == 0 ? 0 : j.sent / j.sizeBytes));
        final l = context.l;
        final finished = open.isEmpty;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(finished ? l.sentUploadsDone : l.sentUploading(done, total)),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: finished ? 1 : (done + partial) / total),
              if (!finished) ...[
                const SizedBox(height: 8),
                Text(web || kIsWeb ? l.sentUploadsKeepOpen : l.sentUploadsBackground,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ]),
          ),
        );
      },
    );
  }
}
