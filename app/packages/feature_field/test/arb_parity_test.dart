import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync()) as Map<String, dynamic>;

Set<String> _keys(Map<String, dynamic> m) => m.keys.where((k) => !k.startsWith('@')).toSet();

Set<String> _placeholders(String s) =>
    RegExp(r'\{(\w+)[,}]').allMatches(s).map((m) => m.group(1)!).toSet()..remove('count');

void main() {
  final en = _arb('field_en.arb');
  final zhTw = _arb('field_zh_TW.arb');
  final zh = _arb('field_zh.arb');

  test('locales are declared', () {
    expect(en['@@locale'], 'en');
    expect(zhTw['@@locale'], 'zh_TW');
    expect(zh['@@locale'], 'zh');
  });

  test('en, zh_TW and zh have the same keys', () {
    expect(_keys(zhTw).difference(_keys(en)), isEmpty, reason: 'keys only in zh_TW');
    expect(_keys(en).difference(_keys(zhTw)), isEmpty, reason: 'keys missing in zh_TW');
    expect(_keys(zh), _keys(zhTw));
  });

  test('zh is a copy of zh_TW', () {
    for (final k in _keys(zhTw)) {
      expect(zh[k], zhTw[k], reason: k);
    }
  });

  test('translations use the same placeholders and are not empty', () {
    for (final k in _keys(en)) {
      final declared = ((en['@$k'] as Map?)?['placeholders'] as Map?)?.keys.toSet() ?? <String>{};
      for (final other in [zhTw, zh]) {
        final s = other[k] as String;
        expect(s.trim(), isNotEmpty, reason: k);
        expect(_placeholders(s), _placeholders(en[k] as String), reason: k);
        for (final p in declared) {
          expect(s.contains('{$p'), isTrue, reason: '$k must use {$p}');
        }
      }
    }
  });
}
