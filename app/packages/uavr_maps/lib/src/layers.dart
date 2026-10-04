import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_ui/uavr_ui.dart';

LatLng ll(LatLon p) => LatLng(p.lat, p.lon);
LatLon lo(LatLng p) => LatLon(p.latitude, p.longitude);

/// Taiwan incl. Penghu, Kinmen and Matsu.
final taiwanBounds = LatLngBounds(const LatLng(21.8, 118.1), const LatLng(26.45, 122.1));
const taiwanCenter = LatLng(23.75, 120.95);

/// Base map: tiles + attribution + caller layers on top.
class UavrMap extends StatelessWidget {
  const UavrMap({
    super.key,
    required this.tileUrlTemplate,
    required this.attribution,
    this.children = const [],
    this.controller,
    this.initialCenter,
    this.initialZoom = 7.2,
    this.onTap,
    this.interactive = true,
  });

  final String tileUrlTemplate;
  final String attribution;
  final List<Widget> children;
  final MapController? controller;
  final LatLng? initialCenter;
  final double initialZoom;
  final void Function(LatLng)? onTap;
  final bool interactive;

  @override
  Widget build(BuildContext context) => FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: initialCenter ?? taiwanCenter,
          initialZoom: initialZoom,
          minZoom: 5,
          maxZoom: 19,
          onTap: onTap == null ? null : (_, p) => onTap!(p),
          interactionOptions: InteractionOptions(
            flags: interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(urlTemplate: tileUrlTemplate, userAgentPackageName: 'tw.reporting', maxNativeZoom: 19),
          ...children,
          RichAttributionWidget(
            showFlutterMapAttribution: false,
            attributions: [TextSourceAttribution(attribution)],
          ),
        ],
      );
}

class ZonesLayer extends StatelessWidget {
  const ZonesLayer(this.zones, {super.key, this.highlightCodes = const {}});
  final List<Zone> zones;
  final Set<String> highlightCodes;

  @override
  Widget build(BuildContext context) => PolygonLayer(
        polygons: [
          for (final z in zones)
            if (z.zoneType != 'jurisdiction')
              for (final ring in z.rings)
                Polygon(
                  points: ring.map(ll).toList(),
                  color: UavrColors.zone(z.zoneType).withValues(alpha: highlightCodes.contains(z.code) ? 0.35 : 0.15),
                  borderColor: UavrColors.zone(z.zoneType),
                  borderStrokeWidth: highlightCodes.contains(z.code) ? 2.5 : 1.2,
                ),
        ],
      );
}

/// Informant bearing lines: observer dot + dashed ray along the bearing.
class BearingLinesLayer extends StatelessWidget {
  const BearingLinesLayer(this.observations, {super.key, this.rayLengthM = 1500});
  final List<ObservationView> observations;
  final double rayLengthM;

  @override
  Widget build(BuildContext context) {
    final withBearing = observations.where((o) => o.observerPosition != null && o.bearingDeg != null).toList();
    final color = Theme.of(context).colorScheme.primary;
    return Stack(children: [
      PolylineLayer(polylines: [
        for (final o in withBearing)
          Polyline(
            points: [ll(o.observerPosition!), ll(o.observerPosition!.destination(o.bearingDeg!, rayLengthM))],
            color: color.withValues(alpha: 0.35 + 0.5 * o.confidence.clamp(0, 1) * (1 - o.spamScore)),
            strokeWidth: 2,
            pattern: StrokePattern.dashed(segments: const [8, 6]),
          ),
      ]),
      CircleLayer(circles: [
        for (final o in observations)
          if (o.observerPosition != null && !o.isSensor)
            CircleMarker(point: ll(o.observerPosition!), radius: 5, color: color, borderColor: Colors.white, borderStrokeWidth: 1.5),
      ]),
    ]);
  }
}

class TrackLayer extends StatelessWidget {
  const TrackLayer(this.points, {super.key, this.color});
  final List<LatLon> points;
  final Color? color;

  @override
  Widget build(BuildContext context) => PolylineLayer(polylines: [
        if (points.length >= 2)
          Polyline(points: points.map(ll).toList(), color: color ?? UavrColors.critical, strokeWidth: 3.5),
      ]);
}

/// Estimated drone position with its uncertainty circle.
class EstimateLayer extends StatelessWidget {
  const EstimateLayer({super.key, required this.position, this.errorM, this.severity = 1});
  final LatLon position;
  final double? errorM;
  final int severity;

  @override
  Widget build(BuildContext context) {
    final c = UavrColors.severity(severity);
    return Stack(children: [
      CircleLayer(circles: [
        if (errorM != null)
          CircleMarker(
            point: ll(position),
            radius: errorM!.clamp(10, 5000),
            useRadiusInMeter: true,
            color: c.withValues(alpha: 0.12),
            borderColor: c.withValues(alpha: 0.6),
            borderStrokeWidth: 1,
          ),
      ]),
      MarkerLayer(markers: [
        Marker(point: ll(position), width: 34, height: 34, child: DroneIcon(color: c)),
      ]),
    ]);
  }
}

class DroneIcon extends StatelessWidget {
  const DroneIcon({super.key, required this.color, this.size = 34, this.badge});
  final Color color;
  final double size;
  final String? badge;

  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
          ),
          child: Icon(Icons.flight, size: size * 0.55, color: Colors.white),
        ),
        if (badge != null)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
              child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
      ]);
}

/// Case markers for queues / live maps. Redacted cases are grey.
class CaseMarkersLayer extends StatelessWidget {
  const CaseMarkersLayer(this.cases, {super.key, this.onTap, this.selectedId});
  final List<CaseSummary> cases;
  final void Function(CaseSummary)? onTap;
  final String? selectedId;

