import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../services/my_reports.dart';
import '../services/settings.dart';
import '../widgets/common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Section(
              title: context.u.languageLabel,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
              child: LanguageList(
                selected: ref.watch(appLocaleProvider),
                onSelected: (locale) => ref.read(informantSettingsProvider.notifier).setLocale(locale),
              ),
            ),
            const SizedBox(height: 12),
            Section(
              title: l.settingsPrivacy,
              child: Text(l.settingsPrivacyBody, style: theme.textTheme.bodyMedium),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: Text(l.settingsClearHistory),
                  onTap: () => _clearHistory(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: Text(l.settingsShowIntro),
                  onTap: () async {
                    await ref.read(informantSettingsProvider.notifier).setOnboarded(false);
                    if (context.mounted) context.go('/onboarding');
                  },
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Text(
              l.settingsVersion(ref.watch(configProvider).appVersion),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _clearHistory(BuildContext context, WidgetRef ref) async {
    final l = context.l;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.settingsClearHistory),
        content: Text(l.settingsClearHistoryBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.u.cancel)),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.settingsClear),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final store = ref.read(informantStoreProvider);
    for (final r in await store.reports()) {
      await store.remove(r.token);
    }
    ref.invalidate(myReportsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.settingsHistoryCleared)));
    }
  }
}
