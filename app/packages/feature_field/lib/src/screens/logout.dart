import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../services/offline_cache.dart';
import '../services/outbox.dart';
import '../widgets/common.dart';

/// Signs out after confirming. Unsent observations belong to this officer (chain of custody),
/// so they are discarded rather than sent later under someone else's account.
Future<void> confirmLogout(BuildContext context, WidgetRef ref) async {
  final l = context.f;
  final pending = ref.read(outboxProvider).length;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(l.signOut),
      content: Text(pending > 0 ? l.signOutPendingWarning(pending) : l.signOutConfirm),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(UavrL10n.of(c).cancel)),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.signOut)),
      ],
    ),
  );
  if (ok != true) return;
  await ref.read(outboxProvider.notifier).clear();
  await ref.read(offlineCacheProvider).clear();
  try {
    await ref.read(staffAuthProvider).logout();
  } catch (_) {}
  ref.invalidate(meProvider);
}
