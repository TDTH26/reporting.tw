// Contract check: every endpoint the Dart client calls must exist in the backend OpenAPI spec
// with the same method.  dart run tool/check_api.dart ../backend/openapi.json
import 'dart:convert';
import 'dart:io';

String norm(String p) => p
    .replaceAll(RegExp(r'\$\{[^}]+\}'), '{}')
    .replaceAll(RegExp(r'\$[a-zA-Z_]\w*'), '{}')
    .replaceAll(RegExp(r'\{[a-z_]+\}'), '{}');

void main(List<String> args) {
  final specPath = args.isNotEmpty ? args.first : '../backend/openapi.json';
  final spec = jsonDecode(File(specPath).readAsStringSync()) as Map<String, dynamic>;
  final available = <String>{
    for (final e in (spec['paths'] as Map<String, dynamic>).entries)
      for (final m in (e.value as Map<String, dynamic>).keys) '${m.toUpperCase()} ${norm(e.key)}',
  };
  final src = File('packages/uavr_api/lib/src/client.dart').readAsStringSync();
  final used = <String>{};
  for (final m in RegExp(r"_(get|post|put)\(\s*'(/v1/[^']+)'").allMatches(src)) {
    used.add('${m.group(1)!.toUpperCase()} ${norm(m.group(2)!)}');
  }
  // The generic _act helper is checked through its concrete call sites below.
  used.remove('POST /v1/agency/cases/{}/{}');
  for (final m in RegExp(r"_act\(\w+, '([a-z-]+)'").allMatches(src)) {
    used.add('POST /v1/agency/cases/{}/${m.group(1)}');
  }
  final missing = used.difference(available).toList()..sort();
  stdout.writeln('client uses ${used.length} endpoints; spec has ${available.length}');
  if (missing.isNotEmpty) {
    stderr.writeln('Not in the OpenAPI spec:\n  ${missing.join('\n  ')}');
    exit(1);
  }
  stdout.writeln('OK: client and spec agree');
}
