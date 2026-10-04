import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_capture/uavr_capture.dart';
import 'package:uavr_native/uavr_native.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../geo_math.dart';
import '../services/observation_body.dart';
import '../services/outbox.dart';
import '../services/sensors.dart';
import '../widgets/common.dart';
import 'remote_id_scan_screen.dart' show submitResultText;

final mediaCaptureProvider = Provider<MediaCapture>((ref) {
  final m = MediaCapture();
  ref.onDispose(m.dispose);
  return m;
});

/// Officer evidence: photo / video / rotor audio, optional bearing lock, note.
class EvidenceScreen extends ConsumerStatefulWidget {
  const EvidenceScreen({super.key, required this.caseId, required this.caseNumber});
  final String caseId, caseNumber;

  @override
  ConsumerState<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends ConsumerState<EvidenceScreen> {
  final _media = <CapturedMedia>[];
  final _note = TextEditingController();
  bool _recording = false;
  bool _capturing = false;
  bool _submitting = false;
  bool _aiming = false;
  OrientationSample? _sample;
  OrientationSample? _locked;
  StreamSubscription<OrientationSample>? _orient;

  @override
  void dispose() {
    _orient?.cancel();
    _note.dispose();
    super.dispose();
  }

  void _setAiming(bool on) {
    _orient?.cancel();
    _orient = null;
    setState(() {
      _aiming = on;
      if (!on) _sample = null;
    });
    if (on) {
      _orient = ref.read(fieldSensorsProvider).orientation().listen((s) {
        if (mounted) setState(() => _sample = s);
      }, onError: (_) {});
    }
  }

  Future<void> _capture(Future<CapturedMedia?> Function(MediaCapture) f) async {
    setState(() => _capturing = true);
    try {
      final m = await f(ref.read(mediaCaptureProvider));
      if (m != null && mounted) setState(() => _media.add(m));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.f.captureFailed)));
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _toggleAudio() async {
    final cap = ref.read(mediaCaptureProvider);
    if (_recording) {
      await _capture((c) => c.stopAudio());
      setState(() => _recording = false);
      return;
    }
    if (!await cap.canRecordAudio) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.f.micPermission)));
      return;
    }
    await cap.startAudio();
    setState(() => _recording = true);
  }

  Future<void> _submit() async {
    final l = context.f;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _submitting = true);
    try {
      final fix = await ref.read(myFixProvider.notifier).current();
      if (fix == null) {
        messenger.showSnackBar(SnackBar(content: Text(l.noGpsFix)));
        return;
      }
      final body = fieldObservationBody(
        observer: fix,
        observedAt: _locked?.at ?? (_media.isEmpty ? null : _media.first.capturedAt),
        bearingDeg: _locked?.azimuthDeg,
        elevationDeg: _locked?.elevationDeg,
        media: _media,
        note: _note.text,
      );
      final r = await ref.read(outboxProvider.notifier).submit(OutboxEntry(
            caseId: widget.caseId,
            caseNumber: widget.caseNumber,
            kind: OutboxKind.evidence,
            body: body,
            media: List.of(_media),
            createdAt: DateTime.now().toUtc(),
          ));
      messenger.showSnackBar(SnackBar(content: Text(submitResultText(l, r))));
      if (r != SubmitResult.rejected && mounted && nav.canPop()) nav.pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.f;
    final t = Theme.of(context).textTheme;
    final fix = ref.watch(myFixProvider);
    final hasContent = _media.isNotEmpty || _locked != null || _note.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l.captureEvidence)),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        Text(l.evidenceFor(widget.caseNumber), style: t.bodySmall),
        const SizedBox(height: 8),
        Section(
          title: l.media,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(
                onPressed: _capturing || _recording ? null : () => _capture((c) => c.photo()),
                icon: const Icon(Icons.photo_camera),
                label: Text(l.photo),
              ),
              OutlinedButton.icon(
                onPressed: _capturing || _recording ? null : () => _capture((c) => c.video()),
                icon: const Icon(Icons.videocam),
                label: Text(l.video),
              ),
              OutlinedButton.icon(
                onPressed: _capturing ? null : _toggleAudio,
                icon: Icon(_recording ? Icons.stop_circle : Icons.mic, color: _recording ? UavrColors.critical : null),
                label: Text(_recording ? l.stopAudio : l.audio),
              ),
            ]),
            for (final m in _media)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(switch (m.kind) {
                  MediaKind.photo => Icons.image,
                  MediaKind.video => Icons.movie,
                  MediaKind.audio => Icons.graphic_eq,
                }),
                title: Text('${m.slot} · ${(m.sizeBytes / 1024).round()} KB'),
                subtitle: Text('SHA-256 ${m.sha256.substring(0, 16)}…', style: const TextStyle(fontFamily: 'monospace')),
                trailing: IconButton(
                  tooltip: l.remove,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _media.remove(m)),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        Section(
          title: l.bearing,
          trailing: Switch(value: _aiming, onChanged: _setAiming),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (!_aiming && _locked == null) Text(l.bearingHint),
            if (_aiming) ...[
              const Center(child: Icon(Icons.gps_fixed, size: 72, color: UavrColors.critical)),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _sample == null
                      ? l.waitingForCompass
                      : '${formatBearing(_sample!.azimuthDeg)} ${compassLabel(l, _sample!.azimuthDeg)}',
                  style: t.displaySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (_sample != null)
                Center(child: Text(l.elevation(_sample!.elevationDeg.round()), style: t.titleMedium)),
              if (_sample != null && _sample!.accuracy < 2)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(l.compassLowAccuracy,
                      textAlign: TextAlign.center, style: const TextStyle(color: UavrColors.medium)),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _sample == null ? null : () => setState(() => _locked = _sample),
                icon: const Icon(Icons.lock),
                label: Text(l.lockBearing),
              ),
            ],
            if (_locked != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock, color: UavrColors.brand),
                title: Text(l.lockedBearing(
                    '${formatBearing(_locked!.azimuthDeg)} ${compassLabel(l, _locked!.azimuthDeg)}',
                    _locked!.elevationDeg.round())),
                subtitle: Text(clockTime(_locked!.at)),
                trailing: IconButton(
                  tooltip: l.remove,
                  icon: const Icon(Icons.lock_open),
                  onPressed: () => setState(() => _locked = null),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        Section(
          title: l.note,
          child: TextField(
            controller: _note,
            minLines: 2,
            maxLines: 6,
            maxLength: 4000,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: l.evidenceNoteHint),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Icon(fix == null ? Icons.gps_not_fixed : Icons.gps_fixed, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              fix == null
                  ? l.waitingForGps
                  : '${fix.position}${fix.accuracyM == null ? '' : ' · ${l.gpsAccuracy(fix.accuracyM!.round())}'}',
              style: t.bodySmall,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _submitting || _recording || !hasContent ? null : _submit,
          icon: _submitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send),
          label: Text(l.submitEvidence),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}
