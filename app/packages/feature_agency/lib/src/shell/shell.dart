import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uavr_core/uavr_core.dart';

import '../common/access.dart';
import '../common/l10n.dart';
import '../live/queue_controller.dart';
import 'alert_banner.dart';
import 'shell_controls.dart';

class _Dest {
  const _Dest(this.path, this.icon, this.label, {this.gapAbove = false});
  final String path;
  final IconData icon;
  final String label;
  final bool gapAbove;
}

/// NavigationRail + top bar + live alert banner around every console page.
class ConsoleShell extends ConsumerWidget {
  const ConsoleShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider).value!;
    final l = context.l;
    // Keep the queue (and with it the live channel) alive on every page.
    if (canReadCases(me)) ref.watch(queueProvider.select((s) => s.alerts.length));
    final dests = [
      if (canReadCases(me)) _Dest('/queue', Icons.inbox_outlined, l.navQueue),
      if (canReadCases(me)) _Dest('/map', Icons.map_outlined, l.navLiveMap),
      if (canSeeMaritime(me)) _Dest('/maritime', Icons.sailing, l.navMaritime),
      if (canSeeAtreides(me)) _Dest('/atreides', Icons.radar, l.navAtreides),
      if (canSeeDashboards(me)) _Dest('/dashboards', Icons.insights_outlined, l.navDashboards),
      if (canSeeCctv(me)) _Dest('/cctv', Icons.videocam_outlined, l.navCctv),
      // A gap separates the administration pages from the operational ones.
      if (canSeeAdmin(me)) _Dest('/admin', Icons.admin_panel_settings_outlined, l.navAdmin, gapAbove: true),
      if (canSeeAudit(me)) _Dest('/audit', Icons.receipt_long_outlined, l.navAudit),
    ];
    final path = location.startsWith('/cases') ? '/queue' : location;
    final idx = dests.indexWhere((d) => path.startsWith(d.path));
    final t = Theme.of(context);
    return Scaffold(
      body: Row(children: [
        NavigationRail(
          selectedIndex: idx < 0 ? null : idx,
          labelType: NavigationRailLabelType.all,
          leading: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Image.asset('packages/feature_agency/assets/app_icon.png',
                width: 40, height: 40, semanticLabel: 'reporting.tw', filterQuality: FilterQuality.medium),
          ),
          onDestinationSelected: (i) => context.go(dests[i].path),
          destinations: [
            for (final d in dests)
              NavigationRailDestination(
                icon: Icon(d.icon),
                label: Text(d.label),
                padding: d.gapAbove ? const EdgeInsets.only(top: 28) : null,
              ),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Column(children: [
            Material(
              color: t.colorScheme.surfaceContainer,
              child: SizedBox(
                height: 52,
                child: Row(children: [
                  const SizedBox(width: 16),
                  // Same title for every account; below it who is signed in (name · desk · agency).
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.consoleTitle,
                            overflow: TextOverflow.ellipsis, maxLines: 1, style: t.textTheme.titleSmall),
                        Text(
                          [
                            me.displayName.isEmpty ? me.username : me.displayName,
                            me.desk?.label(context.lang) ?? l.noDesk,
                            if (me.agency != null) me.agency!.label(context.lang),
                          ].join(' · '),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (me.desk != null && canDispatch(me)) const DutySwitch(),
                  const SizedBox(width: 12),
                  if (canReadCases(me)) const LiveIndicator(),
                  const SizedBox(width: 8),
                  const LanguageButton(),
                  const ThemeButton(),
                  const UserMenu(),
                  const SizedBox(width: 8),
                ]),
              ),
            ),
            const Divider(height: 1),
            if (canReadCases(me)) const AlertBanner(),
            Expanded(child: child),
          ]),
        ),
      ]),
    );
  }
}
