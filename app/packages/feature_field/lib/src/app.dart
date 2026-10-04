import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_ui/uavr_ui.dart';

import 'l10n/field_localizations.dart';
import 'screens/assignments_screen.dart';
import 'screens/case_screen.dart';
import 'screens/evidence_screen.dart';
import 'screens/login_screen.dart';
import 'screens/outbox_screen.dart';
import 'screens/remote_id_scan_screen.dart';
import 'services/assignments.dart';
import 'services/outbox.dart';
import 'services/position_sharing.dart';
import 'services/session.dart';

const fieldLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  FieldL10n.delegate,
  UavrL10n.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

GoRouter buildFieldRouter() => GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const FieldGate()),
      GoRoute(path: '/outbox', builder: (_, _) => const OutboxScreen()),
      GoRoute(
        path: '/case/:id',
        builder: (_, s) => CaseScreen(caseId: s.pathParameters['id']!, initial: s.extra as CaseSummary?),
        routes: [
          GoRoute(
            path: 'scan',
            builder: (_, s) => RemoteIdScanScreen(
              caseId: s.pathParameters['id']!,
              caseNumber: s.uri.queryParameters['n'] ?? '',
            ),
          ),
          GoRoute(
            path: 'evidence',
            builder: (_, s) => EvidenceScreen(
              caseId: s.pathParameters['id']!,
              caseNumber: s.uri.queryParameters['n'] ?? '',
            ),
          ),
        ],
      ),
    ]);

/// Field officer app (Android, MDM-managed).
class FieldApp extends ConsumerStatefulWidget {
  const FieldApp({super.key});

  @override
  ConsumerState<FieldApp> createState() => _FieldAppState();
}

class _FieldAppState extends ConsumerState<FieldApp> {
  late final GoRouter _router = buildFieldRouter();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycle);
  }

  void _onLifecycle(AppLifecycleState s) {
    switch (s) {
      case AppLifecycleState.resumed:
        ref.read(positionSharingProvider.notifier).setForeground(true);
        if (ref.read(fieldSessionProvider).value?.isFieldOfficer == true) {
          ref.read(outboxProvider.notifier).retryAll();
          ref.read(assignmentsProvider.notifier).load();
        }
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        ref.read(positionSharingProvider.notifier).setForeground(false);
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        onGenerateTitle: (c) => FieldL10n.of(c).appTitle,
        debugShowCheckedModeBanner: false,
        theme: uavrTheme(),
        darkTheme: uavrTheme(brightness: Brightness.dark),
        supportedLocales: staffLocales,
        localizationsDelegates: fieldLocalizationsDelegates,
        localeResolutionCallback: (device, supported) => resolveLocale(device, staffLocales),
        routerConfig: _router,
      );
}

/// Login / role check in front of the assignments list.
class FieldGate extends ConsumerWidget {
  const FieldGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(fieldSessionProvider);
    return s.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: () => const Scaffold(body: LoadingView()),
      error: (e, _) => Scaffold(
        body: ErrorView(e, onRetry: () {
          ref.invalidate(meProvider);
          ref.invalidate(fieldSessionProvider);
        }),
      ),
      data: (session) {
        if (!session.signedIn) return const LoginScreen();
        if (!session.isFieldOfficer) return const NoAccessScreen();
        ref.watch(outboxProvider); // starts the outbox retry timer
        return const AssignmentsScreen();
      },
    );
  }
}
