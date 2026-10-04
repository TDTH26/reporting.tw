import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';

import 'cctv/cctv_page.dart';
import 'admin/admin_page.dart';
import 'atreides/atreides_page.dart';
import 'audit/audit_page.dart';
import 'case/case_detail_page.dart';
import 'common/access.dart';
import 'dashboards/dashboards_page.dart';
import 'livemap/live_map_page.dart';
import 'maritime/maritime_page.dart';
import 'queue/queue_page.dart';
import 'shell/auth_gate.dart';
import 'shell/shell.dart';

String defaultRoute(Me me) {
  if (canReadCases(me)) return '/queue';
  if (canSeeAdmin(me)) return '/admin';
  if (canSeeAudit(me)) return '/audit';
  return '/queue';
}

/// Allowed check per top-level path (null = not a guarded path).
bool? allowed(Me me, String path) {
  if (path.startsWith('/queue') || path.startsWith('/cases') || path.startsWith('/map')) return canReadCases(me);
  if (path.startsWith('/dashboards')) return canSeeDashboards(me);
  if (path.startsWith('/cctv')) return canSeeCctv(me);
  if (path.startsWith('/admin')) return canSeeAdmin(me);
  if (path.startsWith('/audit')) return canSeeAudit(me);
  return null;
}

GoRouter buildRouter(WidgetRef ref, {String initialLocation = '/'}) {
  final refresh = ValueNotifier(0);
  ref.listenManual(meProvider, (_, _) => refresh.value++);
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: refresh,
    redirect: (context, state) {
      final me = ref.read(meProvider).value;
      if (me == null) return null; // the gate shows sign-in / loading
      final path = state.uri.path;
      if (path == '/' || allowed(me, path) == false) return defaultRoute(me);
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const AuthGate(child: SizedBox.shrink())),
      ShellRoute(
        builder: (context, state, child) => AuthGate(child: ConsoleShell(location: state.uri.path, child: child)),
        routes: [
          GoRoute(path: '/queue', pageBuilder: (_, _) => const NoTransitionPage(child: QueuePage())),
          GoRoute(
            path: '/cases/:id',
            pageBuilder: (_, s) => NoTransitionPage(
              key: ValueKey(s.pathParameters['id']),
              child: CaseDetailPage(caseId: s.pathParameters['id']!),
            ),
          ),
          GoRoute(path: '/map', pageBuilder: (_, _) => const NoTransitionPage(child: LiveMapPage())),
          GoRoute(path: '/maritime', pageBuilder: (_, _) => const NoTransitionPage(child: MaritimePage())),
          GoRoute(path: '/atreides', pageBuilder: (_, _) => const NoTransitionPage(child: AtreidesPage())),
          GoRoute(path: '/dashboards', pageBuilder: (_, _) => const NoTransitionPage(child: DashboardsPage())),
          GoRoute(path: '/cctv', pageBuilder: (_, _) => const NoTransitionPage(child: CctvPage())),
          GoRoute(path: '/admin', pageBuilder: (_, _) => const NoTransitionPage(child: AdminPage())),
          GoRoute(path: '/audit', pageBuilder: (_, _) => const NoTransitionPage(child: AuditPage())),
        ],
      ),
    ],
  );
}
