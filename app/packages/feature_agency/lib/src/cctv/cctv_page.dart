import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/l10n.dart';
import '../common/labels.dart';
import '../livemap/live_map_page.dart' show videoFeedsProvider;
import '../maritime/maritime_page.dart' show fmtTime;

final videoFeedTracksProvider = FutureProvider.autoDispose.family<VideoFeedTracks, String>(
  (ref, feedId) => ref.watch(staffApiProvider).videoFeedTracks(feedId),
  retry: (_, _) => null,
);

const _trackColor = Color(0xFFF28C28);
const _zoneColor = Color(0xFFD64545);

/// "Yilan Coast (0AXD)": place name and the camera's short id.
String cameraLabel(VideoFeedInfo f) => '${f.name} (${f.id})';

String behaviourLabel(AgencyL10n l, String code) => switch (code) {
  'loiter' => l.cctvBehLoiter,
  'approaching' => l.cctvBehApproaching,
  'fast' => l.cctvBehFast,
  'zone' => l.cctvBehZone,
  _ => code,
};

/// "0AXD-T3" -> "T3": the camera is already chosen above.
String _short(String key) => key.contains('-T') ? key.substring(key.lastIndexOf('-T') + 1) : key;

/// CCTV section: cameras, the craft each one followed (camera tracks), and the last frame of a track.
class CctvPage extends ConsumerStatefulWidget {
  const CctvPage({super.key});
  @override
  ConsumerState<CctvPage> createState() => _CctvPageState();
}

class _CctvPageState extends ConsumerState<CctvPage> {
  String? _feed, _track;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final t = Theme.of(context);
    final feeds = ref.watch(videoFeedsProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.cctvTitle, style: t.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(l.cctvSubtitle, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        ]),
      ),
      const Divider(height: 1),
      Expanded(
        child: switch (feeds) {
          AsyncData(:final value) when value.isEmpty => Center(child: Text(l.cctvNoCameras)),
          AsyncData(:final value) => _body(context, value),
          AsyncError(:final error) => ErrorView(error, onRetry: () => ref.invalidate(videoFeedsProvider)),
          _ => const LoadingView(),
        },
      ),
    ]);
  }

  Widget _body(BuildContext context, List<VideoFeedInfo> feeds) {
    final l = context.l;
    final feed = feeds.where((f) => f.id == _feed).firstOrNull ?? feeds.first;
    final cameras = ListView(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(l.cctvCameras, style: Theme.of(context).textTheme.labelLarge),
      ),
      for (final f in feeds)
        ListTile(
          key: Key('cctv-feed-${f.id}'),
          selected: f.id == feed.id,
          // Red while a case from this camera is still open.
          tileColor: f.openCases > 0 ? UavrColors.critical.withValues(alpha: 0.1) : null,
          selectedTileColor: f.openCases > 0 ? UavrColors.critical.withValues(alpha: 0.18) : null,
          iconColor: f.openCases > 0 ? UavrColors.critical : null,
          textColor: f.openCases > 0 ? UavrColors.critical : null,
          selectedColor: f.openCases > 0 ? UavrColors.critical : null,
          leading: Icon(f.openCases > 0 ? Icons.videocam : Icons.videocam_outlined,
              color: f.active || f.openCases > 0 ? null : UavrColors.redacted),
          title: Text(cameraLabel(f), style: f.openCases > 0 ? const TextStyle(fontWeight: FontWeight.w700) : null),
          subtitle: Text([
            if (f.openCases > 0) l.cctvOpenCases(f.openCases),
            if (f.owner != null) f.owner!,
            for (final d in f.domains) domainLabel(l, d),
            if (!f.active) l.cctvInactive,
            // last_sampled_at is the last attempt: only a frame when the camera did not report an error
            if (f.lastSampledAt != null && f.lastError == null) l.cctvLastSample(fmtTime(context, f.lastSampledAt)),
          ].join(' · ')),
          onTap: () => setState(() {
            _feed = f.id;
            _track = null;
          }),
        ),
    ]);
    final tracks = _FeedTracks(
      feed: feed,
      selected: _track,
      onSelect: (k) => setState(() => _track = k),
    );
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 900) {
        // Phones: the camera list becomes a dropdown so the tracks and the frame get the screen.
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: DropdownButton<String>(
              key: const Key('cctv-feed-select'),
              isExpanded: true,
              value: feed.id,
              underline: const SizedBox.shrink(),
              items: [
                for (final f in feeds)
                  DropdownMenuItem(
                    value: f.id,
                    child: Row(children: [
                      Icon(f.openCases > 0 ? Icons.videocam : Icons.videocam_outlined,
                          size: 20,
                          color: f.openCases > 0 ? UavrColors.critical : (f.active ? null : UavrColors.redacted)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f.openCases > 0 ? '${cameraLabel(f)} · ${l.cctvOpenCases(f.openCases)}' : cameraLabel(f),
                          overflow: TextOverflow.ellipsis,
                          style: f.openCases > 0
                              ? const TextStyle(color: UavrColors.critical, fontWeight: FontWeight.w700)
                              : null,
                        ),
                      ),
                    ]),
                  ),
              ],
              onChanged: (v) => setState(() {
                _feed = v;
                _track = null;
              }),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: tracks),
        ]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(width: 320, child: cameras),
        const VerticalDivider(width: 1),
        Expanded(child: tracks),
      ]);
    });
  }
}

