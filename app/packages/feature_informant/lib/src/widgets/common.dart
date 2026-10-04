import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_capture/uavr_capture.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../l10n/informant_localizations.dart';
import '../services/capture.dart';

extension InformantL10nX on BuildContext {
  InformantL10n get l => InformantL10n.of(this);
}

String transportLabel(InformantL10n l, String t) => switch (t) {
      'bt4' => l.transportBt4,
      'bt5' => l.transportBt5,
      'wifi_beacon' => l.transportWifiBeacon,
      'wifi_nan' => l.transportWifiNan,
      _ => t,
    };

String mediaKindLabel(InformantL10n l, MediaKind k) => switch (k) {
      MediaKind.photo => l.mediaPhoto,
      MediaKind.video => l.mediaVideo,
      MediaKind.audio => l.mediaAudio,
    };

IconData mediaKindIcon(MediaKind k) => switch (k) {
      MediaKind.photo => Icons.photo_camera_outlined,
      MediaKind.video => Icons.videocam_outlined,
      MediaKind.audio => Icons.graphic_eq,
    };

String formatBytes(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Colour for a informant status pill.
Color statusColor(String status) => status == 'completed' ? UavrColors.low : UavrColors.brand;

/// One captured file with a remove button.
class MediaTile extends StatelessWidget {
  const MediaTile(this.media, {super.key, this.label, this.onRemove});
  final CapturedMedia media;
  final String? label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(mediaKindIcon(media.kind)),
        title: Text(label ?? mediaKindLabel(context.l, media.kind)),
        subtitle: Text('${clockTime(media.capturedAt)} · ${formatBytes(media.sizeBytes)}'),
        trailing: onRemove == null
            ? null
            : IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: context.l.evidenceRemove,
                onPressed: onRemove,
              ),
      );
}

/// Large add-evidence buttons for the requested kinds.
class CaptureButtons extends StatelessWidget {
  const CaptureButtons({super.key, required this.kinds, required this.onCapture, this.enabled = true});
  final List<MediaKind> kinds;
  final void Function(MediaKind) onCapture;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (final k in kinds)
          OutlinedButton.icon(
            onPressed: enabled ? () => onCapture(k) : null,
            icon: Icon(mediaKindIcon(k)),
            label: Text(k == MediaKind.audio ? context.l.evidenceRecordSound : mediaKindLabel(context.l, k)),
          ),
      ]);
}

/// Captures one file of [kind]: system camera for photo/video, the recorder sheet for sound.
Future<CapturedMedia?> captureMedia(BuildContext context, EvidenceCapture capture, MediaKind kind) =>
    switch (kind) {
      MediaKind.photo => capture.photo(),
      MediaKind.video => capture.video(),
      MediaKind.audio => recordSound(context, capture),
    };

/// Records rotor sound with a live level meter. Returns the file, or null if cancelled.
Future<CapturedMedia?> recordSound(BuildContext context, EvidenceCapture capture) async {
  if (!await capture.startAudio()) return null;
  if (!context.mounted) return null;
  return showModalBottomSheet<CapturedMedia>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => _RecorderSheet(capture),
  );
}

class _RecorderSheet extends StatefulWidget {
  const _RecorderSheet(this.capture);
  final EvidenceCapture capture;

  @override
  State<_RecorderSheet> createState() => _RecorderSheetState();
}

class _RecorderSheetState extends State<_RecorderSheet> {
  final _started = DateTime.now();
  late final Timer _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  late final Stream<double> _level = widget.capture.amplitude();
  bool _stopping = false;

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  Future<void> _stop() async {
    setState(() => _stopping = true);
    final media = await widget.capture.stopAudio();
    if (mounted) Navigator.of(context).pop(media);
  }

  @override
  Widget build(BuildContext context) {
    final seconds = DateTime.now().difference(_started).inSeconds;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(context.l.evidenceRecording(seconds), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          StreamBuilder<double>(
            stream: _level,
            builder: (context, snap) => Semantics(
              label: context.l.mediaAudio,
              child: LinearProgressIndicator(value: snap.data ?? 0, minHeight: 14, borderRadius: BorderRadius.circular(7)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _stopping ? null : _stop,
              icon: const Icon(Icons.stop),
              label: Text(context.l.evidenceStopRecording),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Language list with each language in its own script.
class LanguageList extends StatelessWidget {
  const LanguageList({super.key, required this.selected, required this.onSelected});
  final Locale selected;
  final ValueChanged<Locale> onSelected;

  @override
  Widget build(BuildContext context) => Column(children: [
        for (final locale in informantLocales)
          ListTile(
            title: Text(lookupUavrL10n(locale).languageSelfName),
            trailing: locale.languageCode == selected.languageCode ? const Icon(Icons.check) : null,
            selected: locale.languageCode == selected.languageCode,
            onTap: () => onSelected(locale),
          ),
      ]);
}

/// A short paragraph with a leading icon, used on onboarding and info cards.
class IconLine extends StatelessWidget {
  const IconLine(this.icon, this.text, {super.key, this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
        ]),
      );
}
