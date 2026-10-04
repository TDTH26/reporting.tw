import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_maps/uavr_maps.dart';

import 'l10n.dart';
import 'providers.dart';

/// Zooms [map] by [by] steps around the current centre; ignored when no map is rendered (maps disabled in tests).
void zoomMap(MapController map, double by) {
  try {
    final cam = map.camera;
    map.move(cam.center, (cam.zoom + by).clamp(cam.minZoom ?? 3, cam.maxZoom ?? 18));
  } catch (_) {}
}

/// Small floating zoom in / zoom out buttons for a map overlay.
class MapZoomButtons extends StatelessWidget {
  const MapZoomButtons(this.map, {super.key, required this.heroTag});
  final MapController map;
  final String heroTag;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        FloatingActionButton.small(
          key: Key('$heroTag-zoom-in'),
          heroTag: '$heroTag-zoom-in',
          tooltip: context.l.zoomIn,
          onPressed: () => zoomMap(map, 1),
          child: const Icon(Icons.zoom_in),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          key: Key('$heroTag-zoom-out'),
          heroTag: '$heroTag-zoom-out',
          tooltip: context.l.zoomOut,
          onPressed: () => zoomMap(map, -1),
          child: const Icon(Icons.zoom_out),
        ),
      ]);
}

/// UavrMap with the configured tile server; a plain placeholder when maps are disabled (tests).
class ConsoleMap extends ConsumerWidget {
  const ConsoleMap({
    super.key,
    this.children = const [],
    this.controller,
    this.initialCenter,
    this.initialZoom = 7.2,
    this.onTap,
  });

  final List<Widget> children;
  final MapController? controller;
  final LatLng? initialCenter;
  final double initialZoom;
  final void Function(LatLng)? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(consoleMapsEnabledProvider)) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.map_outlined)),
      );
    }
    final cfg = ref.watch(configProvider);
    return UavrMap(
      tileUrlTemplate: cfg.tileUrlTemplate,
      attribution: cfg.tileAttribution,
      controller: controller,
      initialCenter: initialCenter,
      initialZoom: initialZoom,
      onTap: onTap,
      children: children,
    );
  }
}
