/// Pure-Dart decoder for ASTM F3411-22a / ASD-STAN prEN 4709-002 Remote ID
/// messages, plus per-drone aggregation.
///
/// Every message is 25 bytes, little-endian. Byte 0 is the header: message
/// type in the high nibble, protocol version in the low nibble.
library;

import 'dart:typed_data';

import 'models.dart';

/// Size of one ASTM F3411 message.
const int astmMessageSize = 25;

/// Maximum number of messages in a message pack.
const int astmMaxPackMessages = 9;

sealed class AstmMessage {
  final int protocolVersion;
  const AstmMessage(this.protocolVersion);
}

/// 0x0 Basic ID.
final class BasicIdMessage extends AstmMessage {
  /// Raw ID type, 0..15.
  final int idType;

  /// Raw UA type, 0..15.
  final int uaType;

  /// UAS ID, NUL padding removed. Empty if none was broadcast.
  final String uasId;

  const BasicIdMessage(
    super.protocolVersion, {
    required this.idType,
    required this.uaType,
    required this.uasId,
  });

  /// `'none' | 'serial' | 'caa_registration' | 'utm_assigned' | 'specific_session'`,
  /// or null for reserved values.
  String? get idTypeName => idType < _idTypeNames.length ? _idTypeNames[idType] : null;

  String get uaTypeName => _uaTypeNames[uaType];
}

/// 0x1 Location/Vector. Fields that were broadcast as "unknown" are null.
final class LocationMessage extends AstmMessage {
  /// 0 undeclared, 1 ground, 2 airborne, 3 emergency, 4 remote ID system failure.
  final int status;

  /// 0 height above takeoff, 1 height above ground level.
  final int heightType;
  final double? directionDeg;
  final double? speedMps;
  final double? verticalSpeedMps;
  final double? lat;
  final double? lon;
  final double? altBaroM;
  final double? altGeoM;
  final double? heightM;

  /// Raw accuracy enums (ASTM tables), 0 = unknown.
  final int horizontalAccuracy;
  final int verticalAccuracy;
  final int baroAccuracy;
  final int speedAccuracy;

  /// Tenths of a second since the start of the current UTC hour.
  final int? timestampTenths;

  /// Timestamp accuracy in seconds, null if unknown.
  final double? timestampAccuracyS;

  const LocationMessage(
    super.protocolVersion, {
    required this.status,
    required this.heightType,
    this.directionDeg,
    this.speedMps,
    this.verticalSpeedMps,
    this.lat,
    this.lon,
    this.altBaroM,
    this.altGeoM,
    this.heightM,
    this.horizontalAccuracy = 0,
    this.verticalAccuracy = 0,
    this.baroAccuracy = 0,
    this.speedAccuracy = 0,
    this.timestampTenths,
    this.timestampAccuracyS,
  });

  String get statusName => status < _statusNames.length ? _statusNames[status] : 'reserved';

  /// Seconds since the start of the current hour.
  double? get timestampSeconds => timestampTenths == null ? null : timestampTenths! / 10;
}

/// 0x2 Authentication. Only recorded, not decoded or verified.
final class AuthMessage extends AstmMessage {
  final int authType;
  final int pageNumber;
  const AuthMessage(super.protocolVersion, {required this.authType, required this.pageNumber});
}

/// 0x3 Self-ID (free-text operator description).
final class SelfIdMessage extends AstmMessage {
  final int descriptionType;
  final String text;
  const SelfIdMessage(super.protocolVersion, {required this.descriptionType, required this.text});
}

/// 0x4 System: operator location and operating area.
final class SystemMessage extends AstmMessage {
  /// 0 takeoff, 1 live GNSS, 2 fixed.
  final int operatorLocationType;

  /// 0 undeclared, 1 EU.
  final int classificationType;
  final double? operatorLat;
  final double? operatorLon;
  final int areaCount;
  final double areaRadiusM;
  final double? areaCeilingM;
  final double? areaFloorM;
  final int uaCategory;
  final int uaClass;
  final double? operatorAltGeoM;

  /// Null if the broadcast timestamp is 0.
  final DateTime? timestamp;

  const SystemMessage(
    super.protocolVersion, {
    required this.operatorLocationType,
    required this.classificationType,
    this.operatorLat,
    this.operatorLon,
    this.areaCount = 0,
    this.areaRadiusM = 0,
    this.areaCeilingM,
    this.areaFloorM,
    this.uaCategory = 0,
    this.uaClass = 0,
    this.operatorAltGeoM,
    this.timestamp,
  });
}

