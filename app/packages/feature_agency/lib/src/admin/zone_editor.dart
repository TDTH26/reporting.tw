import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_maps/uavr_maps.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/console_map.dart';
import '../common/l10n.dart';
import '../common/labels.dart';
import '../common/providers.dart';
import '../common/run_action.dart';

/// Zones list + editor (polygon on the map, routing chain, ack timeouts).
class ZonesAdmin extends ConsumerStatefulWidget {
  const ZonesAdmin({super.key});
  @override
  ConsumerState<ZonesAdmin> createState() => _ZonesAdminState();
}

class _ZonesAdminState extends ConsumerState<ZonesAdmin> {
  Zone? _editing;
  bool _new = false;
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final u = context.u;
    final zones = ref.watch(staffZonesProvider);
    return Row(children: [
      SizedBox(
        width: 300,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.search),
                  onChanged: (v) => setState(() => _filter = v.toLowerCase()),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: l.newZone,
                onPressed: () => setState(() {
                  _new = true;
                  _editing = null;
                }),
                icon: const Icon(Icons.add),
              ),
            ]),
          ),
          Expanded(
            child: zones.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(errorText(e), onRetry: () => ref.invalidate(staffZonesProvider)),
              data: (zs) {
                final list = zs
                    .where((z) => _filter.isEmpty || '${z.code} ${z.name} ${z.nameZh}'.toLowerCase().contains(_filter))
                    .toList()
                  ..sort((a, b) => a.code.compareTo(b.code));
                return ListView(children: [
                  for (final z in list)
                    ListTile(
                      dense: true,
                      selected: _editing?.id == z.id,
                      leading: Icon(Icons.square_rounded, color: UavrColors.zone(z.zoneType)),
                      title: Text('${z.code} · ${context.lang == 'zh-TW' ? z.nameZh : z.name}', overflow: TextOverflow.ellipsis),
                      subtitle: Text([
                        zoneTypeLabel(u, z.zoneType),
                        classificationLabel(l, z.classification),
                        if (z.published) l.published,
                      ].join(' · ')),
                      onTap: () => setState(() {
                        _editing = z;
                        _new = false;
                      }),
                    ),
                ]);
              },
            ),
          ),
        ]),
      ),
      const VerticalDivider(width: 1),
      Expanded(
        child: _editing == null && !_new
            ? EmptyView(l.selectZone, icon: Icons.layers_outlined)
            : ZoneEditor(
                key: ValueKey(_new ? 'new' : _editing!.id),
                zone: _new ? null : _editing,
                onSaved: () {
                  ref.invalidate(staffZonesProvider);
                  setState(() {
                    _editing = null;
                    _new = false;
                  });
                },
              ),
      ),
    ]);
  }
}

class ZoneEditor extends ConsumerStatefulWidget {
  const ZoneEditor({super.key, required this.zone, required this.onSaved});
  final Zone? zone;
  final VoidCallback onSaved;

  @override
  ConsumerState<ZoneEditor> createState() => _ZoneEditorState();
}

class _ZoneEditorState extends ConsumerState<ZoneEditor> {
  final _map = MapController();
  final _mapKey = GlobalKey();
  late final Zone? z = widget.zone;
  late final _code = TextEditingController(text: z?.code ?? '');
  late final _name = TextEditingController(text: z?.name ?? '');
  late final _nameZh = TextEditingController(text: z?.nameZh ?? '');
  late final _priority = TextEditingController(text: '${z?.priority ?? 0}');
  late final _ack = {
    for (final s in ['3', '2', '1']) s: TextEditingController(text: z?.ackTimeouts[s]?.toString() ?? ''),
  };
  late String _type = z?.zoneType ?? 'red';
  late int _class = z?.classification ?? 0;
  late bool _published = z?.published ?? false;
  late int? _primary = z?.primaryDeskId;
  late List<int> _backups = [...?z?.backupChain];
  late List<LatLon> _ring = z == null || z!.rings.isEmpty ? [] : _open(z!.rings.first);
  final List<List<LatLon>> _undo = [];
  bool _saving = false;

