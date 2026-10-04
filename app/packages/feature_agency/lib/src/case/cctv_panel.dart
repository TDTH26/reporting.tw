import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_ui/uavr_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common/l10n.dart';
import '../common/labels.dart';
import '../common/run_action.dart';

/// Nearby CCTV cameras; opening a stream is audited server-side.
class CctvPanel extends ConsumerStatefulWidget {
  const CctvPanel({super.key, required this.summary});
  final CaseSummary summary;

  @override
  ConsumerState<CctvPanel> createState() => _CctvPanelState();
}

class _CctvPanelState extends ConsumerState<CctvPanel> {
  List<CctvCamera>? _cams;
  bool _busy = false;

  Future<void> _find() async {
    setState(() => _busy = true);
    final r = await runAction(context, () => ref.read(staffApiProvider).cctvNear(widget.summary.position!));
    if (mounted) {
      setState(() {
        _busy = false;
        _cams = r ?? _cams;
      });
    }
  }

  Future<void> _open(CctvCamera cam) async {
    final l = context.l;
    final r = await runAction(context, () => ref.read(staffApiProvider).cctvStream(cam.id, caseId: widget.summary.id));
    if (r == null || !mounted) return;
    final url = r.streamUrl ?? r.snapshotUrl;
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.noStream)));
      return;
    }
    await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final hasPos = widget.summary.position != null;
    return Section(
      title: l.panelCctv,
      trailing: OutlinedButton.icon(
        key: const Key('cctv-find'),
        onPressed: !hasPos || _busy ? null : _find,
        icon: const Icon(Icons.videocam_outlined, size: 18),
        label: Text(l.findCameras),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_cams == null) Text(l.cctvHint),
        if (_cams != null && _cams!.isEmpty) Text(l.noCameras),
        for (final cam in _cams ?? const <CctvCamera>[])
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.videocam),
            title: Text(cam.name),
            subtitle: Text([if (cam.owner != null) cam.owner!, if (cam.distanceM != null) distanceLabel(cam.distanceM!)].join(' · ')),
            trailing: TextButton.icon(
              onPressed: () => _open(cam),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(l.openStream),
            ),
          ),
        Text(l.cctvAudited, style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}