class _FeedTracks extends ConsumerWidget {
  const _FeedTracks({required this.feed, required this.selected, required this.onSelect});
  final VideoFeedInfo feed;
  final String? selected;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final data = ref.watch(videoFeedTracksProvider(feed.id));
    return switch (data) {
      AsyncData(:final value) when value.tracks.isEmpty => Center(child: Text(l.cctvNoTracks)),
      AsyncData(:final value) => _list(context, value),
      AsyncError(:final error) => ErrorView(error, onRetry: () => ref.invalidate(videoFeedTracksProvider(feed.id))),
      _ => const LoadingView(),
    };
  }

  Widget _list(BuildContext context, VideoFeedTracks d) {
    final l = context.l;
    final t = Theme.of(context);
    // Tracks come newest first: open the newest one followed over several frames (single hits are often noise).
    final first = d.tracks.where((x) => x.hits >= 3).firstOrNull ?? d.tracks.first;
    final sel = d.tracks.where((x) => x.key == selected).firstOrNull ?? first;
    final list = ListView(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(l.cctvTracks, style: t.textTheme.labelLarge),
      ),
      for (final k in d.tracks)
        ListTile(
          key: Key('cctv-track-${k.key}'),
          selected: k.key == sel.key,
          leading: const CircleAvatar(backgroundColor: _trackColor, radius: 6),
          title: Text('${k.key} · ${craftTypeLabel(l, k.craftType)}'),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.cctvTrackFacts(k.hits, fmtTime(context, k.firstAt), fmtTime(context, k.lastAt))),
            if (k.behaviours.isNotEmpty || k.caseNumber != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(spacing: 6, runSpacing: 4, children: [
                  Pill(k.status == 'active' ? l.cctvTrackActive : l.cctvTrackLost,
                      color: k.status == 'active' ? UavrColors.low : UavrColors.redacted),
                  for (final b in k.behaviours)
                    Tooltip(
                      message: b.text,
                      child: Pill(behaviourLabel(l, b.code), color: b.code == 'zone' ? _zoneColor : _trackColor),
                    ),
                  if (k.caseSeverity != null) SeverityChip(k.caseSeverity!, compact: true),
                ]),
              ),
          ]),
          isThreeLine: true,
          onTap: () => onSelect(k.key),
        ),
    ]);
    return LayoutBuilder(builder: (context, c) {
      final detail = _TrackDetail(track: sel, zone: d.alertZone);
      if (c.maxWidth < 1000) {
        // Narrow: the tracks as a row of chips above the frame, one scrolling column.
        return ListView(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final k in d.tracks)
                ChoiceChip(
                  key: Key('cctv-chip-${k.key}'),
                  selected: k.key == sel.key,
                  showCheckmark: false,
                  avatar: CircleAvatar(
                    backgroundColor: k.caseSeverity != null ? UavrColors.severity(k.caseSeverity!) : _trackColor,
                    radius: 5,
                  ),
                  label: Text('${_short(k.key)} · ${craftTypeLabel(l, k.craftType)}'),
                  onSelected: (_) => onSelect(k.key),
                ),
            ]),
          ),
          detail,
        ]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(width: 380, child: list),
        const VerticalDivider(width: 1),
        Expanded(child: SingleChildScrollView(child: detail)),
      ]);
    });
  }
}

