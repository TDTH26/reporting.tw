import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'alert_sound.dart';
import 'wav.dart';

class _WebAlertSound implements AlertSound {
  late final String _normal = 'data:audio/wav;base64,${base64Encode(beepWav())}';
  late final String _critical =
      'data:audio/wav;base64,${base64Encode(beepWav(freqs: const [1320, 990, 1320, 990], toneSec: 0.14))}';

  @override
  void play({bool critical = false}) {
    try {
      final a = web.HTMLAudioElement()..src = critical ? _critical : _normal;
      // Browsers may block audio before the first user gesture; the visual alert still shows.
      a.play().toDart.catchError((_) => null);
    } catch (_) {}
  }
}

AlertSound createAlertSound() => _WebAlertSound();