  static List<LatLon> _open(List<LatLon> r) => r.length > 1 && r.first == r.last ? r.sublist(0, r.length - 1) : [...r];

  @override
  void dispose() {
    for (final c in [_code, _name, _nameZh, _priority, ..._ack.values]) {
      c.dispose();
    }
    super.dispose();
  }

  void _edit(List<LatLon> next) => setState(() {
        _undo.add(_ring);
        _ring = next;
      });

  LatLon? _toLatLon(Offset global) {
    final box = _mapKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    try {
      return lo(_map.camera.screenOffsetToLatLng(box.globalToLocal(global)));
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    final l = context.l;
    final missing = _code.text.trim().isEmpty || _name.text.trim().isEmpty || _nameZh.text.trim().isEmpty;
    if (missing || _ring.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(missing ? l.zoneFieldsRequired : l.zoneNeedsPolygon)));
      return;
    }
    final zone = Zone(
      id: z?.id,
      code: _code.text.trim(),
      name: _name.text.trim(),
      nameZh: _nameZh.text.trim(),
      zoneType: _type,
      rings: [_ring, ...?z?.rings.skip(1)],
      classification: _class,
      published: _published,
      primaryDeskId: _primary,
      backupChain: _backups,
      priority: int.tryParse(_priority.text.trim()) ?? 0,
      ackTimeouts: {
        for (final e in _ack.entries)
          if (int.tryParse(e.value.text.trim()) != null) e.key: int.parse(e.value.text.trim()),
      },
    );
    setState(() => _saving = true);
    final api = ref.read(staffApiProvider);
    final ok = await runAction(context, () async {
      if (z?.id == null) {
        await api.createZone(zone);
      } else {
        await api.updateZone(z!.id!, zone);
      }
      return true;
    }, success: l.saved);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok == true) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final u = context.u;
    final me = ref.watch(meProvider).value!;
    final desks = ref.watch(desksProvider).value ?? const <Desk>[];
    final lang = context.lang;
    String deskName(int id) => desks.where((d) => d.id == id).firstOrNull?.label(lang) ?? '#$id';
    final pts = _ring.map(ll).toList();
    final color = UavrColors.zone(_type);
    final map = Stack(children: [
      KeyedSubtree(
        key: _mapKey,
        child: ConsoleMap(
          controller: _map,
          initialCenter: _ring.isEmpty ? null : ll(_ring.first),
          initialZoom: _ring.isEmpty ? 7.2 : 12,
          onTap: (p) => _edit([..._ring, lo(p)]),
          children: [
            PolygonLayer(polygons: [
              if (pts.length >= 3)
                Polygon(points: pts, color: color.withValues(alpha: 0.2), borderColor: color, borderStrokeWidth: 2),
            ]),
            PolylineLayer(polylines: [if (pts.length == 2) Polyline(points: pts, color: color, strokeWidth: 2)]),
            MarkerLayer(markers: [
              for (var i = 0; i < pts.length; i++)
                Marker(
                  point: pts[i],
                  width: 22,
                  height: 22,
                  child: GestureDetector(
                    onPanStart: (_) => _undo.add([..._ring]),
                    onPanUpdate: (d) {
                      final p = _toLatLon(d.globalPosition);
                      if (p != null) setState(() => _ring = [..._ring]..[i] = p);
                    },
                    onLongPress: () => _edit([..._ring]..removeAt(i)),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 3),
                      ),
                      child: Center(child: Text('${i + 1}', style: const TextStyle(fontSize: 9, color: Colors.black))),
                    ),
                  ),
                ),
            ]),
          ],
        ),
      ),
      Positioned(
        left: 8,
        top: 8,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(children: [
              IconButton(
                tooltip: l.undo,
                onPressed: _undo.isEmpty ? null : () => setState(() => _ring = _undo.removeLast()),
                icon: const Icon(Icons.undo),
              ),
              IconButton(tooltip: l.clear, onPressed: _ring.isEmpty ? null : () => _edit([]), icon: const Icon(Icons.delete_sweep_outlined)),
              IconButton(
                tooltip: l.fitAll,
                onPressed: () {
                  try {
                    fitTo(_map, _ring);
                  } catch (_) {}
                },
                icon: const Icon(Icons.fit_screen),
              ),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(l.vertexHelp(_ring.length))),
            ]),
          ),
        ),
      ),
    ]);

    final form = ListView(padding: const EdgeInsets.all(12), children: [
      Text(z == null ? l.newZone : '${l.editZone}: ${z!.code}', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      TextField(controller: _code, decoration: InputDecoration(labelText: l.code)),
      const SizedBox(height: 8),
      TextField(controller: _name, decoration: InputDecoration(labelText: l.nameEn)),
      const SizedBox(height: 8),
      TextField(controller: _nameZh, decoration: InputDecoration(labelText: l.nameZh)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        initialValue: _type,
        decoration: InputDecoration(labelText: l.zoneType),
        items: [for (final t in zoneTypes) DropdownMenuItem(value: t, child: Text('${zoneTypeLabel(u, t)} ($t)'))],
        onChanged: (v) => setState(() => _type = v ?? _type),
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<int>(
        initialValue: _class,
        decoration: InputDecoration(labelText: l.classification),
        items: [
          for (var c = 0; c <= 2; c++)
            DropdownMenuItem(value: c, enabled: c <= me.clearance, child: Text('$c · ${classificationLabel(l, c)}')),
        ],
        onChanged: (v) => setState(() => _class = v ?? _class),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l.published),
        subtitle: Text(l.publishedHint),
        value: _published,
        onChanged: (v) => setState(() => _published = v),
      ),
      TextField(controller: _priority, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l.priority)),
      const SizedBox(height: 12),
      DropdownButtonFormField<int?>(
        initialValue: _primary,
        isExpanded: true,
        decoration: InputDecoration(labelText: l.primaryDesk),
        items: [
          DropdownMenuItem(value: null, child: Text(l.none)),
          for (final d in desks) DropdownMenuItem(value: d.id, child: Text('${d.code} · ${d.label(lang)}', overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (v) => setState(() => _primary = v),
      ),
      const SizedBox(height: 12),
      Text(l.backupChain, style: Theme.of(context).textTheme.labelLarge),
      for (var i = 0; i < _backups.length; i++)
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(radius: 12, child: Text('${i + 1}', style: const TextStyle(fontSize: 11))),
          title: Text(deskName(_backups[i])),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              icon: const Icon(Icons.arrow_upward, size: 18),
              onPressed: i == 0 ? null : () => setState(() => _backups.insert(i - 1, _backups.removeAt(i))),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_downward, size: 18),
              onPressed: i == _backups.length - 1 ? null : () => setState(() => _backups.insert(i + 1, _backups.removeAt(i))),
            ),
            IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _backups.removeAt(i))),
          ]),
        ),
      DropdownButton<int>(
        hint: Text(l.addBackupDesk),
        isExpanded: true,
        value: null,
        items: [
          for (final d in desks)
            if (!_backups.contains(d.id) && d.id != _primary)
              DropdownMenuItem(value: d.id, child: Text('${d.code} · ${d.label(lang)}', overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (v) => v == null ? null : setState(() => _backups = [..._backups, v]),
      ),
      Text(l.backupChainHint, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 12),
      Text(l.ackTimeouts, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 6),
      Row(children: [
        for (final s in ['3', '2', '1']) ...[
          Expanded(
            child: TextField(
              controller: _ack[s],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: severityLabel(u, int.parse(s)), suffixText: 's', hintText: l.defaultValue),
            ),
          ),
          if (s != '1') const SizedBox(width: 8),
        ],
      ]),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.save_outlined),
        label: Text(context.u.save),
      ),
    ]);

    return Row(children: [
      Expanded(child: map),
      const VerticalDivider(width: 1),
      SizedBox(width: 340, child: form),
    ]);
  }
}
