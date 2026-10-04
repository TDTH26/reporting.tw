import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../services/permissions.dart';
import '../services/settings.dart';
import '../widgets/common.dart';

/// First-run introduction: language, what to report, safety, privacy, and (Android) permissions.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(informantSettingsProvider.notifier).setOnboarded(true);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final gate = ref.watch(permissionGateProvider);
    final pages = <Widget>[
      _LanguagePage(),
      const _WhatPage(),
      const _SafetyPage(),
      const _PrivacyPage(),
      if (gate.asksUpFront) const _PermissionsPage(),
    ];
    final last = _index == pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: (i) => setState(() => _index = i),
              children: [
                for (final p in pages)
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: p),
                    ),
                  ),
              ],
            ),
          ),
          _Dots(count: pages.length, index: _index),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Row(children: [
              if (!last) TextButton(onPressed: _finish, child: Text(context.l.skip)),
              const Spacer(),
              FilledButton(
                onPressed: last
                    ? _finish
                    : () => _pages.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                child: Text(last ? context.l.onboardingStart : context.u.next),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(4),
            width: i == index ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? scheme.primary : scheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ]),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle(this.icon, this.title);
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
      ]);
}

class _LanguagePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _PageTitle(Icons.translate, context.l.onboardingLanguageTitle),
        Text(context.l.onboardingLanguageBody),
        const SizedBox(height: 8),
        LanguageList(
          selected: ref.watch(appLocaleProvider),
          onSelected: (l) => ref.read(informantSettingsProvider.notifier).setLocale(l),
        ),
      ]);
}

class _WhatPage extends StatelessWidget {
  const _WhatPage();

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _PageTitle(Icons.flight, context.l.onboardingWhatTitle),
        Text(context.l.onboardingWhatBody, style: Theme.of(context).textTheme.bodyLarge),
      ]);
}

class _SafetyPage extends StatelessWidget {
  const _SafetyPage();

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _PageTitle(Icons.health_and_safety_outlined, context.l.onboardingSafetyTitle),
        IconLine(Icons.do_not_disturb_on_outlined, context.l.onboardingSafetyApproach, color: UavrColors.critical),
        IconLine(Icons.social_distance, context.l.onboardingSafetyDistance),
        IconLine(Icons.local_phone, context.l.onboardingSafetyDanger, color: UavrColors.critical),
      ]);
}

class _PrivacyPage extends StatelessWidget {
  const _PrivacyPage();

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _PageTitle(Icons.privacy_tip_outlined, context.l.onboardingPrivacyTitle),
        IconLine(Icons.person_off_outlined, context.l.onboardingPrivacyNoAccount),
        IconLine(Icons.list_alt, context.l.onboardingPrivacyCollected),
        IconLine(Icons.account_balance_outlined, context.l.onboardingPrivacyUse),
      ]);
}

class _PermissionsPage extends StatelessWidget {
  const _PermissionsPage();

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _PageTitle(Icons.verified_user_outlined, l.onboardingPermissionsTitle),
      Text(l.onboardingPermissionsBody),
      const SizedBox(height: 12),
      _PermissionTile(InformantPermission.location, Icons.location_on_outlined, l.permLocationTitle, l.permLocationBody),
      _PermissionTile(InformantPermission.camera, Icons.photo_camera_outlined, l.permCameraTitle, l.permCameraBody),
      _PermissionTile(InformantPermission.microphone, Icons.mic_none, l.permMicrophoneTitle, l.permMicrophoneBody),
      _PermissionTile(InformantPermission.nearby, Icons.bluetooth_searching, l.permNearbyTitle, l.permNearbyBody),
      _PermissionTile(
          InformantPermission.notifications, Icons.notifications_none, l.permNotificationsTitle, l.permNotificationsBody),
    ]);
  }
}

/// Explains one permission and asks for it only when the user taps "Allow".
class _PermissionTile extends ConsumerStatefulWidget {
  const _PermissionTile(this.permission, this.icon, this.title, this.body);
  final InformantPermission permission;
  final IconData icon;
  final String title;
  final String body;

  @override
  ConsumerState<_PermissionTile> createState() => _PermissionTileState();
}

class _PermissionTileState extends ConsumerState<_PermissionTile> {
  bool? _granted;
  bool _asked = false;

  @override
  void initState() {
    super.initState();
    ref.read(permissionGateProvider).isGranted(widget.permission).then((g) {
      if (mounted) setState(() => _granted = g);
    }).catchError((_) {});
  }

  Future<void> _request() async {
    final gate = ref.read(permissionGateProvider);
    if (_asked && _granted == false) return gate.openSettings();
    final granted = await gate.request(widget.permission).catchError((_) => false);
    if (!mounted) return;
    setState(() {
      _granted = granted;
      _asked = true;
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(widget.icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(widget.body),
            ]),
          ),
          const SizedBox(width: 8),
          _granted == true
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Pill(context.l.permGranted, color: UavrColors.low, icon: Icons.check),
                )
              : TextButton(
                  onPressed: _request,
                  child: Text(_asked ? context.l.permOpenSettings : context.l.permAllow),
                ),
        ]),
      );
}
