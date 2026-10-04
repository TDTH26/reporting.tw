import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';

import '../../services/capture.dart';
import '../../widgets/common.dart';
import 'aim_step.dart';
import 'report_controller.dart';

/// Optional photos, video and rotor sound. Speed beats perfect evidence.
class EvidenceStep extends ConsumerStatefulWidget {
  const EvidenceStep({super.key});

  @override
  ConsumerState<EvidenceStep> createState() => _EvidenceStepState();
}

class _EvidenceStepState extends ConsumerState<EvidenceStep> {
  bool _busy = false;

  Future<void> _capture(MediaKind kind) async {
    final capture = ref.read(evidenceCaptureProvider);
    final flow = ref.read(reportFlowProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.l.evidenceCaptureFailed;
    setState(() => _busy = true);
    try {
      final m = await captureMedia(context, capture, kind);
      if (m != null && mounted) flow.addMedia(m);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final media = ref.watch(reportFlowProvider.select((d) => d.media));
    final flow = ref.read(reportFlowProvider.notifier);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(l.evidenceTitle, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      IconLine(Icons.bolt, l.evidenceSpeedNote),
      const SizedBox(height: 12),
      CaptureButtons(kinds: MediaKind.values, onCapture: _capture, enabled: !_busy),
      const SizedBox(height: 16),
      if (media.isEmpty)
        Text(l.evidenceNone, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
      else
        for (final m in media)
          MediaTile(
            m,
            label: m.slot == aimPhotoSlot ? l.evidenceAimPhoto : null,
            onRemove: () => flow.removeMedia(m.slot),
          ),
    ]);
  }
}