/// 0x5 Operator ID.
final class OperatorIdMessage extends AstmMessage {
  final int operatorIdType;
  final String operatorId;
  const OperatorIdMessage(
    super.protocolVersion, {
    required this.operatorIdType,
    required this.operatorId,
  });
}

const _idTypeNames = ['none', 'serial', 'caa_registration', 'utm_assigned', 'specific_session'];

const _uaTypeNames = [
  'none',
  'aeroplane',
  'helicopter_or_multirotor',
  'gyroplane',
  'hybrid_lift',
  'ornithopter',
  'glider',
  'kite',
  'free_balloon',
  'captive_balloon',
  'airship',
  'parachute',
  'rocket',
  'tethered_powered_aircraft',
  'ground_obstacle',
  'other',
];

const _statusNames = ['undeclared', 'ground', 'airborne', 'emergency', 'system_failure'];

/// Epoch of the System message timestamp.
final _systemEpoch = DateTime.utc(2019);

/// Decodes [bytes] as one message or a message pack (type 0xF).
///
/// Never throws: malformed or unknown parts are skipped, so the result may be
/// partial or empty.
List<AstmMessage> decodeAstm(Uint8List bytes) {
  if (bytes.length < astmMessageSize) {
    // A pack header alone is 3 bytes, but holds nothing usable without a message.
    return const [];
  }
  final data = ByteData.sublistView(bytes);
  if (bytes[0] >> 4 != 0xF) {
    final m = _decodeOne(data, 0);
    return m == null ? const [] : [m];
  }
  final size = bytes[1];
  final count = bytes[2];
  if (size != astmMessageSize || count > astmMaxPackMessages) return const [];
  final out = <AstmMessage>[];
  for (var i = 0; i < count; i++) {
    final off = 3 + i * astmMessageSize;
    if (off + astmMessageSize > bytes.length) break;
    final m = _decodeOne(data, off);
    if (m != null) out.add(m);
  }
  return out;
}

AstmMessage? _decodeOne(ByteData d, int o) {
  final header = d.getUint8(o);
  final type = header >> 4;
  final version = header & 0x0F;
  final b1 = d.getUint8(o + 1);
  switch (type) {
    case 0x0:
      return BasicIdMessage(
        version,
        idType: b1 >> 4,
        uaType: b1 & 0x0F,
        uasId: _ascii(d, o + 2, 20),
      );
    case 0x1:
      return _decodeLocation(d, o, version);
    case 0x2:
      return AuthMessage(version, authType: b1 >> 4, pageNumber: b1 & 0x0F);
    case 0x3:
      return SelfIdMessage(version, descriptionType: b1, text: _ascii(d, o + 2, 23));
    case 0x4:
      return _decodeSystem(d, o, version);
    case 0x5:
      return OperatorIdMessage(version, operatorIdType: b1, operatorId: _ascii(d, o + 2, 20));
    default:
      return null; // reserved, or a pack nested inside a pack
  }
}

LocationMessage _decodeLocation(ByteData d, int o, int version) {
  final flags = d.getUint8(o + 1);
  final ewSegment = (flags & 0x02) != 0;
  final speedMult = (flags & 0x01) != 0;

  // Track direction is split into a 0..179 byte plus an E/W bit adding 180.
  final dirRaw = d.getUint8(o + 2) + (ewSegment ? 180 : 0);
  final speedRaw = d.getUint8(o + 3);
  final vSpeedRaw = d.getInt8(o + 4);
  final tsRaw = d.getUint16(o + 21, Endian.little);
  final tsAcc = d.getUint8(o + 23) & 0x0F;

  return LocationMessage(
    version,
    status: flags >> 4,
    heightType: (flags >> 2) & 0x01,
    directionDeg: dirRaw >= 360 ? null : dirRaw.toDouble(), // 361 = unknown
    speedMps: speedRaw == 255
        ? null
        : speedMult
        ? speedRaw * 0.75 + 255 * 0.25
        : speedRaw * 0.25,
    verticalSpeedMps: vSpeedRaw == 126 ? null : vSpeedRaw * 0.5, // 63 m/s = unknown
    lat: _latLon(d, o + 5),
    lon: _latLon(d, o + 9),
    altBaroM: _alt(d, o + 13),
    altGeoM: _alt(d, o + 15),
    heightM: _alt(d, o + 17),
    verticalAccuracy: d.getUint8(o + 19) >> 4,
    horizontalAccuracy: d.getUint8(o + 19) & 0x0F,
    baroAccuracy: d.getUint8(o + 20) >> 4,
    speedAccuracy: d.getUint8(o + 20) & 0x0F,
    timestampTenths: tsRaw == 0xFFFF || tsRaw > 36000 ? null : tsRaw,
    timestampAccuracyS: tsAcc == 0 ? null : tsAcc * 0.1,
  );
}

