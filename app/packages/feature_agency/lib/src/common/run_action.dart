import 'package:flutter/material.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_ui/uavr_ui.dart';

import 'l10n.dart';

String errorText(Object e) => e is ApiException ? e.message : '$e';

/// Shared helper: run an API action with error snackbar.
Future<T?> runAction<T>(BuildContext context, Future<T> Function() f, {String? success}) async {
  final l = context.l;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final r = await f();
    if (success != null) messenger.showSnackBar(SnackBar(content: Text(success)));
    return r;
  } catch (e) {
    messenger.showSnackBar(SnackBar(
      backgroundColor: UavrColors.critical,
      content: Text('${l.actionFailed}: ${errorText(e)}'),
    ));
    return null;
  }
}
