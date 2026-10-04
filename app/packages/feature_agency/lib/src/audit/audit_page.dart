import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../common/l10n.dart';
import '../common/run_action.dart';

typedef AuditFilter = ({String? user, String? action, String? objectId});

final auditProvider = FutureProvider.autoDispose.family<List<AuditEntry>, AuditFilter>(
  (ref, f) => ref.watch(staffApiProvider).audit(user: f.user, action: f.action, objectId: f.objectId, limit: 500),
  retry: (_, _) => null,
);

class AuditPage extends ConsumerStatefulWidget {
  const AuditPage({super.key});
  @override
  ConsumerState<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends ConsumerState<AuditPage> {
  final _user = TextEditingController(), _action = TextEditingController(), _object = TextEditingController();
  AuditFilter _f = (user: null, action: null, objectId: null);

  @override
  void dispose() {
    _user.dispose();
    _action.dispose();
    _object.dispose();
    super.dispose();
  }

  String? _v(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  void _apply() => setState(() => _f = (user: _v(_user), action: _v(_action), objectId: _v(_object)));

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final rows = ref.watch(auditProvider(_f));
    Widget field(TextEditingController c, String label, {double w = 200}) => SizedBox(
          width: w,
          child: TextField(controller: c, onSubmitted: (_) => _apply(), decoration: InputDecoration(labelText: label)),
        );
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          field(_user, l.auditUser),
          field(_action, l.auditActionPrefix),
          field(_object, l.auditObjectId, w: 320),
          FilledButton.icon(onPressed: _apply, icon: const Icon(Icons.filter_alt_outlined), label: Text(l.apply)),
          IconButton(tooltip: l.refresh, onPressed: () => ref.invalidate(auditProvider(_f)), icon: const Icon(Icons.refresh)),
          Text(l.auditViewAudited, style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
      const Divider(height: 1),
      Expanded(
        child: rows.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(errorText(e), onRetry: () => ref.invalidate(auditProvider(_f))),
          data: (list) => list.isEmpty
              ? EmptyView(l.noData)
              : SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowHeight: 32,
                      dataRowMinHeight: 28,
                      dataRowMaxHeight: 48,
                      columns: [
                        DataColumn(label: Text(l.time)),
                        DataColumn(label: Text(l.auditUser)),
                        DataColumn(label: Text(l.auditAction)),
                        DataColumn(label: Text(l.auditObject)),
                        const DataColumn(label: Text('IP')),
                        DataColumn(label: Text(l.details)),
                      ],
                      rows: [
                        for (final a in list)
                          DataRow(cells: [
                            DataCell(Text(dateTime(a.at))),
                            DataCell(Text(a.username ?? '—')),
                            DataCell(Text(a.action, style: const TextStyle(fontFamily: 'monospace'))),
                            DataCell(SelectableText([a.objectType, a.objectId].whereType<String>().join(' '))),
                            DataCell(Text(a.ip ?? '—')),
                            DataCell(ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: Tooltip(
                                message: const JsonEncoder.withIndent('  ').convert(a.details),
                                child: Text(a.details.isEmpty ? '' : jsonEncode(a.details),
                                    overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                              ),
                            )),
                          ]),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    ]);
  }
}
