/// Android native capabilities for reporting.tw: Remote ID (OpenDroneID)
/// reception, back-camera orientation and Play Integrity, with web fallbacks.
library;

import 'dart:async';

import 'src/astm_f3411.dart';
import 'src/models.dart';
import 'src/platform/platform_native.dart'
    if (dart.library.js_interop) 'src/platform/platform_web.dart'
    as impl;

export 'src/astm_f3411.dart';
export 'src/models.dart';

abstract final class UavrNative {
  /// True on Android; false elsewhere (web, desktop, tests).
  static bool get isSupported => impl.isSupported;

  /// Remote ID transports this device can receive. All false off Android.
  static Future<RemoteIdCapabilities> remoteIdCapabilities() => impl.remoteIdCapabilities();

  /// Raw Remote ID frames. Scanning runs on all supported transports while the
  /// stream is listened to and stops on cancel.
  ///
  /// The app must have requested BLUETOOTH_SCAN, ACCESS_FINE_LOCATION and
  /// NEARBY_WIFI_DEVICES first. If any is missing, a [PlatformException] with
  /// code `'permission'` is emitted as a stream error; transports whose
  /// permissions are granted keep scanning.
  static Stream<RemoteIdFrame> remoteIdFrames() => impl.remoteIdFrames();

  /// Frames decoded and merged per drone. A drone is emitted when its decoded
  /// state changes, and at least once a second while it keeps transmitting.
  /// Stream errors from [remoteIdFrames] are forwarded.
  static Stream<RemoteIdDrone> remoteIdDrones() => Stream.multi((controller) {
    final tracker = RemoteIdTracker();
    final emitted = <String, RemoteIdDrone>{};
    final sub = remoteIdFrames().listen(
      (frame) {
        if (decodeAstm(frame.payload).isEmpty) return;
        final drone = tracker.add(frame);
        final prev = emitted[drone.sourceAddress];
        if (prev == null ||
            !drone.sameStateAs(prev) ||
            drone.lastSeen.difference(prev.lastSeen) >= const Duration(seconds: 1)) {
          emitted[drone.sourceAddress] = drone;
          emitted.removeWhere((k, _) => !tracker.drones.containsKey(k));
          controller.addSync(drone);
        }
      },
      onError: controller.addErrorSync,
      onDone: controller.closeSync,
    );
    controller
      ..onPause = sub.pause
      ..onResume = sub.resume
      ..onCancel = sub.cancel;
  });

  /// Back-camera pointing direction, at most one sample per [interval].
  static Stream<OrientationSample> orientation({
    Duration interval = const Duration(milliseconds: 100),
  }) => impl.orientation(interval);

  /// Last GPS fix, used for magnetic declination. No-op off Android.
  static Future<void> setLocation(double lat, double lon, double altM) =>
      impl.setLocation(lat, lon, altM);

  /// Play Integrity standard-request token bound to [requestHash], or null
  /// when unavailable (no Play services, web, any error).
  static Future<String?> integrityToken(String requestHash, {required int cloudProjectNumber}) =>
      impl.integrityToken(requestHash, cloudProjectNumber);
}