SystemMessage _decodeSystem(ByteData d, int o, int version) {
  final flags = d.getUint8(o + 1);
  final catClass = d.getUint8(o + 17);
  final ts = d.getUint32(o + 20, Endian.little);
  return SystemMessage(
    version,
    operatorLocationType: flags & 0x03,
    classificationType: (flags >> 2) & 0x07,
    operatorLat: _latLon(d, o + 2),
    operatorLon: _latLon(d, o + 6),
    areaCount: d.getUint16(o + 10, Endian.little),
    areaRadiusM: d.getUint8(o + 12) * 10.0,
    areaCeilingM: _alt(d, o + 13),
    areaFloorM: _alt(d, o + 15),
    uaCategory: catClass >> 4,
    uaClass: catClass & 0x0F,
    operatorAltGeoM: _alt(d, o + 18),
    timestamp: ts == 0 ? null : _systemEpoch.add(Duration(seconds: ts)),
  );
}

/// int32 degrees * 1e7; 0 means unknown.
double? _latLon(ByteData d, int o) {
  final raw = d.getInt32(o, Endian.little);
  return raw == 0 ? null : raw / 1e7;
}

/// uint16 (value * 0.5) - 1000 m; raw 0 (-1000 m) means unknown.
double? _alt(ByteData d, int o) {
  final raw = d.getUint16(o, Endian.little);
  return raw == 0 ? null : raw * 0.5 - 1000;
}

/// ASCII field, cut at the first NUL, trimmed, non-printables dropped.
String _ascii(ByteData d, int o, int len) {
  final chars = <int>[];
  for (var i = 0; i < len; i++) {
    final c = d.getUint8(o + i);
    if (c == 0) break;
    if (c >= 0x20 && c < 0x7F) chars.add(c);
  }
  return String.fromCharCodes(chars).trim();
}

/// Everything known about one drone, merged from the frames of one source address.
class RemoteIdDrone {
  final String sourceAddress;
  final String transport;
  final DateTime lastSeen;
  final int? rssi;
  final String? uasId;
  final String? idType;
  final String? uaType;
  final double? lat;
  final double? lon;
  final double? altGeoM;
  final double? altBaroM;
  final double? heightM;
  final double? speedMps;
  final double? directionDeg;
  final double? operatorLat;
  final double? operatorLon;
  final String? operatorId;
  final String? selfIdText;

  /// `'undeclared' | 'ground' | 'airborne' | 'emergency' | 'system_failure' | 'reserved'`.
  final String? status;

  const RemoteIdDrone({
    required this.sourceAddress,
    required this.transport,
    required this.lastSeen,
    this.rssi,
    this.uasId,
    this.idType,
    this.uaType,
    this.lat,
    this.lon,
    this.altGeoM,
    this.altBaroM,
    this.heightM,
    this.speedMps,
    this.directionDeg,
    this.operatorLat,
    this.operatorLon,
    this.operatorId,
    this.selfIdText,
    this.status,
  });

  /// A drone built from a single frame.
  factory RemoteIdDrone.fromFrame(RemoteIdFrame f) => RemoteIdDrone(
    sourceAddress: f.sourceAddress,
    transport: f.transport,
    lastSeen: f.receivedAt.toUtc(),
  ).merge(f);

