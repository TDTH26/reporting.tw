import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

enum InformantPermission { location, camera, microphone, nearby, notifications }

/// Runtime permissions explained during onboarding. Denial never blocks reporting.
abstract class PermissionGate {
  /// Only Android asks for permissions up front; browsers prompt in context.
  bool get asksUpFront;
  Future<bool> isGranted(InformantPermission p);
  Future<bool> request(InformantPermission p);
  Future<void> openSettings();
}

class DevicePermissionGate implements PermissionGate {
  @override
  bool get asksUpFront => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static List<Permission> _map(InformantPermission p) => switch (p) {
        InformantPermission.location => [Permission.locationWhenInUse],
        InformantPermission.camera => [Permission.camera],
        InformantPermission.microphone => [Permission.microphone],
        // Remote ID: Bluetooth LE scanning plus Wi-Fi beacon / NAN (Android 13+).
        InformantPermission.nearby => [Permission.bluetoothScan, Permission.nearbyWifiDevices],
        InformantPermission.notifications => [Permission.notification],
      };

  @override
  Future<bool> isGranted(InformantPermission p) async {
    for (final perm in _map(p)) {
      if (!await perm.isGranted) return false;
    }
    return true;
  }

  @override
  Future<bool> request(InformantPermission p) async {
    final results = await _map(p).request();
    return results.values.every((s) => s.isGranted || s.isLimited);
  }

  @override
  Future<void> openSettings() => openAppSettings();
}

final permissionGateProvider = Provider<PermissionGate>((ref) => DevicePermissionGate());
