import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../services/assignments.dart';
import '../services/outbox.dart';
import '../services/sensors.dart';
import '../services/session.dart';
import '../widgets/common.dart';
import 'logout.dart';

class AssignmentsScreen extends ConsumerWidget {
  const AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.f;
    final s = ref.watch(assignmentsProvider);
    final fix = ref.watch(myFixProvider);
    final outbox = ref.watch(outboxProvider);
    final pending = outbox.where((e) => !e.rejected).length;
    final cases = s.cases;

    Widget body;
    if (cases == null) {
      body = s.loading
          ? const LoadingView()
          : ErrorView(s.error ?? l.noAssignments, onRetry: () => ref.read(assignmentsProvider.notifier).load());
    } else {
      body = RefreshIndicator(
        onRefresh: () => ref.read(assignmentsProvider.notifier).load(),
        child: cases.isEmpty
            ? ListView(children: [
                SizedBox(height: 360, child: EmptyView(l.noAssignments, icon: Icons.assignment_turned_in_outlined)),
              ])
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: cases.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => AssignmentTile(cases[i], me: fix?.position),
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.assignmentsTitle),
        actions: [
          IconButton(
            tooltip: l.outboxTitle,
            onPressed: () => context.push('/outbox'),
            icon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.outbox_outlined),
            ),
          ),
        ],
      ),
      drawer: const FieldDrawer(),
      body: Column(children: [
        if (s.offline && cases != null) OfflineBanner(updatedAt: s.updatedAt),
        if (s.loading && cases != null) const LinearProgressIndicator(minHeight: 2),
        Expanded(child: body),
      ]),
    );
  }
}

class AssignmentTile extends StatelessWidget {
  const AssignmentTile(this.c, {super.key, this.me});
  final CaseSummary c;
  final LatLon? me;

  @override
  Widget build(BuildContext context) {
    final l = context.f;
    final u = UavrL10n.of(context);
    final t = Theme.of(context).textTheme;
    final last = c.lastSeen ?? c.createdAt;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/case/${c.id}', extra: c),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              SeverityChip(c.severity),
              const SizedBox(width: 8),
              Expanded(
                child: Text(c.caseNumber,
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontFamily: 'monospace')),
              ),
              if (c.redacted)
                Tooltip(
                  message: l.redactedShort,
                  child: const Icon(Icons.lock, size: 20, color: UavrColors.redacted, semanticLabel: 'redacted'),
                ),
              const SizedBox(width: 6),
              Pill(caseStateLabel(l, c.state)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.near_me_outlined, size: 18),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  c.position == null ? l.positionUnknown : (me == null ? l.waitingForGps : rangeText(l, me!, c.position!)),
                  style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.schedule, size: 16),
              const SizedBox(width: 4),
              Text(last == null ? '—' : l.lastSeen(relativeTime(u, last))),
            ]),
          ]),
        ),
      ),
    );
  }
}

class FieldDrawer extends ConsumerWidget {
  const FieldDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.f;
    final session = ref.watch(fieldSessionProvider).value;
    final me = session?.me;
    final lang = Localizations.localeOf(context).languageCode;
    return Drawer(
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.badge_outlined)),
            title: Text(me?.displayName.isNotEmpty == true ? me!.displayName : (me?.username ?? '')),
            subtitle: Text([
              if (me?.agency != null) me!.agency!.label(lang),
              if (me?.desk != null) me!.desk!.label(lang),
              if (me?.fieldUnit == true) l.defenseFieldUnit,
            ].join(' · ')),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.assignment_outlined),
            title: Text(l.assignmentsTitle),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.outbox_outlined),
            title: Text(l.outboxTitle),
            onTap: () {
              Navigator.pop(context);
              context.push('/outbox');
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.phonelink_lock, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(l.mdmNote, style: Theme.of(context).textTheme.bodySmall)),
            ]),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l.signOut),
            onTap: () => confirmLogout(context, ref),
          ),
        ]),
      ),
    );
  }
}