  /// Returns a copy updated with the messages in [f]. Fields absent from the
  /// frame keep their previous values; a Location message replaces all
  /// position/vector fields (unknown values become null).
  RemoteIdDrone merge(RemoteIdFrame f) {
    var uasId = this.uasId, idType = this.idType, uaType = this.uaType;
    var lat = this.lat, lon = this.lon, altGeoM = this.altGeoM;
    var altBaroM = this.altBaroM, heightM = this.heightM;
    var speedMps = this.speedMps, directionDeg = this.directionDeg;
    var operatorLat = this.operatorLat, operatorLon = this.operatorLon;
    var operatorId = this.operatorId, selfIdText = this.selfIdText, status = this.status;

    for (final m in decodeAstm(f.payload)) {
      switch (m) {
        case BasicIdMessage():
          // Drones may send two Basic IDs (e.g. serial + session ID); a serial
          // number is the most useful for registry lookups, so it wins.
          if (m.uasId.isEmpty) break;
          if (idType == 'serial' && m.idTypeName != 'serial') break;
          uasId = m.uasId;
          idType = m.idTypeName;
          uaType = m.uaTypeName;
        case LocationMessage():
          lat = m.lat;
          lon = m.lon;
          altGeoM = m.altGeoM;
          altBaroM = m.altBaroM;
          heightM = m.heightM;
          speedMps = m.speedMps;
          directionDeg = m.directionDeg;
          status = m.statusName;
        case SystemMessage():
          operatorLat = m.operatorLat;
          operatorLon = m.operatorLon;
        case OperatorIdMessage():
          if (m.operatorId.isNotEmpty) operatorId = m.operatorId;
        case SelfIdMessage():
          if (m.text.isNotEmpty) selfIdText = m.text;
        case AuthMessage():
          break;
      }
    }

    final at = f.receivedAt.toUtc();
    return RemoteIdDrone(
      sourceAddress: sourceAddress,
      transport: f.transport,
      lastSeen: at.isAfter(lastSeen) ? at : lastSeen,
      rssi: f.rssi ?? rssi,
      uasId: uasId,
      idType: idType,
      uaType: uaType,
      lat: lat,
      lon: lon,
      altGeoM: altGeoM,
      altBaroM: altBaroM,
      heightM: heightM,
      speedMps: speedMps,
      directionDeg: directionDeg,
      operatorLat: operatorLat,
      operatorLon: operatorLon,
      operatorId: operatorId,
      selfIdText: selfIdText,
      status: status,
    );
  }

  /// The informant-API `RemoteIdMessage` JSON object; null fields are omitted.
  Map<String, dynamic> toApiJson() {
    final json = <String, dynamic>{
      'transport': transport,
      'received_at': lastSeen.toUtc().toIso8601String(),
      'rssi': rssi,
      'uas_id': uasId,
      'id_type': idType,
      'ua_type': uaType,
      'lat': lat,
      'lon': lon,
      'alt_geo_m': altGeoM,
      'alt_baro_m': altBaroM,
      'height_m': heightM,
      'speed_mps': speedMps,
      'direction_deg': directionDeg,
      'operator_lat': operatorLat,
      'operator_lon': operatorLon,
      'operator_id': operatorId,
      'self_id_text': selfIdText,
    };
    json.removeWhere((_, v) => v == null);
    return json;
  }

  /// True if everything except [lastSeen] and [rssi] is equal.
  bool sameStateAs(RemoteIdDrone o) =>
      transport == o.transport &&
      uasId == o.uasId &&
      idType == o.idType &&
      uaType == o.uaType &&
      lat == o.lat &&
      lon == o.lon &&
      altGeoM == o.altGeoM &&
      altBaroM == o.altBaroM &&
      heightM == o.heightM &&
      speedMps == o.speedMps &&
      directionDeg == o.directionDeg &&
      operatorLat == o.operatorLat &&
      operatorLon == o.operatorLon &&
      operatorId == o.operatorId &&
      selfIdText == o.selfIdText &&
      status == o.status;

  @override
  String toString() =>
      'RemoteIdDrone($sourceAddress, $transport, ${uasId ?? '?'}, '
      '${lat?.toStringAsFixed(6)},${lon?.toStringAsFixed(6)})';
}

/// Keeps the current state of every drone in range, keyed by source address.
/// Drones not heard from for [ttl] are dropped.
class RemoteIdTracker {
  final Duration ttl;
  final DateTime Function() _now;
  final Map<String, RemoteIdDrone> _drones = {};

  RemoteIdTracker({this.ttl = const Duration(seconds: 30), DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  /// Merges [f] into its drone and returns the updated drone.
  RemoteIdDrone add(RemoteIdFrame f) {
    prune();
    final prev = _drones[f.sourceAddress];
    final next = prev == null ? RemoteIdDrone.fromFrame(f) : prev.merge(f);
    _drones[f.sourceAddress] = next;
    return next;
  }

  /// Removes drones whose last frame is older than [ttl].
  void prune() {
    final cutoff = _now().toUtc().subtract(ttl);
    _drones.removeWhere((_, d) => d.lastSeen.isBefore(cutoff));
  }

  /// Current drones (pruned first).
  Map<String, RemoteIdDrone> get drones {
    prune();
    return Map.unmodifiable(_drones);
  }
}
