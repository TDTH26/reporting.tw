import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import '../models.dart';

const _method = MethodChannel('uavr_native');
const _remoteId = EventChannel('uavr_native/remote_id');
const _orientation = EventChannel('uavr_native/orientation');

bool get isSupported => Platform.isAndroid;

Future<RemoteIdCapabilities> remoteIdCapabilities() async {
  if (!isSupported) return RemoteIdCapabilities.none;
  final m = await _method.invokeMapMethod<Object?, Object?>('remoteIdCapabilities');
  return m == null ? RemoteIdCapabilities.none : RemoteIdCapabilities.fromMap(m);
}

Stream<RemoteIdFrame> remoteIdFrames() {
  if (!isSupported) return const Stream.empty();
  return _remoteId.receiveBroadcastStream().map((e) {
    final m = e as Map<Object?, Object?>;
    return RemoteIdFrame(
      transport: m['transport'] as String,
      sourceAddress: m['address'] as String,
      rssi: m['rssi'] as int?,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(m['ts'] as int, isUtc: true),
      payload: m['payload'] as Uint8List,
    );
  });
}

Stream<OrientationSample> orientation(Duration interval) {
  if (!isSupported) return const Stream.empty();
  return _orientation.receiveBroadcastStream({'intervalMs': interval.inMilliseconds}).map((e) {
    final m = e as Map<Object?, Object?>;
    return OrientationSample(
      azimuthDeg: (m['azimuth'] as num).toDouble(),
      magneticAzimuthDeg: (m['magneticAzimuth'] as num).toDouble(),
      elevationDeg: (m['elevation'] as num).toDouble(),
      declinationDeg: (m['declination'] as num).toDouble(),
      accuracy: m['accuracy'] as int,
      at: DateTime.fromMillisecondsSinceEpoch(m['ts'] as int, isUtc: true),
    );
  });
}

Future<void> setLocation(double lat, double lon, double altM) async {
  if (!isSupported) return;
  await _method.invokeMethod<void>('setLocation', {'lat': lat, 'lon': lon, 'alt': altM});
}

Future<String?> integrityToken(String requestHash, int cloudProjectNumber) async {
  if (!isSupported) return null;
  try {
    return await _method.invokeMethod<String>('integrityToken', {
      'requestHash': requestHash,
      'cloudProjectNumber': cloudProjectNumber,
    });
  } on PlatformException {
    return null;
  } on MissingPluginException {
    return null;
  }
}
