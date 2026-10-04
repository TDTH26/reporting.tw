import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/l10n.dart';
import '../common/labels.dart';
import 'async_card.dart';
import 'dashboard_providers.dart';
import 'hotspot_card.dart';

// ---------------------------------------------------------------- time of day

class TimeOfDayCard extends ConsumerWidget {
  const TimeOfDayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    return AsyncSection<TimeOfDay>(
      title: l.timeOfDay,
      value: ref.watch(timeOfDayProvider),
      builder: (t) => TimeOfDayGrid(grid: t, dowLabels: dowLabels(l)),
    );
  }
}

/// 7×24 heat grid (rows Mon..Sun, columns 00..23 Taipei time). Single-hue sequential scale.
class TimeOfDayGrid extends StatefulWidget {
  const TimeOfDayGrid({super.key, required this.grid, required this.dowLabels});
  final TimeOfDay grid;
  final List<String> dowLabels;

  @override
  State<TimeOfDayGrid> createState() => _TimeOfDayGridState();
}

class _TimeOfDayGridState extends State<TimeOfDayGrid> {
  (int, int)? _hover;
  static const _labelW = 48.0, _headerH = 18.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      LayoutBuilder(builder: (context, c) {
        final cellW = (c.maxWidth - _labelW) / 24;
        final cellH = math.min(28.0, cellW * 0.8);
        final size = Size(c.maxWidth, _headerH + cellH * 7);
        return MouseRegion(
          onExit: (_) => setState(() => _hover = null),
          onHover: (e) {
            final x = e.localPosition.dx - _labelW, y = e.localPosition.dy - _headerH;
            if (x < 0 || y < 0) return setState(() => _hover = null);
            final h = (x / cellW).floor(), d = (y / cellH).floor();
            setState(() => _hover = (h >= 0 && h < 24 && d >= 0 && d < 7) ? (d, h) : null);
          },
          child: CustomPaint(
            size: size,
            painter: _GridPainter(
              grid: widget.grid,
              labels: widget.dowLabels,
              cellW: cellW,
              cellH: cellH,
              low: dark ? const Color(0xFF1E2A3D) : const Color(0xFFE8EEF8),
              high: dark ? const Color(0xFF8FB3F0) : UavrColors.brand,
              surface: scheme.surface,
              ink: scheme.onSurfaceVariant,
              hover: _hover,
            ),
          ),
        );
      }),
      const SizedBox(height: 6),
      Text(
        _hover == null
            ? context.l.timeOfDayHint(widget.grid.max)
            : '${widget.dowLabels[_hover!.$1]} ${_hover!.$2.toString().padLeft(2, '0')}:00 — ${context.l.incidentsN(widget.grid.grid[_hover!.$1][_hover!.$2])}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ]);
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.grid,
    required this.labels,
    required this.cellW,
    required this.cellH,
    required this.low,
    required this.high,
    required this.surface,
    required this.ink,
    required this.hover,
  });
  final TimeOfDay grid;
  final List<String> labels;
  final double cellW, cellH;
  final Color low, high, surface, ink;
  final (int, int)? hover;

  void _text(Canvas c, String s, Offset o, {double size = 10, bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: ink, fontSize: size)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center ? o - Offset(tp.width / 2, 0) : o);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const lw = _TimeOfDayGridState._labelW, hh = _TimeOfDayGridState._headerH;
    final max = math.max(1, grid.max);
    for (var h = 0; h < 24; h += 3) {
      _text(canvas, h.toString().padLeft(2, '0'), Offset(lw + h * cellW + cellW / 2, 2), center: true);
    }
    for (var d = 0; d < 7 && d < grid.grid.length; d++) {
      _text(canvas, labels[d], Offset(0, hh + d * cellH + cellH / 2 - 7), size: 11);
      for (var h = 0; h < 24 && h < grid.grid[d].length; h++) {
        final v = grid.grid[d][h];
        final r = Rect.fromLTWH(lw + h * cellW + 1, hh + d * cellH + 1, cellW - 2, cellH - 2);
        final color = v == 0 ? low.withValues(alpha: 0.5) : Color.lerp(low, high, math.sqrt(v / max))!;
        canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = color);
        if (hover == (d, h)) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(r.inflate(1), const Radius.circular(3)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = ink,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.grid != grid || old.hover != hover || old.high != high || old.cellW != cellW;
}

// ---------------------------------------------------------------- zones

class _Legend extends StatelessWidget {
  const _Legend(this.items);
  final List<(Color, String)> items;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 16, children: [
        for (final (c, s) in items)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text(s, style: Theme.of(context).textTheme.bodySmall),
          ]),
      ]);
}

const _authColor = UavrColors.low, _noPermitColor = UavrColors.critical, _unknownColor = Color(0xFF9E9E9E);

