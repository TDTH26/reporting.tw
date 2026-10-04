import 'alert_sound.dart';

class _Silent implements AlertSound {
  @override
  void play({bool critical = false}) {}
}

AlertSound createAlertSound() => _Silent();
