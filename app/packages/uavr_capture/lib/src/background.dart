import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'upload_queue.dart';

const _task = 'uavr.evidence-upload';

/// WorkManager entry point: drains the upload queue in a background isolate.
@pragma('vm:entry-point')
void uploadCallbackDispatcher() {
  Workmanager().executeTask((task, input) async {
    WidgetsFlutterBinding.ensureInitialized();
    final q = UploadQueue();
    await q.run();
    return q.pendingCount == 0;
  });
}

/// Call once at startup on Android. Uploads continue if the app is closed or the phone reboots.
Future<void> registerBackgroundUploads() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  await Workmanager().initialize(uploadCallbackDispatcher);
  await Workmanager().registerPeriodicTask(
    _task,
    _task,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}

/// Ask WorkManager to run the queue as soon as there is network (after a report is sent).
Future<void> kickBackgroundUploads() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  await Workmanager().registerOneOffTask(
    '$_task.now',
    _task,
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingWorkPolicy.replace,
    backoffPolicy: BackoffPolicy.exponential,
  );
}
