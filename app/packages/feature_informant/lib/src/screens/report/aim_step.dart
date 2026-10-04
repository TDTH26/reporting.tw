import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_capture/uavr_capture.dart';
import 'package:uavr_native/uavr_native.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../../services/capture.dart';
import '../../services/sensors.dart';
import '../../widgets/common.dart';
import 'report_controller.dart';

/// Slot of the photo taken when the direction is locked.
const aimPhotoSlot = 'aim1';

/// Back-camera preview with a crosshair and a live bearing/elevation readout.
class AimStep extends ConsumerStatefulWidget {
  const AimStep({super.key});

  @override
  ConsumerState<AimStep> createState() => _AimStepState();
}

class _AimStepState extends ConsumerState<AimStep> {
  AimCamera? _camera;
  bool _cameraChecked = false;
  bool _takePhoto = true;
  bool _locking = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    ref.read(informantSensorsProvider).openBackCamera().then((cam) {
      if (_disposed) {
        cam?.dispose();
        return;
      }
      setState(() {
        _camera = cam;
        _cameraChecked = true;
      });
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _lock(OrientationSample sample) async {
    // The direction is taken at the instant of the tap; the photo follows.
    final lock = DirectionLock.fromSample(sample);
    final flow = ref.read(reportFlowProvider.notifier);
    final capture = ref.read(evidenceCaptureProvider);
    CapturedMedia? photo;
    final camera = _camera;
    if (_takePhoto && camera != null) {
      setState(() => _locking = true);
      try {
        photo = await capture.ingest(await camera.takePicture(), MediaKind.photo, aimPhotoSlot);
      } catch (_) {
        // The bearing is what matters most; carry on without the photo.
      }
    }
    if (!_disposed) flow.lockDirection(lock, photo: photo);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final sample = ref.watch(orientationProvider).value;
    final lock = ref.watch(reportFlowProvider.select((d) => d.lock));
    final camera = _camera;
    return Stack(fit: StackFit.expand, children: [
      ColoredBox(
        color: Colors.black,
        child: camera != null
            ? ClipRect(child: FittedBox(fit: BoxFit.cover, clipBehavior: Clip.hardEdge, child: SizedBox(width: 1080, height: 1920, child: camera.preview())))
            : Center(
                child: _cameraChecked
                    ? Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.no_photography_outlined, color: Colors.white54, size: 40),
                        const SizedBox(height: 8),
                        Text(l.aimNoCamera, style: const TextStyle(color: Colors.white70)),
                      ])
                    : const CircularProgressIndicator(color: Colors.white54),
              ),
      ),
      const Center(child: ExcludeSemantics(child: _Crosshair())),
      Positioned(top: 12, left: 12, right: 12, child: _Readout(sample: sample, lock: lock)),
      Positioned(
        left: 12,
        right: 12,
        bottom: 12,
        child: _AimControls(
          canLock: sample != null && !_locking,
          locking: _locking,
          hasCamera: camera != null,
          takePhoto: _takePhoto,
          onTakePhoto: (v) => setState(() => _takePhoto = v),
          onLock: sample == null ? null : () => _lock(sample),
          onSkip: ref.read(reportFlowProvider.notifier).skipAiming,
        ),
      ),
    ]);
  }
}

class _Crosshair extends StatelessWidget {
  const _Crosshair();

  @override
  Widget build(BuildContext context) => Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 40),
      );
}

class _Readout extends StatelessWidget {
  const _Readout({required this.sample, required this.lock});
  final OrientationSample? sample;
  final DirectionLock? lock;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final s = sample;
    final style = Theme.of(context).textTheme;
    return Card(
      color: Colors.black.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (s == null)
              Text(l.aimNoCompass)
            else
              Semantics(
                liveRegion: true,
                child: Row(children: [
                  Expanded(child: _Value(l.aimBearing, '${s.azimuthDeg.round() % 360}°', style)),
                  Expanded(child: _Value(l.aimElevation, '${s.elevationDeg.round()}°', style)),
                ]),
              ),
            if (s != null && s.accuracy < 2) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.screen_rotation_alt, color: UavrColors.zoneYellow, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(l.aimCalibrate)),
              ]),
            ],
            if (lock != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.lock, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(l.aimLocked(lock!.bearingDeg.round(), lock!.elevationDeg.round()))),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.label, this.value, this.style);
  final String label;
  final String value;
  final TextTheme style;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: style.labelMedium?.copyWith(color: Colors.white70)),
        Text(value,
            style: style.headlineMedium?.copyWith(
                color: Colors.white, fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()])),
      ]);
}

class _AimControls extends StatelessWidget {
  const _AimControls({
    required this.canLock,
    required this.locking,
    required this.hasCamera,
    required this.takePhoto,
    required this.onTakePhoto,
    required this.onLock,
    required this.onSkip,
  });

  final bool canLock;
  final bool locking;
  final bool hasCamera;
  final bool takePhoto;
  final ValueChanged<bool> onTakePhoto;
  final VoidCallback? onLock;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Card(
      color: Colors.black.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.aimInstruction, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
          if (hasCamera)
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: takePhoto,
              onChanged: onTakePhoto,
              title: Text(l.aimTakePhoto, style: const TextStyle(color: Colors.white)),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: FilledButton.icon(
              onPressed: canLock ? onLock : null,
              icon: locking
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.gps_fixed),
              label: Text(l.aimLock),
            ),
          ),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(foregroundColor: Colors.white, minimumSize: const Size(48, 48)),
            child: Text(l.aimSkip),
          ),
        ]),
      ),
    );
  }
}
