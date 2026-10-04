import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uavr_ui/uavr_ui.dart';

import 'l10n/informant_localizations.dart';
import 'push.dart';
import 'screens/case_status.dart';
import 'screens/home.dart';
import 'screens/onboarding.dart';
import 'screens/report/report_screen.dart';
import 'screens/sent.dart';
import 'screens/settings.dart';
import 'screens/zones.dart';
import 'services/report_sender.dart';
import 'services/settings.dart';
import 'services/uploads.dart';

GoRouter buildInformantRouter({required bool onboarded}) => GoRouter(
      initialLocation: onboarded ? '/' : '/onboarding',
      routes: [
        GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
        GoRoute(
          path: '/',
          builder: (_, _) => const HomeScreen(),
          routes: [
            GoRoute(path: 'report', builder: (_, _) => const ReportScreen()),
            GoRoute(
              path: 'sent',
              redirect: (_, state) => state.extra is SentArgs ? null : '/',
              builder: (_, state) => SentScreen(state.extra! as SentArgs),
            ),
            GoRoute(
              path: 'case/:caseNumber',
              builder: (_, state) => CaseStatusScreen(state.pathParameters['caseNumber']!),
            ),
            GoRoute(path: 'zones', builder: (_, _) => const ZonesScreen()),
            GoRoute(path: 'settings', builder: (_, _) => const SettingsScreen()),
          ],
        ),
      ],
    );

/// The informant app (Android and web).
class InformantApp extends ConsumerStatefulWidget {
  const InformantApp({super.key});

  @override
  ConsumerState<InformantApp> createState() => _InformantAppState();
}

class _InformantAppState extends ConsumerState<InformantApp> {
  GoRouter? _router;

  @override
  void dispose() {
    _router?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(informantSettingsProvider);
    if (settings.isLoading && !settings.hasValue) {
      return MaterialApp(theme: uavrTheme(), home: const Scaffold(body: LoadingView()));
    }
    final router = _router ??= buildInformantRouter(onboarded: settings.value?.onboarded ?? false);
    return MaterialApp.router(
      onGenerateTitle: (context) => UavrL10n.of(context).appName,
      theme: uavrTheme(),
      darkTheme: uavrTheme(brightness: Brightness.dark),
      locale: ref.watch(appLocaleProvider),
      supportedLocales: informantLocales,
      localizationsDelegates: const [
        InformantL10n.delegate,
        UavrL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) => _BackgroundWork(child: child ?? const SizedBox.shrink()),
    );
  }
}

/// Retries the outbox on start and every 30 s while the app is open, resumes evidence
/// uploads and starts push.
class _BackgroundWork extends ConsumerStatefulWidget {
  const _BackgroundWork({required this.child});
  final Widget child;

  static const retryInterval = Duration(seconds: 30);

  @override
  ConsumerState<_BackgroundWork> createState() => _BackgroundWorkState();
}

class _BackgroundWorkState extends ConsumerState<_BackgroundWork> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(_BackgroundWork.retryInterval, (_) => _flush());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _flush();
      ref.read(evidenceUploadsProvider).run().ignore();
      ref.read(informantPushProvider).start().ignore();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _flush();
      ref.read(informantPushProvider).refreshStatuses();
    }
  }

  void _flush() => ref.read(reportSenderProvider).flushOutbox().ignore();

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
