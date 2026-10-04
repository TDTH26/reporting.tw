import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/l10n.dart';
import '../common/settings.dart';
import '../live/live_state.dart';

class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    return PopupMenuButton<Locale>(
      tooltip: context.l.language,
      icon: const Icon(Icons.translate),
      initialValue: s.locale,
      onSelected: ref.read(settingsProvider.notifier).setLocale,
      itemBuilder: (_) => const [
        PopupMenuItem(value: Locale('zh', 'TW'), child: Text('繁體中文')),
        PopupMenuItem(value: Locale('en'), child: Text('English')),
      ],
    );
  }
}

/// Two-way language toggle for the sign-in card (one click instead of a menu).
class LanguageSwitch extends ConsumerWidget {
  const LanguageSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final en = ref.watch(settingsProvider).locale.languageCode == 'en';
    return SizedBox(
      width: 260,
      child: SegmentedButton<bool>(
        key: const Key('login-language'),
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: false, label: Text('繁體中文', maxLines: 1, softWrap: false)),
          ButtonSegment(value: true, label: Text('English', maxLines: 1, softWrap: false)),
        ],
        selected: {en},
        onSelectionChanged: (s) =>
            ref.read(settingsProvider.notifier).setLocale(s.first ? const Locale('en') : const Locale('zh', 'TW')),
      ),
    );
  }
}

class ThemeButton extends ConsumerWidget {
  const ThemeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(settingsProvider).dark;
    return IconButton(
      tooltip: dark ? context.l.themeLight : context.l.themeDark,
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: ref.read(settingsProvider.notifier).toggleDark,
    );
  }
}

class LiveIndicator extends ConsumerWidget {
  const LiveIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final s = ref.watch(liveStateProvider).value ?? LiveState.disconnected;
    final (color, label) = switch (s) {
      LiveState.connected => (UavrColors.low, l.liveConnected),
      LiveState.connecting => (UavrColors.medium, l.liveConnecting),
      LiveState.disconnected => (UavrColors.critical, l.liveDisconnected),
    };
    return Tooltip(
      message: l.liveTooltip,
      child: Pill(label, color: color, icon: s == LiveState.connected ? Icons.wifi_tethering : Icons.wifi_tethering_off),
    );
  }
}

class DutySwitch extends ConsumerStatefulWidget {
  const DutySwitch({super.key});
  @override
  ConsumerState<DutySwitch> createState() => _DutySwitchState();
}

class _DutySwitchState extends ConsumerState<DutySwitch> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final on = ref.watch(dutyProvider);
    return Tooltip(
      message: l.onDutyTooltip,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(on ? l.onDuty : l.offDuty,
            style: TextStyle(fontWeight: FontWeight.w600, color: on ? UavrColors.low : UavrColors.redacted)),
        Switch(
          key: const Key('duty-switch'),
          value: on,
          onChanged: _busy
              ? null
              : (v) async {
                  setState(() => _busy = true);
                  try {
                    await ref.read(dutyProvider.notifier).set(v);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l.actionFailed}: $e')));
                    }
                  }
                  if (mounted) setState(() => _busy = false);
                },
        ),
      ]),
    );
  }
}

class UserMenu extends ConsumerWidget {
  const UserMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider).value;
    if (me == null) return const SizedBox.shrink();
    final l = context.l;
    return PopupMenuButton<String>(
      tooltip: me.displayName,
      onSelected: (v) {
        if (v == 'logout') ref.read(staffAuthProvider).logout();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(me.displayName.isEmpty ? me.username : me.displayName,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(me.username),
            if (me.desk != null) Text(me.desk!.label(context.lang)),
            if (me.agency != null) Text(me.agency!.label(context.lang)),
            Text('${l.roles}: ${me.roles.join(', ')}'),
            Text('${l.clearance}: ${me.clearance}'),
          ]),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'logout', child: ListTile(leading: const Icon(Icons.logout), title: Text(l.signOut))),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: CircleAvatar(
          radius: 16,
          child: Text((me.displayName.isEmpty ? me.username : me.displayName).characters.first.toUpperCase()),
        ),
      ),
    );
  }
}
