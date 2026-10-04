import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_core/uavr_core.dart';

/// Shared startup for the three builds. Each build has its own entrypoint and imports only its
/// own feature package, so tree shaking keeps the other builds' screens out of the bundle.
Future<void> runUavr(AppFlavor flavor, Widget app, {Future<void> Function(AppConfig)? before}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment(flavor);
  await before?.call(config);
  runApp(ProviderScope(overrides: [configProvider.overrideWithValue(config)], child: app));
}
