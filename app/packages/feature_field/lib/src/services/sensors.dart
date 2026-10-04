import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_native/uavr_native.dart';
import '../json_util.dart';

/// One GPS fix of this phone.
class GpsFix {
  const GpsFix({required this.position, required this.at, this.accuracyM, this.altM});
  final LatLon position;
  final double? accuracyM;
  final double? altM;
  final DateTime at;

  /// `observer` object of FieldObservationIn.
  Json toObserverJson() => compact({'lat': position.lat, 'lon': position.lon, 'accuracy_m': accuracyM});
}

/// Result of asking for the Remote ID scan permissions.
class ScanPermissions {
  const ScanPermissions({required this.bluetooth, required this.location, required this.nearbyWifi});
  final bool bluetooth, location, nearbyWifi;
  bool get all => bluetooth && location && nearbyWifi;
}

/// GPS, compass and Remote ID access, injectable so tests can fake the hardware.
abstract class FieldSensors {
  /// Continuous GPS fixes (asks for location permission first; silent if denied).
  Stream<GpsFix> positions();

  /// A single fresh fix, or null if location is unavailable.
  Future<GpsFix?> currentFix();

  /// Back-camera pointing direction (azimuth / elevation).
  Stream<OrientationSample> orientation();

  Future<RemoteIdCapabilities> remoteIdCapabilities();

  /// Asks for BLUETOOTH_SCAN, ACCESS_FINE_LOCATION and NEARBY_WIFI_DEVICES.
  Future<ScanPermissions> requestScanPermissions();

  /// Decoded Remote ID drones; emits a PlatformException(code: 'permission') error when a permission is missing.
  Stream<RemoteIdDrone> remoteIdDrones();

  Future<void> openSettings();
}

/// Real hardware: geolocator + permission_handler + UavrNative.
class DeviceSensors implements FieldSensors {
  Future<bool> _ensureLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      return p == LocationPermission.always || p == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  GpsFix _fix(Position p) {
    // Magnetic declination for the compass needs a location.
    unawaited(UavrNative.setLocation(p.latitude, p.longitude, p.altitude).catchError((_) {}));
    return GpsFix(
      position: LatLon(p.latitude, p.longitude),
      accuracyM: p.accuracy,
      altM: p.altitude,
      at: p.timestamp.toUtc(),
    );
  }

  LocationSettings get _settings => defaultTargetPlatform == TargetPlatform.android
      ? AndroidSettings(accuracy: LocationAccuracy.best, distanceFilter: 3, intervalDuration: const Duration(seconds: 3))
      : const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 3);

  @override
  Stream<GpsFix> positions() async* {
    if (!await _ensureLocation()) return;
    yield* Geolocator.getPositionStream(locationSettings: _settings).map(_fix).handleError((Object _) {});
  }

  @override
  Future<GpsFix?> currentFix() async {
    if (!await _ensureLocation()) return null;
    try {
      return _fix(await Geolocator.getCurrentPosition(locationSettings: _settings)
          .timeout(const Duration(seconds: 15)));
    } catch (_) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        return last == null ? null : _fix(last);
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Stream<OrientationSample> orientation() => UavrNative.orientation(interval: const Duration(milliseconds: 150));

  @override
  Future<RemoteIdCapabilities> remoteIdCapabilities() async {
    try {
      return await UavrNative.remoteIdCapabilities();
    } catch (_) {
      return RemoteIdCapabilities.none;
    }
  }

  @override
  Future<ScanPermissions> requestScanPermissions() async {
    if (!UavrNative.isSupported) return const ScanPermissions(bluetooth: false, location: false, nearbyWifi: false);
    final r = await [Permission.bluetoothScan, Permission.locationWhenInUse, Permission.nearbyWifiDevices].request();
    bool ok(Permission p) => r[p]?.isGranted == true || r[p]?.isLimited == true;
    return ScanPermissions(
      bluetooth: ok(Permission.bluetoothScan),
      location: ok(Permission.locationWhenInUse),
      nearbyWifi: ok(Permission.nearbyWifiDevices),
    );
  }

  @override
  Stream<RemoteIdDrone> remoteIdDrones() => UavrNative.remoteIdDrones();

  @override
  Future<void> openSettings() => openAppSettings();
}

final fieldSensorsProvider = Provider<FieldSensors>((ref) => DeviceSensors());

/// Latest GPS fix of this phone (null until the first fix).
class MyFix extends Notifier<GpsFix?> {
  StreamSubscription<GpsFix>? _sub;

  @override
  GpsFix? build() {
    _sub = ref.watch(fieldSensorsProvider).positions().listen((f) => state = f, onError: (_) {});
    ref.onDispose(() => _sub?.cancel());
    return null;
  }

  /// The live fix if we have one, else a one-off request.
  Future<GpsFix?> current() async => state ?? await ref.read(fieldSensorsProvider).currentFix();
}

final myFixProvider = NotifierProvider<MyFix, GpsFix?>(MyFix.new);
