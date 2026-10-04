import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_maps/uavr_maps.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../../widgets/common.dart';

/// Fallback when GPS is unavailable (typical on desktop browsers): the informant taps their
/// position on the map.
Future<LatLon?> pickLocationOnMap(BuildContext context, {LatLon? initial}) => Navigator.of(context).push<LatLon>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => _MapPicker(initial)),
    );

class _MapPicker extends ConsumerStatefulWidget {
  const _MapPicker(this.initial);
  final LatLon? initial;

  @override
  ConsumerState<_MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends ConsumerState<_MapPicker> {
  late LatLon? _picked = widget.initial;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l.mapPickTitle)),
      body: UavrMap(
        tileUrlTemplate: config.tileUrlTemplate,
        attribution: config.tileAttribution,
        initialCenter: _picked == null ? null : ll(_picked!),
        initialZoom: _picked == null ? 7.2 : 16,
        onTap: (LatLng p) => setState(() => _picked = lo(p)),
        children: [
          if (_picked != null) PointsLayer([_picked!], icon: Icons.person_pin_circle, color: UavrColors.critical),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _picked == null ? null : () => Navigator.pop(context, _picked),
            child: Text(context.l.mapPickConfirm),
          ),
        ),
      ),
    );
  }
}
