import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every ARB file must translate every template key, keep its placeholders, and the
/// Chinese fallback (zh) must match Traditional Chinese (zh_TW).
void main() {
  Map<String, dynamic> load(String locale) =>
      jsonDecode(File('lib/l10n/informant_$locale.arb').readAsStringSync()) as Map<String, dynamic>;

  Set<String> messageKeys(Map<String, dynamic> arb) => arb.keys.where((k) => !k.startsWith('@')).toSet();

  final placeholder = RegExp(r'\{(\w+)[,}]');
  Set<String> placeholders(String message) => placeholder.allMatches(message).map((m) => m.group(1)!).toSet();

  const locales = ['zh_TW', 'zh', 'vi', 'id', 'th', 'fil'];
  final template = load('en');

  test('the six informant languages plus the zh fallback exist', () {
    final files = Directory('lib/l10n').listSync().map((f) => f.uri.pathSegments.last).toSet();
    expect(files, containsAll(['informant_en.arb', for (final l in locales) 'informant_$l.arb']));
  });

  for (final locale in locales) {
    test('$locale has exactly the template keys and placeholders', () {
      final arb = load(locale);
      expect(arb['@@locale'], locale);
      expect(messageKeys(arb), messageKeys(template));
      for (final key in messageKeys(template)) {
        final message = arb[key] as String;
        expect(message.trim(), isNotEmpty, reason: '$locale.$key is empty');
        expect(placeholders(message), placeholders(template[key] as String), reason: '$locale.$key placeholders');
      }
    });
  }

  test('zh is a copy of zh_TW (Traditional Chinese)', () {
    final zh = load('zh')..remove('@@locale');
    final zhTw = load('zh_TW')..remove('@@locale');
    expect(zh, zhTw);
  });
}
