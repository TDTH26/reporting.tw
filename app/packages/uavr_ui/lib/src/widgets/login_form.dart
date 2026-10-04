import 'package:flutter/material.dart';

/// Username + password form shared by the console and the field app (texts come from the caller's l10n).
class StaffLoginForm extends StatefulWidget {
  const StaffLoginForm({
    super.key,
    required this.onSubmit,
    required this.usernameLabel,
    required this.passwordLabel,
    required this.submitLabel,
  });

  /// Returns an error message to show, or null on success.
  final Future<String?> Function(String username, String password) onSubmit;
  final String usernameLabel, passwordLabel, submitLabel;

  @override
  State<StaffLoginForm> createState() => _StaffLoginFormState();
}

class _StaffLoginFormState extends State<StaffLoginForm> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false, _obscure = true;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_user.text.trim().isEmpty || _pass.text.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await widget.onSubmit(_user.text.trim(), _pass.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
      if (err != null) _pass.clear();
    });
  }

  @override
  Widget build(BuildContext context) => AutofillGroup(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            key: const Key('login-username'),
            controller: _user,
            autofillHints: const [AutofillHints.username],
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: InputDecoration(labelText: widget.usernameLabel, prefixIcon: const Icon(Icons.person_outline)),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('login-password'),
            controller: _pass,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: widget.passwordLabel,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('sign-in'),
            onPressed: _busy ? null : _submit,
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.login),
            label: Text(widget.submitLabel),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, key: const Key('login-error'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ]),
      );
}
