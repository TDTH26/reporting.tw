import 'dart:math' as math;

import 'json.dart';

/// WGS84 position. Kept independent of map libraries so the API package stays pure Dart.
class LatLon {
  const LatLon(this.lat, this.lon);
  final double lat;
  final double lon;

  static LatLon? fromJson(Object? v) {
    final m = obj(v);
    if (m == null || m['lat'] == null || m['lon'] == null) return null;
    return LatLon(toDouble(m['lat'])!, toDouble(m['lon'])!);
  }

  Json toJson() => {'lat': lat, 'lon': lon};

  /// Great-circle distance in metres.
  double distanceTo(LatLon o) {
    const r = 6371008.8;
    final p1 = lat * math.pi / 180, p2 = o.lat * math.pi / 180;
    final dp = p2 - p1, dl = (o.lon - lon) * math.pi / 180;
    final a = math.pow(math.sin(dp / 2), 2) + math.cos(p1) * math.cos(p2) * math.pow(math.sin(dl / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  /// Point at [distanceM] along compass [bearingDeg] (equirectangular, fine for a few km).
  LatLon destination(double bearingDeg, double distanceM) {
    const r = 6371008.8;
    final b = bearingDeg * math.pi / 180;
    final dLat = distanceM * math.cos(b) / r;
    final dLon = distanceM * math.sin(b) / (r * math.cos(lat * math.pi / 180));
    return LatLon(lat + dLat * 180 / math.pi, lon + dLon * 180 / math.pi);
  }

  @override
  String toString() => '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';

  @override
  bool operator ==(Object other) => other is LatLon && other.lat == lat && other.lon == lon;

  @override
  int get hashCode => Object.hash(lat, lon);
}

/// GeoJSON helpers: the API sends geometries as GeoJSON (lon, lat order).
class GeoJson {
  static List<LatLon> line(Object? geom) {
    final g = obj(geom);
    if (g == null || g['type'] != 'LineString') return const [];
    return (g['coordinates'] as List).map((c) => LatLon(toDouble(c[1])!, toDouble(c[0])!)).toList();
  }

  /// Outer rings of a Polygon / MultiPolygon.
  static List<List<LatLon>> rings(Object? geom) {
    final g = obj(geom);
    if (g == null) return const [];
    List<LatLon> ring(List r) => r.map((c) => LatLon(toDouble(c[1])!, toDouble(c[0])!)).toList();
    switch (g['type']) {
      case 'Polygon':
        return [ring((g['coordinates'] as List).first as List)];
      case 'MultiPolygon':
        return (g['coordinates'] as List).map((p) => ring((p as List).first as List)).toList();
    }
    return const [];
  }

  static Json polygon(List<LatLon> ring) {
    final closed = [...ring, if (ring.isNotEmpty && ring.first != ring.last) ring.first];
    return {
      'type': 'Polygon',
      'coordinates': [
        [
          for (final p in closed) [p.lon, p.lat],
        ],
      ],
    };
  }
}

class Zone {
  Zone({
    required this.id,
    required this.code,
    required this.name,
    required this.nameZh,
    required this.zoneType,
    required this.rings,
    this.classification = 0,
    this.published = false,
    this.primaryDeskId,
    this.backupChain = const [],
    this.priority = 0,
    this.ackTimeouts = const {},
    this.domains = const ['aerial', 'surface', 'subsurface', 'shore'],
  });

  final int? id;
  final String code;
  final String name;
  final String nameZh;
  final String zoneType;
  final List<List<LatLon>> rings;
  final int classification;
  final bool published;
  final int? primaryDeskId;
  final List<int> backupChain;
  final int priority;
  final Map<String, int> ackTimeouts;
  final List<String> domains;

  static List<Zone> fromFeatureCollection(Json fc) => listOf(fc['features'], (f) {
    final p = obj(f['properties']) ?? const {};
    return Zone(
      id: toInt(p['id']),
      code: '${p['code']}',
      name: '${p['name'] ?? ''}',
      nameZh: '${p['name_zh'] ?? ''}',
      zoneType: '${p['zone_type']}',
      rings: GeoJson.rings(f['geometry']),
      classification: toInt(p['classification']) ?? 0,
      published: p['published'] == true,
      primaryDeskId: toInt(p['primary_desk_id']),
      backupChain: (p['backup_chain'] as List? ?? const []).map((e) => toInt(e)!).toList(),
      priority: toInt(p['priority']) ?? 0,
      ackTimeouts: (obj(p['ack_timeouts']) ?? const {}).map((k, v) => MapEntry(k, toInt(v) ?? 0)),
      domains: p['domains'] == null ? const ['aerial', 'surface', 'subsurface', 'shore'] : strings(p['domains']),
    );
  });

  Json toAdminJson() => {
    'code': code,
    'name': name,
    'name_zh': nameZh,
    'zone_type': zoneType,
    'classification': classification,
    'published': published,
    'priority': priority,
    'geometry': rings.length == 1
        ? GeoJson.polygon(rings.first)
        : {
            'type': 'MultiPolygon',
            'coordinates': [for (final r in rings) (GeoJson.polygon(r)['coordinates'] as List)],
          },
    'primary_desk_id': primaryDeskId,
    'backup_chain': backupChain,
    'ack_timeouts': ackTimeouts,
    'domains': domains,
  };
}

const zoneTypes = [
  'jurisdiction',
  'open',
  'yellow',
  'red',
  'airport',
  'military',
  'critical_infrastructure',
  'outlying_islands_strict',
  'residential',
  'territorial_sea',
  'harbor',
  'restricted_waters',
  'coastal_defense',
];