class ZonesCard extends ConsumerWidget {
  const ZonesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final u = context.u;
    final lang = context.lang;
    return AsyncSection<List<StatRow>>(
      title: l.zonesAuthorization,
      value: ref.watch(zoneStatsProvider),
      builder: (rows) {
        if (rows.isEmpty) return Text(l.noData);
        final top = rows.take(15).toList();
        String name(StatRow r) => lang == 'zh-TW' ? r.s('name_zh') : r.s('name');
        final maxY = top.fold<int>(1, (m, r) => math.max(m, r.i('incidents'))).toDouble();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Legend([(_authColor, l.authLikelyAuthorized), (_noPermitColor, l.authNoPermit), (_unknownColor, l.authUnknown)]),
          const SizedBox(height: 8),
          SizedBox(
            height: 240,
            child: BarChart(BarChartData(
              maxY: maxY * 1.1,
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (g, _, _, _) {
                    final r = top[g.x];
                    return BarTooltipItem(
                      '${name(r)}\n${l.authLikelyAuthorized} ${r.i('authorized')} · ${l.authNoPermit} ${r.i('no_permit')} · ${l.authUnknown} ${r.i('unknown')}',
                      const TextStyle(color: Colors.white, fontSize: 11),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(top[v.toInt()].s('code'), style: const TextStyle(fontSize: 9)),
                    ),
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < top.length; i++)
                  () {
                    final r = top[i];
                    final a = r.i('authorized').toDouble(), n = r.i('no_permit').toDouble(), k = r.i('unknown').toDouble();
                    return BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: a + n + k,
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        rodStackItems: [
                          BarChartRodStackItem(0, a, _authColor),
                          BarChartRodStackItem(a, a + n, _noPermitColor),
                          BarChartRodStackItem(a + n, a + n + k, _unknownColor),
                        ],
                      ),
                    ]);
                  }(),
              ],
            )),
          ),
          const SizedBox(height: 8),
          DashTable(
            headers: [l.zone, l.zoneType, l.kpiIncidents, l.authLikelyAuthorized, l.authNoPermit, l.authUnknown],
            rows: [
              for (final r in rows)
                [
                  '${r.s('code')} ${name(r)}',
                  zoneTypeLabel(u, r.s('zone_type')),
                  '${r.i('incidents')}',
                  '${r.i('authorized')}',
                  '${r.i('no_permit')}',
                  '${r.i('unknown')}',
                ],
            ],
          ),
        ]);
      },
    );
  }
}

// ---------------------------------------------------------------- response

class ResponseCard extends ConsumerWidget {
  const ResponseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final u = context.u;
    final lang = context.lang;
    final group = ref.watch(responseGroupProvider);
    final scheme = Theme.of(context).colorScheme;
    final p50 = scheme.primary, p90 = scheme.primary.withValues(alpha: 0.45);
    return AsyncSection<List<StatRow>>(
      title: l.responsePerformance,
      trailing: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [ButtonSegment(value: 'agency', label: Text(l.byAgency)), ButtonSegment(value: 'desk', label: Text(l.byDesk))],
        selected: {group},
        onSelectionChanged: (v) => ref.read(responseGroupProvider.notifier).set(v.first),
      ),
      value: ref.watch(responseStatsProvider),
      builder: (rows) {
        if (rows.isEmpty) return Text(l.noData);
        String label(StatRow r) => '${r.s('code')}·${severityLabel(u, r.i('severity'))}';
        final chartRows = rows.take(24).toList();
        final maxY = chartRows.fold<double>(1, (m, r) => math.max(m, r.d('ack_p90_s') ?? 0)) / 60;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Legend([(p50, l.ackP50Minutes), (p90, l.ackP90Minutes)]),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: BarChart(BarChartData(
              maxY: maxY * 1.15,
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (g, _, rod, ri) => BarTooltipItem(
                    '${label(chartRows[g.x])}\n${ri == 0 ? 'p50' : 'p90'} ${durationLabel((rod.toY * 60))}',
                    const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(label(chartRows[v.toInt()]), style: const TextStyle(fontSize: 9)),
                    ),
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < chartRows.length; i++)
                  BarChartGroupData(x: i, barsSpace: 2, barRods: [
                    BarChartRodData(
                      toY: (chartRows[i].d('ack_p50_s') ?? 0) / 60,
                      color: p50,
                      width: 8,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                    BarChartRodData(
                      toY: (chartRows[i].d('ack_p90_s') ?? 0) / 60,
                      color: p90,
                      width: 8,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ]),
              ],
            )),
          ),
          const SizedBox(height: 8),
          DashTable(
            headers: [
              group == 'agency' ? l.agency : l.desk,
              l.severity,
              l.cases,
              l.ackP50,
              l.ackP90,
              l.resolveP50,
              l.rerouteRate,
              l.unackedRate,
            ],
            rows: [
              for (final r in rows)
                [
                  '${r.s('code')} ${lang == 'zh-TW' ? r.s('name_zh') : r.s('name')}',
                  severityLabel(u, r.i('severity')),
                  '${r.i('cases')}',
                  durationLabel(r.d('ack_p50_s')),
                  durationLabel(r.d('ack_p90_s')),
                  durationLabel(r.d('resolve_p50_s')),
                  percent(r.d('reroute_rate')),
                  percent(r.d('unacked_rate')),
                ],
            ],
          ),
        ]);
      },
    );
  }
}

/// Plain dense table used by the dashboard cards.
class DashTable extends StatelessWidget {
  const DashTable({super.key, required this.headers, required this.rows});
  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final head = Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 32,
        dataRowMinHeight: 28,
        dataRowMaxHeight: 40,
        columnSpacing: 20,
        columns: [for (final h in headers) DataColumn(label: Text(h, style: head))],
        rows: [
          for (final r in rows) DataRow(cells: [for (final c in r) DataCell(SelectableText(c))]),
        ],
      ),
    );
  }
}
