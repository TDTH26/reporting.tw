import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../widgets/common.dart';
import 'logout.dart';

class _MdmNote extends StatelessWidget {
  const _MdmNote();
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.phonelink_lock, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(context.f.mdmNote, style: Theme.of(context).textTheme.bodySmall)),
      ]);
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final l = context.f;
    final t = Theme.of(context).textTheme;
    final netErr = context.u.errorNetwork;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Icon(Icons.local_police, size: 64, color: UavrColors.brand),
                const SizedBox(height: 16),
                Text(l.appTitle, textAlign: TextAlign.center, style: t.headlineSmall),
                const SizedBox(height: 8),
                Text(l.loginSubtitle, textAlign: TextAlign.center, style: t.bodyMedium),
                const SizedBox(height: 32),
                StaffLoginForm(
                  usernameLabel: l.loginUsername,
                  passwordLabel: l.loginPassword,
                  submitLabel: l.signIn,
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
                const SizedBox(height: 32),
                const _MdmNote(),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class NoAccessScreen extends ConsumerWidget {
  const NoAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.f;
    return Scaffold(
      appBar: AppBar(title: Text(l.appTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.block, size: 56, color: UavrColors.critical),
          const SizedBox(height: 16),
          Text(l.noAccessTitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(l.noAccessBody, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => confirmLogout(context, ref),
            icon: const Icon(Icons.logout),
            label: Text(l.signOut),
          ),
          const SizedBox(height: 24),
          const _MdmNote(),
        ]),
      ),
    );
  }
}
