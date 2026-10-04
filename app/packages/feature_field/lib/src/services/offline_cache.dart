import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uavr_api/uavr_api.dart';
import '../json_util.dart';

class Cached<T> {
  const Cached(this.value, this.savedAt);
  final T value;
  final DateTime savedAt;
}

/// Key/value JSON cache for offline use (last assignments, opened cases, signed-in officer).
///
/// The device is MDM-managed and wiped remotely when lost; the cache is also cleared on logout.
abstract class OfflineCache {
  Future<Cached<Object?>?> read(String key);
  Future<void> write(String key, Object? value);
  Future<void> clear();
}

extension OfflineCacheX on OfflineCache {
  static const _assignments = 'assignments';
  static const _me = 'me';
  static String _case(String id) => 'case_${id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}';

  Future<void> writeAssignments(List<CaseSummary> cases) => write(_assignments, [for (final c in cases) c.raw]);

  Future<Cached<List<CaseSummary>>?> readAssignments() async {
    final c = await read(_assignments);
    if (c == null || c.value is! List) return null;
    return Cached(listOf(c.value, CaseSummary.fromJson), c.savedAt);
  }

  Future<void> writeCase(CaseDetail d) => write(_case(d.summary.id), d.summary.raw);

  Future<Cached<CaseDetail>?> readCase(String id) async {
    final c = await read(_case(id));
    final j = obj(c?.value);
    return j == null ? null : Cached(CaseDetail.fromJson(j), c!.savedAt);
  }

  Future<void> writeMe(Me me) => write(_me, meToJson(me));

  Future<Me?> readMe() async {
    final j = obj((await read(_me))?.value);
    return j == null ? null : Me.fromJson(j);
  }
}

Json? _ref(NamedRef? r) =>
    r == null ? null : {'id': r.id, 'code': r.code, 'name': r.name, 'name_zh': r.nameZh, 'kind': r.kind};

/// `Me` has no toJson in uavr_api; this mirrors Me.fromJson.
Json meToJson(Me m) => {
      'id': m.id,
      'username': m.username,
      'display_name': m.displayName,
      'roles': m.roles.toList(),
      'clearance': m.clearance,
      'field_unit': m.fieldUnit,
      'on_duty': m.onDuty,
      'desk': _ref(m.desk),
      'agency': _ref(m.agency),
    };

/// JSON files in the app support directory (not backed up, private to the app).
class FileOfflineCache implements OfflineCache {
  FileOfflineCache({Future<Directory> Function()? dir}) : _dir = dir ?? getApplicationSupportDirectory;
  final Future<Directory> Function() _dir;

  Future<Directory> _base() async {
    final d = Directory('${(await _dir()).path}/field_cache');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  @override
  Future<Cached<Object?>?> read(String key) async {
    try {
      final f = File('${(await _base()).path}/$key.json');
      if (!await f.exists()) return null;
      final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return Cached(j['data'], DateTime.parse(j['saved_at'] as String));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, Object? value) async {
    try {
      final base = await _base();
      final tmp = File('${base.path}/$key.json.tmp');
      await tmp.writeAsString(jsonEncode({'saved_at': DateTime.now().toUtc().toIso8601String(), 'data': value}));
      await tmp.rename('${base.path}/$key.json');
    } catch (_) {
      // Cache is best effort.
    }
  }

  @override
  Future<void> clear() async {
    try {
      final d = await _base();
      await d.delete(recursive: true);
    } catch (_) {}
  }
}

/// In-memory cache (tests, web).
class MemoryOfflineCache implements OfflineCache {
  final _m = <String, Cached<Object?>>{};

  @override
  Future<Cached<Object?>?> read(String key) async => _m[key];

  @override
  Future<void> write(String key, Object? value) async =>
      _m[key] = Cached(jsonDecode(jsonEncode(value)), DateTime.now().toUtc());

  @override
  Future<void> clear() async => _m.clear();
}

final offlineCacheProvider = Provider<OfflineCache>((ref) => FileOfflineCache());
