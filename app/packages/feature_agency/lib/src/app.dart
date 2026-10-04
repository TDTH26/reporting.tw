import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uavr_ui/uavr_ui.dart';

import 'common/l10n.dart';
import 'common/settings.dart';
import 'router.dart';

/// Agency console root: auth gate, shell and routes.
class AgencyApp extends ConsumerStatefulWidget {
  const AgencyApp({super.key});

  @override
  ConsumerState<AgencyApp> createState() => _AgencyAppState();
}

class _AgencyAppState extends ConsumerState<AgencyApp> {
  late final GoRouter _router = buildRouter(ref);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    return MaterialApp.router(
      onGenerateTitle: (c) => c.l.consoleTitle,
      debugShowCheckedModeBanner: false,
      theme: uavrTheme(brightness: Brightness.light, dense: true),
      darkTheme: uavrTheme(brightness: Brightness.dark, dense: true),
      themeMode: s.dark ? ThemeMode.dark : ThemeMode.light,
      locale: s.locale,
      supportedLocales: staffLocales,
      localizationsDelegates: const [
        AgencyL10n.delegate,
        UavrL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
    );
  }
}
