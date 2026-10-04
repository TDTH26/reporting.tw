import 'dart:typed_data';

/// Which Remote ID transports this device can receive.
class RemoteIdCapabilities {
  /// Bluetooth 4 legacy advertising.
  final bool bluetoothLegacy;

  /// Bluetooth 5 Coded PHY (long range) with extended advertising.
  final bool bluetoothLongRange;

  /// Vendor IEs readable from Wi-Fi scan results (Android 11 / API 30+).
  final bool wifiBeacon;

  /// Wi-Fi Aware (NAN) available.
  final bool wifiNan;

  const RemoteIdCapabilities({
    this.bluetoothLegacy = false,
    this.bluetoothLongRange = false,
    this.wifiBeacon = false,
    this.wifiNan = false,
  });

  static const RemoteIdCapabilities none = RemoteIdCapabilities();

  factory RemoteIdCapabilities.fromMap(Map<Object?, Object?> m) => RemoteIdCapabilities(
    bluetoothLegacy: m['bluetoothLegacy'] == true,
    bluetoothLongRange: m['bluetoothLongRange'] == true,
    wifiBeacon: m['wifiBeacon'] == true,
    wifiNan: m['wifiNan'] == true,
  );

  bool get any => bluetoothLegacy || bluetoothLongRange || wifiBeacon || wifiNan;

  /// Subset of `['bt4', 'bt5', 'wifi_beacon', 'wifi_nan']`.
  List<String> get transports => [
    if (bluetoothLegacy) 'bt4',
    if (bluetoothLongRange) 'bt5',
    if (wifiBeacon) 'wifi_beacon',
    if (wifiNan) 'wifi_nan',
  ];

  @override
  String toString() => 'RemoteIdCapabilities(${transports.join(', ')})';
}

/// One raw Remote ID frame, with the transport framing already stripped.
class RemoteIdFrame {
  /// `'bt4' | 'bt5' | 'wifi_beacon' | 'wifi_nan'`.
  final String transport;

  /// BLE MAC, Wi-Fi BSSID or NAN peer handle; groups frames per drone.
  final String sourceAddress;
  final int? rssi;

  /// UTC.
  final DateTime receivedAt;

  /// ASTM F3411 bytes: a single 25-byte message or a message pack (type 0xF).
  final Uint8List payload;

  const RemoteIdFrame({
    required this.transport,
    required this.sourceAddress,
    required this.rssi,
    required this.receivedAt,
    required this.payload,
  });

  @override
  String toString() => 'RemoteIdFrame($transport, $sourceAddress, rssi=$rssi, ${payload.length} B)';
}

/// Pointing direction of the back camera.
class OrientationSample {
  /// True-north bearing of the back camera axis, 0..360 clockwise.
  final double azimuthDeg;

  /// Same as [azimuthDeg] but relative to magnetic north.
  final double magneticAzimuthDeg;

  /// Angle of the camera axis above the horizon, -90..90.
  final double elevationDeg;

  /// Magnetic declination applied (0 if the location is unknown).
  final double declinationDeg;

  /// 0 unreliable, 1 low, 2 medium, 3 high (Android SENSOR_STATUS_*).
  /// On web: 1 if absolute orientation is available, else 0.
  final int accuracy;
  final DateTime at;

  const OrientationSample({
    required this.azimuthDeg,
    required this.magneticAzimuthDeg,
    required this.elevationDeg,
    required this.declinationDeg,
    required this.accuracy,
    required this.at,
  });

  @override
  String toString() =>
      'OrientationSample(az=${azimuthDeg.toStringAsFixed(1)}, '
      'el=${elevationDeg.toStringAsFixed(1)}, acc=$accuracy)';
}