class _TrackDetail extends StatelessWidget {
  const _TrackDetail({required this.track, required this.zone});
  final VideoTrackInfo track;
  final List<({double x, double y})> zone;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('${track.key} · ${craftTypeLabel(l, track.craftType)}', style: t.textTheme.titleMedium),
          if (track.caseId != null)
            FilledButton.tonalIcon(
              key: const Key('cctv-open-case'),
              onPressed: () => context.go('/cases/${track.caseId}'),
              icon: const Icon(Icons.open_in_new),
              label: Text(l.cctvOpenCase(track.caseNumber ?? '')),
            ),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ColoredBox(
              color: Colors.black,
              child: Stack(fit: StackFit.expand, children: [
                if (track.lastFrameUrl != null)
                  Image.network(
                    track.lastFrameUrl!,
                    fit: BoxFit.fill,
                    errorBuilder: (_, _, _) => Center(
                      child: Text(l.cctvNoFrame, style: const TextStyle(color: Colors.white70)),
                    ),
                  )
                else
                  Center(child: Text(l.cctvNoFrame, style: const TextStyle(color: Colors.white70))),
                CustomPaint(painter: _TrackPainter(track, zone)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(l.cctvFrameLegend, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        Text(l.cctvTrackFacts(track.hits, fmtTime(context, track.firstAt), fmtTime(context, track.lastAt))),
        const SizedBox(height: 8),
        for (final b in track.behaviours)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Pill(behaviourLabel(l, b.code), color: b.code == 'zone' ? _zoneColor : _trackColor),
              const SizedBox(width: 8),
              Expanded(child: Text(b.text)),
            ]),
          ),
      ]),
    );
  }
}

/// Watch area, the path of the box centre and the latest box, drawn over the frame (coordinates 0..1).
class _TrackPainter extends CustomPainter {
  _TrackPainter(this.track, this.zone);
  final VideoTrackInfo track;
  final List<({double x, double y})> zone;

  @override
  void paint(Canvas canvas, Size size) {
    Offset at(double x, double y) => Offset(x * size.width, y * size.height);
    if (zone.length >= 3) {
      final p = Path()..addPolygon([for (final z in zone) at(z.x, z.y)], true);
      canvas.drawPath(p, Paint()..color = _zoneColor.withValues(alpha: 0.12));
      canvas.drawPath(
        p,
        Paint()
          ..color = _zoneColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    final pts = [for (final q in track.path) at(q.x, q.y)];
    if (pts.length > 1) {
      canvas.drawPoints(
        PointMode.polygon,
        pts,
        Paint()
          ..color = _trackColor
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
    for (final o in pts) {
      canvas.drawCircle(o, 5, Paint()..color = _trackColor);
    }
    final box = track.path.isEmpty ? null : track.path.last.box;
    if (box != null && box.length == 4) {
      canvas.drawRect(
        Rect.fromPoints(at(box[0], box[1]), at(box[2], box[3])),
        Paint()
          ..color = _trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(_TrackPainter old) => old.track != track || old.zone != zone;
}
