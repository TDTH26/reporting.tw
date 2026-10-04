import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/l10n.dart';
import '../common/labels.dart';
import '../common/providers.dart';
import '../common/run_action.dart';

final usersProvider =
    FutureProvider.autoDispose<List<StaffAccount>>((ref) => ref.watch(staffApiProvider).users(), retry: (_, _) => null);

/// Staff accounts: create, edit roles/desk/clearance, reset passwords, deactivate.
class UsersAdmin extends ConsumerWidget {
  const UsersAdmin({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final users = ref.watch(usersProvider);
    final desks = ref.watch(desksByIdProvider);

    Future<void> edit(StaffAccount? u) async {
      final saved = await showDialog<bool>(context: context, builder: (_) => UserDialog(user: u));
      if (saved == true) ref.invalidate(usersProvider);
    }

    Future<void> toggleActive(StaffAccount u) async {
      await runAction(context, () => ref.read(staffApiProvider).updateUser(u, active: !u.active), success: l.userSaved);
      ref.invalidate(usersProvider);
    }

    return users.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(errorText(e), onRetry: () => ref.invalidate(usersProvider)),
      data: (rows) => ListView(padding: const EdgeInsets.all(12), children: [
        Row(children: [
          Expanded(child: Text(l.usersHint)),
          FilledButton.icon(
              key: const Key('new-user'), onPressed: () => edit(null), icon: const Icon(Icons.person_add), label: Text(l.newUser)),
        ]),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text(l.loginUsername)),
              DataColumn(label: Text(l.displayName)),
              DataColumn(label: Text(l.roles)),
              DataColumn(label: Text(l.desk)),
              DataColumn(label: Text(l.clearance)),
              DataColumn(label: Text(l.lastSeenLabel)),
              const DataColumn(label: Text('')),
            ],
            rows: [
              for (final u in rows)
                DataRow(cells: [
                  DataCell(Row(children: [
                    Text(u.username, style: TextStyle(decoration: u.active ? null : TextDecoration.lineThrough)),
                    if (!u.active) ...[const SizedBox(width: 6), Pill(l.deactivated, color: UavrColors.redacted)],
                    if (u.locked) ...[const SizedBox(width: 6), Pill(l.lockedLabel, color: UavrColors.medium)],
                  ])),
                  DataCell(Text(u.displayName)),
                  DataCell(Text(u.roles.join(', '))),
                  DataCell(Text(desks[u.deskId]?.label(context.lang) ?? '—')),
                  DataCell(Text(classificationLabel(l, u.clearance))),
                  DataCell(Text(u.lastSeen == null ? '—' : dateTime(u.lastSeen!))),
                  DataCell(Row(children: [
                    IconButton(tooltip: l.editUser, icon: const Icon(Icons.edit_outlined), onPressed: () => edit(u)),
                    TextButton(
                        onPressed: () => toggleActive(u), child: Text(u.active ? l.deactivate : l.reactivate)),
                  ])),
                ]),
            ],
          ),
        ),
      ]),
    );
  }
}

class UserDialog extends ConsumerStatefulWidget {
  const UserDialog({super.key, this.user});
  final StaffAccount? user;

  @override
  ConsumerState<UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends ConsumerState<UserDialog> {
  late StaffAccount _u = widget.user ?? StaffAccount(id: '', username: '', roles: const ['dispatcher']);
  late final _username = TextEditingController(text: _u.username);
  late final _name = TextEditingController(text: _u.displayName);
  final _password = TextEditingController();
  bool _saving = false;

  bool get _isNew => widget.user == null;

  @override
  void dispose() {
    _username.dispose();
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l;
    final api = ref.read(staffApiProvider);
    final u = _u.copyWith(username: _username.text.trim(), displayName: _name.text.trim());
    setState(() => _saving = true);
    final ok = await runAction(
      context,
      () => _isNew
          ? api.createUser(u, _password.text)
          : api.updateUser(u, newPassword: _password.text.isEmpty ? null : _password.text),
      success: l.userSaved,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok != null) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final desks = ref.watch(desksProvider).value ?? const <Desk>[];
    return AlertDialog(
      title: Text(_isNew ? l.newUser : '${l.editUser}: ${_u.username}'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_isNew)
              TextField(controller: _username, decoration: InputDecoration(labelText: l.loginUsername)),
            const SizedBox(height: 8),
            TextField(controller: _name, decoration: InputDecoration(labelText: l.displayName)),
            const SizedBox(height: 8),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(labelText: _isNew ? l.initialPassword : l.resetPassword),
            ),
            const SizedBox(height: 12),
            Text(l.roles, style: Theme.of(context).textTheme.labelLarge),
            Wrap(spacing: 6, children: [
              for (final r in staffRoles)
                FilterChip(
                  label: Text(r),
                  selected: _u.roles.contains(r),
                  onSelected: (on) => setState(() =>
                      _u = _u.copyWith(roles: on ? [..._u.roles, r] : _u.roles.where((x) => x != r).toList())),
                ),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _u.deskId,
              decoration: InputDecoration(labelText: l.desk),
              items: [
                DropdownMenuItem(value: null, child: Text(l.noDesk)),
                for (final d in desks) DropdownMenuItem(value: d.id, child: Text('${d.agencyCode} · ${d.label(context.lang)}')),
              ],
              onChanged: (v) => setState(() => _u = v == null ? _u.copyWith(clearDesk: true) : _u.copyWith(deskId: v)),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _u.clearance,
              decoration: InputDecoration(labelText: l.clearance),
              items: [for (final c in [0, 1, 2]) DropdownMenuItem(value: c, child: Text(classificationLabel(l, c)))],
              onChanged: (v) => setState(() => _u = _u.copyWith(clearance: v ?? 0)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.fieldUnitLabel),
              value: _u.fieldUnit,
              onChanged: (v) => setState(() => _u = _u.copyWith(fieldUnit: v)),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.u.cancel)),
        FilledButton(onPressed: _saving ? null : _save, child: Text(context.u.save)),
      ],
    );
  }
}
