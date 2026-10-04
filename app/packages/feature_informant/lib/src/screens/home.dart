import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_ui/uavr_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/my_reports.dart';
import '../services/outbox.dart';
import '../widgets/common.dart';

/// The CAA's official drone no-fly zone map (dronegis.caa.gov.tw).
const caaZoneMapUrl =
    'https://dronegis.caa.gov.tw/portal/apps/webappviewer/index.html?id=807bd21438ba4208b4a7e28569fe41aa';

void _openCaaZoneMap() => launchUrl(Uri.parse(caaZoneMapUrl), mode: LaunchMode.externalApplication);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final reports = ref.watch(myReportsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.u.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: l.homeZonesMap,
            onPressed: _openCaaZoneMap,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l.homeSettings,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myReportsProvider.future),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(padding: const EdgeInsets.all(16), children: [
              const DemoBanner(),
              const SizedBox(height: 12),
              const EmergencyBanner(),
              const SizedBox(height: 16),
              const _ReportButton(),
              const SizedBox(height: 6),
              Text(l.homeReportHint, textAlign: TextAlign.center),
              if (kIsWeb) ...[const SizedBox(height: 16), const _AndroidAppBanner()],
              const SizedBox(height: 16),
              Section(
                title: l.homeMyReports,
                child: switch (reports) {
                  AsyncData(:final value) => _ReportList(value),
                  AsyncError(:final error) => ErrorView(error, onRetry: () => ref.invalidate(myReportsProvider)),
                  _ => const Padding(padding: EdgeInsets.all(16), child: LoadingView()),
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _openCaaZoneMap,
                icon: const Icon(Icons.open_in_new),
                label: Text(l.homeZonesMap),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ReportButton extends StatelessWidget {
  const _ReportButton();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 84,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: UavrColors.critical,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          onPressed: () => context.push('/report'),
          icon: const Icon(Icons.campaign, size: 32),
          label: Text(context.l.homeReportButton),
        ),
      );
}

class _AndroidAppBanner extends ConsumerWidget {
  const _AndroidAppBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(configProvider).androidAppUrl;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconLine(Icons.android, context.l.homeWebBanner),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => launchUrl(Uri.parse(url)),
              icon: const Icon(Icons.open_in_new),
              label: Text(context.l.homeGetAndroidApp),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ReportList extends StatelessWidget {
  const _ReportList(this.data);
  final MyReports data;

  @override
  Widget build(BuildContext context) {
    if (data.reports.isEmpty && data.pending.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(context.l.homeNoReports, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }
    return Column(children: [
      for (final p in data.pending) _PendingTile(p),
      for (final r in data.reports) _ReportTile(r),
    ]);
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile(this.report);
  final PendingReport report;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.schedule_send_outlined),
        title: Text(context.l.homePendingSend),
        subtitle: Text(relativeTime(context.u, report.createdAt)),
        trailing: Pill(context.l.homePendingSend, color: UavrColors.medium),
      );
}

class _ReportTile extends StatelessWidget {
  const _ReportTile(this.report);
  final MyReport report;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final u = context.u;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: 64,
      leading: Badge(
        isLabelVisible: report.hasOpenRequest,
        child: const Icon(Icons.description_outlined),
      ),
      title: Text(report.stored.caseNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text(relativeTime(u, report.stored.sentAt)),
        if (report.hasOpenRequest) Pill(l.homeEvidenceRequested, color: UavrColors.medium, icon: Icons.add_a_photo),
        if (report.isStale) Text(l.homeStatusOffline, style: Theme.of(context).textTheme.bodySmall),
      ]),
      trailing: Pill(informantStatusLabel(u, report.status), color: statusColor(report.status)),
      onTap: () => context.push('/case/${Uri.encodeComponent(report.stored.caseNumber)}'),
    );
  }
}
