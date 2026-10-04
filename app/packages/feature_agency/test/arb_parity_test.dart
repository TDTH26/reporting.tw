import 'dart:convert';
import 'dart:io';

import 'package:feature_agency/src/live/wav.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String name) => jsonDecode(File('lib/l10n/$name').readAsStringSync()) as Map<String, dynamic>;

Set<String> _keys(Map<String, dynamic> m) => m.keys.where((k) => !k.startsWith('@')).toSet();

void main() {
  final en = _arb('agency_en.arb');

  for (final other in ['agency_zh_TW.arb', 'agency_zh.arb']) {
    test('ARB key parity: $other matches agency_en.arb', () {
      final o = _arb(other);
      expect(_keys(o).difference(_keys(en)), isEmpty, reason: 'extra keys in $other');
      expect(_keys(en).difference(_keys(o)), isEmpty, reason: 'missing keys in $other');
      for (final k in _keys(en)) {
        expect((o[k] as String).trim(), isNotEmpty, reason: '$other: $k is empty');
        final meta = en['@$k'];
        if (meta is Map && meta['placeholders'] is Map) {
          for (final p in (meta['placeholders'] as Map).keys) {
            expect(o[k], contains('{$p'), reason: '$other: $k lacks placeholder {$p}');
          }
        }
      }
    });
  }

  test('zh and zh_TW are identical (Traditional Chinese)', () {
    final a = _arb('agency_zh_TW.arb')..remove('@@locale');
    final b = _arb('agency_zh.arb')..remove('@@locale');
    expect(a, b);
  });

  test('generated alert WAV has a valid RIFF header', () {
    final w = beepWav();
    expect(String.fromCharCodes(w.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(w.sublist(8, 12)), 'WAVE');
    expect(w.length, greaterThan(44));
  });
}
