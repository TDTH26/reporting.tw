import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';

/// Server-defined interview for an API language ('zh-TW', 'en', ...). Cached per language so a report
/// can still be structured when the phone is offline (the report itself then waits in the outbox).
final interviewProvider = FutureProvider.family<Interview?, String>((ref, lang) async {
  final key = 'uavr.interview.v1.$lang';
  final prefs = await SharedPreferences.getInstance();
  try {
    final iv = await ref.watch(publicApiProvider).interview(lang);
    await prefs.setString(key, jsonEncode(iv.toJson()));
    return iv;
  } catch (_) {
    final cached = prefs.getString(key);
    return cached == null ? null : Interview.fromJson(jsonDecode(cached) as Map<String, dynamic>);
  }
});
