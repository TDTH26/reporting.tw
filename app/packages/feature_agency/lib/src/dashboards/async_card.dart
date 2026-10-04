import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/run_action.dart';

/// Section that renders an AsyncValue with loading / error states.
class AsyncSection<T> extends StatelessWidget {
  const AsyncSection({super.key, required this.title, required this.value, required this.builder, this.trailing, this.minHeight = 120});
  final String title;
  final AsyncValue<T> value;
  final Widget Function(T) builder;
  final Widget? trailing;
  final double minHeight;

  @override
  Widget build(BuildContext context) => Section(
        title: title,
        trailing: trailing,
        child: value.when(
          skipLoadingOnRefresh: false,
          loading: () => SizedBox(height: minHeight, child: const LoadingView()),
          error: (e, _) => SizedBox(height: minHeight, child: ErrorView(errorText(e))),
          data: builder,
        ),
      );
}
