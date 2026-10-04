import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/access.dart';
import '../common/l10n.dart';
import 'shell_controls.dart';

/// Sign-in page / no-access page until a staff member with a console role is signed in.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    return me.when(
      skipLoadingOnRefresh: true,
      loading: () => const Scaffold(body: LoadingView()),
      error: (e, _) => Scaffold(body: ErrorView(e, onRetry: () => ref.invalidate(meProvider))),
      data: (m) {
        if (m == null) return const SignInPage();
        if (!hasConsoleAccess(m)) return const NoAccessPage();
        return child;
      },
    );
  }
}

class _Branded extends StatelessWidget {
  const _Branded({required this.children, this.languageInCard = false});
  final List<Widget> children;

  /// The sign-in card has its own language switch; other pages keep the corner button.
  final bool languageInCard;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      body: Stack(children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (languageInCard) ...[const LanguageSwitch(), const SizedBox(height: 20)],
                  Image.asset('packages/feature_agency/assets/app_icon.png',
                      width: 72, height: 72, semanticLabel: 'reporting.tw', filterQuality: FilterQuality.medium),
                  const SizedBox(height: 16),
                  // "Reporting.tw" on its own line, the description below it
                  Text(context.l.consoleTitle.replaceFirst(RegExp(r'^Reporting\.tw\s*[:：]\s*'), 'Reporting.tw\n'),
                      style: t.textTheme.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(context.l.consoleSubtitle,
                      style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ...children,
                ]),
              ),
            ),
          ),
        ),
        Positioned(
            top: 8, right: 8, child: Row(children: [if (!languageInCard) const LanguageButton(), const ThemeButton()])),
      ]),
    );
  }
}

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});
  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final netErr = context.u.errorNetwork;
    return _Branded(languageInCard: true, children: [
      StaffLoginForm(
        usernameLabel: l.loginUsername,
        passwordLabel: l.loginPassword,
        submitLabel: l.signInAgency,
        onSubmit: (u, p) async {
      final auth = ref.read(staffAuthProvider);
      try {
        await auth.login(u, p);
        return null;
      } on ApiException catch (e) {
        if (e.isNetwork) return netErr;
        if (e.isRateLimited) return l.loginTooMany;
        if (e.message.contains('locked')) return l.loginLocked;
        return l.loginWrongCredentials;
      }
        },
      ),
      const SizedBox(height: 16),
      const DemoBanner(),
      const SizedBox(height: 12),
      Text(l.signInHint, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
      const SizedBox(height: 8),
      _LinkedText(l.requestAccount, key: const Key('request-account')),
      const SizedBox(height: 4),
      _LinkedText(l.fileReportVia, key: const Key('file-report-via')),
    ]);
  }
}

/// Small centred text whose first e-mail address or https URL is a clickable link.
class _LinkedText extends StatelessWidget {
  const _LinkedText(this.text, {super.key});
  final String text;

  static final _link = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+|https://\S+');

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final style = t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant);
    final m = _link.firstMatch(text);
    if (m == null) return Text(text, style: style, textAlign: TextAlign.center);
    final target = m[0]!;
    final mail = target.contains('@');
    final uri = Uri.parse(mail ? 'mailto:$target' : target);
    return Text.rich(
      TextSpan(style: style, children: [
        TextSpan(text: text.substring(0, m.start)),
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => launchUrl(uri, webOnlyWindowName: mail ? '_self' : '_blank'),
              child: Text(target,
                  style: style?.copyWith(
                      color: t.colorScheme.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: t.colorScheme.primary)),
            ),
          ),
        ),
        TextSpan(text: text.substring(m.end)),
      ]),
      textAlign: TextAlign.center,
    );
  }
}

class NoAccessPage extends ConsumerWidget {
  const NoAccessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    return _Branded(children: [
      const Icon(Icons.block, size: 40, color: UavrColors.critical),
      const SizedBox(height: 8),
      Text(l.noAccessTitle, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Text(l.noAccessBody, textAlign: TextAlign.center),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: () => ref.read(staffAuthProvider).logout(),
        icon: const Icon(Icons.logout),
        label: Text(l.signOut),
      ),
    ]);
  }
}
