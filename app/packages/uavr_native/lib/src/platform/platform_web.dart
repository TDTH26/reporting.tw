import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math' as math;

import 'package:web/web.dart' as web;

import '../models.dart';
import '../orientation_math.dart';

bool get isSupported => false;

Future<RemoteIdCapabilities> remoteIdCapabilities() async => RemoteIdCapabilities.none;

Stream<RemoteIdFrame> remoteIdFrames() => const Stream.empty();

Future<void> setLocation(double lat, double lon, double altM) async {}

Future<String?> integrityToken(String requestHash, int cloudProjectNumber) async => null;

/// iOS Safari exposes a magnetic compass heading instead of absolute events.
extension type _WebkitOrientationEvent(web.DeviceOrientationEvent _)
    implements web.DeviceOrientationEvent {
  external double? get webkitCompassHeading;
}

/// Uses `deviceorientationabsolute` (Chrome/Android) when the browser has it,
/// else `deviceorientation`, taking `webkitCompassHeading` as the absolute
/// heading on iOS Safari. On iOS the app must first call
/// `DeviceOrientationEvent.requestPermission()` from a user gesture.
Stream<OrientationSample> orientation(Duration interval) {
  final type = web.window.has('ondeviceorientationabsolute')
      ? 'deviceorientationabsolute'
      : 'deviceorientation';
  late final StreamController<OrientationSample> controller;
  JSFunction? listener;
  DateTime? lastEmit;
  double? sx, sy, sz; // low-passed camera axis

  void onEvent(web.DeviceOrientationEvent e) {
    var alpha = e.alpha;
    final beta = e.beta, gamma = e.gamma;
    if (beta == null || gamma == null) return;
    var absolute = e.absolute;
    final compass = _WebkitOrientationEvent(e).webkitCompassHeading;
    if (compass != null) {
      alpha = 360 - compass;
      absolute = true;
    }
    if (alpha == null) return;

    final w = cameraAxis(alpha, beta, gamma);
    if (sx == null) {
      sx = w.x;
      sy = w.y;
      sz = w.z;
    } else {
      // Smooth the unit vector rather than the angles, so 359°→0° can't jump.
      const k = 0.3;
      sx = sx! + k * (w.x - sx!);
      sy = sy! + k * (w.y - sy!);
      sz = sz! + k * (w.z - sz!);
    }

    final now = DateTime.now().toUtc();
    if (lastEmit != null && now.difference(lastEmit!) < interval) return;
    lastEmit = now;

    final n = math.sqrt(sx! * sx! + sy! * sy! + sz! * sz!);
    if (n == 0) return;
    final az = (math.atan2(sx!, sy!) * degPerRad + 360) % 360;
    final el = math.asin((sz! / n).clamp(-1.0, 1.0)) * degPerRad;
    controller.add(
      OrientationSample(
        azimuthDeg: az,
        magneticAzimuthDeg: az,
        elevationDeg: el,
        declinationDeg: 0,
        accuracy: absolute ? 1 : 0,
        at: now,
      ),
    );
  }

  controller = StreamController<OrientationSample>(
    onListen: () {
      listener = onEvent.toJS;
      web.window.addEventListener(type, listener);
    },
    onCancel: () {
      web.window.removeEventListener(type, listener);
      listener = null;
    },
  );
  return controller.stream;
}
