import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_native/uavr_native.dart';

import 'settings.dart';

/// One position fix of the informant.
class LocationFix {
  const LocationFix({required this.position, required this.at, this.accuracyM, this.altitudeM, this.manual = false});

  final LatLon position;
  final double? accuracyM;
  final double? altitudeM;
  final DateTime at;

  /// Set by tapping the map because GPS was unavailable.
  final bool manual;
}

enum LocationProblem { serviceDisabled, denied, unavailable }

class LocationException implements Exception {
  const LocationException(this.problem);
  final LocationProblem problem;

  @override
  String toString() => 'LocationException($problem)';
}

/// Live back-camera preview used for aiming.
abstract class AimCamera {
  Widget preview();
  Future<XFile> takePicture();
  Future<void> dispose();
}

/// Everything the report flow reads from the device. The default implementation uses
/// geolocator, the uavr_native plugin and the camera package; tests override
/// [informantSensorsProvider] with fakes.
abstract class InformantSensors {
  /// 'android' or 'web' (the API's platform values).
  String get platform;

  /// High-accuracy position updates. Emits [LocationException] when location is off or denied.
  Stream<LocationFix> locationFixes();

  /// Back-camera pointing direction (true north).
  Stream<OrientationSample> orientation();

  bool get remoteIdSupported;

  /// API transport codes this phone can receive ('bt4', 'bt5', 'wifi_beacon', 'wifi_nan').
  Future<List<String>> remoteIdTransports();

  /// Remote ID broadcasts decoded per drone. Emits a `PlatformException(code: 'permission')`
  /// when the nearby-devices permission is missing.
  Stream<RemoteIdDrone> remoteIdDrones();

  /// Gives the native compass the position, for magnetic declination.
  Future<void> setDeclinationLocation(LocationFix fix);

  Future<String?> integrityToken(String requestHash, int cloudProjectNumber);

  /// The back camera, or null when there is none or it can't be opened.
  Future<AimCamera?> openBackCamera();
}

class DeviceSensors implements InformantSensors {
  @override
  String get platform => kIsWeb ? 'web' : 'android';

  @override
  Stream<LocationFix> locationFixes() async* {
    if (!kIsWeb && !await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationProblem.serviceDisabled);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw const LocationException(LocationProblem.denied);
    }
    final settings = kIsWeb
        ? WebSettings(accuracy: LocationAccuracy.best, maximumAge: Duration.zero)
        : AndroidSettings(accuracy: LocationAccuracy.best, distanceFilter: 0, intervalDuration: const Duration(seconds: 1));
    try {
      yield* Geolocator.getPositionStream(locationSettings: settings).map(_fix);
    } on PermissionDeniedException {
      throw const LocationException(LocationProblem.denied);
    } on LocationServiceDisabledException {
      throw const LocationException(LocationProblem.serviceDisabled);
    }
  }

  static LocationFix _fix(Position p) => LocationFix(
        position: LatLon(p.latitude, p.longitude),
        accuracyM: p.accuracy > 0 ? p.accuracy : null,
        altitudeM: p.altitude,
        at: p.timestamp.toUtc(),
      );

  @override
  Stream<OrientationSample> orientation() => UavrNative.orientation();

  @override
  bool get remoteIdSupported => UavrNative.isSupported;

  @override
  Future<List<String>> remoteIdTransports() async {
    try {
      return (await UavrNative.remoteIdCapabilities()).transports;
    } catch (_) {
      return const [];
    }
  }

  @override
  Stream<RemoteIdDrone> remoteIdDrones() => UavrNative.isSupported ? UavrNative.remoteIdDrones() : const Stream.empty();

  @override
  Future<void> setDeclinationLocation(LocationFix fix) =>
      UavrNative.setLocation(fix.position.lat, fix.position.lon, fix.altitudeM ?? 0);

  @override
  Future<String?> integrityToken(String requestHash, int cloudProjectNumber) =>
      UavrNative.integrityToken(requestHash, cloudProjectNumber: cloudProjectNumber);

  @override
  Future<AimCamera?> openBackCamera() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) return null;
      final back = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cams.first);
      final controller = CameraController(back, ResolutionPreset.high, enableAudio: false);
      await controller.initialize();
      return _PluginCamera(controller);
    } catch (_) {
      return null; // permission denied or camera busy: aiming still works from the compass
    }
  }
}

class _PluginCamera implements AimCamera {
  _PluginCamera(this._c);
  final CameraController _c;

  @override
  Widget preview() => CameraPreview(_c);

  @override
  Future<XFile> takePicture() => _c.takePicture();

  @override
  Future<void> dispose() => _c.dispose();
}

final informantSensorsProvider = Provider<InformantSensors>((ref) => DeviceSensors());

/// Live orientation while aiming.
final orientationProvider = StreamProvider.autoDispose<OrientationSample>(
  (ref) => ref.watch(informantSensorsProvider).orientation(),
  retry: noRetry,
);
