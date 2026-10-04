// Small helpers so the hand-written models stay terse and null-safe.

typedef Json = Map<String, dynamic>;

DateTime? parseDate(Object? v) => v is String ? DateTime.tryParse(v) : null;

double? toDouble(Object? v) => v is num ? v.toDouble() : null;

int? toInt(Object? v) => v is num ? v.toInt() : null;

List<T> listOf<T>(Object? v, T Function(Json) f) =>
    v is List ? v.whereType<Map>().map((e) => f(e.cast<String, dynamic>())).toList() : <T>[];

List<String> strings(Object? v) => v is List ? v.map((e) => '$e').toList() : const [];

Json? obj(Object? v) => v is Map ? v.cast<String, dynamic>() : null;

Json compact(Json m) => m..removeWhere((_, v) => v == null);