  @override
  Widget build(BuildContext context) => MarkerLayer(markers: [
        for (final c in cases)
          if (c.position != null)
            Marker(
              point: ll(c.position!),
              width: c.id == selectedId ? 44 : 34,
              height: c.id == selectedId ? 44 : 34,
              child: GestureDetector(
                onTap: onTap == null ? null : () => onTap!(c),
                child: DroneIcon(
                  color: c.redacted ? UavrColors.redacted : UavrColors.severity(c.severity),
                  size: c.id == selectedId ? 44 : 34,
                  badge: c.observationCount > 1 ? '${c.observationCount}' : null,
                ),
              ),
            ),
      ]);
}

class AircraftLayer extends StatelessWidget {
  const AircraftLayer(this.aircraft, {super.key});
  final List<Aircraft> aircraft;

  @override
  Widget build(BuildContext context) => MarkerLayer(markers: [
        for (final a in aircraft)
          Marker(
            point: ll(a.position),
            width: 70,
            height: 40,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Transform.rotate(
                angle: (a.trackDeg ?? 0) * math.pi / 180,
                child: const Icon(Icons.airplanemode_active, color: Color(0xFF0D47A1), size: 22),
              ),
              Text(a.callsign ?? a.icao24,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF0D47A1))),
            ]),
          ),
      ]);
}

/// Simple point markers (operator position, field officers, CCTV, the informant).
class PointsLayer extends StatelessWidget {
  const PointsLayer(this.points, {super.key, required this.icon, required this.color, this.labels});
  final List<LatLon> points;
  final IconData icon;
  final Color color;
  final List<String>? labels;

  @override
  Widget build(BuildContext context) => MarkerLayer(markers: [
        for (var i = 0; i < points.length; i++)
          Marker(
            point: ll(points[i]),
            width: 80,
            height: 46,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: color, size: 26, shadows: const [Shadow(blurRadius: 3, color: Colors.white)]),
              if (labels != null && i < labels!.length)
                Text(labels![i],
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
            ]),
          ),
      ]);
}

/// Hotspot grid cells drawn as circles sized and shaded by count.
class HeatmapLayer extends StatelessWidget {
  const HeatmapLayer(this.cells, {super.key, this.cellDeg = 0.01});
  final List<HotspotCell> cells;
  final double cellDeg;

  @override
  Widget build(BuildContext context) {
    final max = cells.fold<int>(1, (m, c) => math.max(m, c.count));
    final radiusM = cellDeg * 111320 * 0.75;
    return CircleLayer(circles: [
      for (final c in cells)
        CircleMarker(
          point: LatLng(c.lat, c.lon),
          radius: radiusM * (0.5 + 0.5 * math.sqrt(c.count / max)),
          useRadiusInMeter: true,
          color: Color.lerp(const Color(0xFFFFC107), UavrColors.critical, c.count / max)!
              .withValues(alpha: 0.25 + 0.5 * (c.count / max)),
          borderStrokeWidth: 0,
        ),
    ]);
  }
}

/// Fit a map controller to points (with padding), falling back to Taiwan.
void fitTo(MapController c, List<LatLon> pts, {double maxZoom = 16}) {
  if (pts.isEmpty) {
    c.fitCamera(CameraFit.bounds(bounds: taiwanBounds, padding: const EdgeInsets.all(24)));
    return;
  }
  if (pts.length == 1) {
    c.move(ll(pts.first), math.min(maxZoom, 15));
    return;
  }
  c.fitCamera(CameraFit.coordinates(
    coordinates: pts.map(ll).toList(),
    padding: const EdgeInsets.all(48),
    maxZoom: maxZoom,
  ));
}


/// AIS vessels (blue, identified) and non-cooperative MDA tracks (orange; fixed sites as squares).
class VesselsLayer extends StatelessWidget {
  const VesselsLayer(this.vessels, {super.key, this.onTap});
  final List<VesselContact> vessels;
  final void Function(VesselContact)? onTap;

  @override
  Widget build(BuildContext context) => MarkerLayer(markers: [
        for (final v in vessels)
          Marker(
            point: ll(v.position),
            width: 18,
            height: 18,
            child: GestureDetector(
              onTap: onTap == null ? null : () => onTap!(v),
              child: Tooltip(
                message: v.isAis ? '${v.label} (AIS ${v.mmsi})' : '${v.trackId} · ${v.role ?? ''}',
                child: v.isAis
                    ? Transform.rotate(
                        angle: (v.cogDeg ?? 0) * math.pi / 180,
                        child: const Icon(Icons.navigation, size: 16, color: Color(0xFF1565C0)),
                      )
                    : Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: (v.role == 'fixed_site' ? const Color(0xFF6D4C41) : const Color(0xFFEF6C00))
                              .withValues(alpha: v.roleConfidence == 'low' ? 0.45 : 0.9),
                          shape: v.role == 'fixed_site' ? BoxShape.rectangle : BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
              ),
            ),
          ),
      ]);
}

/// Agency cameras with their viewing direction.
class CamerasLayer extends StatelessWidget {
  const CamerasLayer(this.feeds, {super.key, this.onTap});
  final List<VideoFeedInfo> feeds;
  final void Function(VideoFeedInfo)? onTap;

  @override
  Widget build(BuildContext context) => MarkerLayer(markers: [
        for (final f in feeds)
          Marker(
            point: ll(f.position),
            width: 30,
            height: 30,
            child: GestureDetector(
              onTap: onTap == null ? null : () => onTap!(f),
              child: Tooltip(
                message: f.name,
                child: Transform.rotate(
                  angle: (f.bearingDeg ?? 0) * math.pi / 180,
                  child: Icon(Icons.videocam, size: 22, color: f.active ? const Color(0xFF00695C) : Colors.grey),
                ),
              ),
            ),
          ),
      ]);
}
