import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'alert_sound_stub.dart' if (dart.library.js_interop) 'alert_sound_web.dart';

/// Audible alert for new / escalated cases at the dispatcher's desk.
abstract class AlertSound {
  void play({bool critical = false});
}

final alertSoundProvider = Provider<AlertSound>((ref) => createAlertSound());
