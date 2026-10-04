import 'package:flutter/widgets.dart';

/// The six informant-facing languages, in display order. API language codes use BCP 47 tags.
const informantLocales = [
  Locale('zh', 'TW'),
  Locale('en'),
  Locale('vi'),
  Locale('id'),
  Locale('th'),
  Locale('fil'),
  Locale('de'),
  Locale('fr'),
];

/// Staff-facing builds (console, field app) ship Traditional Chinese and English.
const staffLocales = [Locale('zh', 'TW'), Locale('en')];

/// Locale -> API language code ('zh-TW', 'en', 'vi', 'id', 'th', 'fil', 'de', 'fr').
String apiLanguage(Locale l) => l.languageCode == 'zh' ? 'zh-TW' : l.languageCode;

Locale localeFromApi(String code) => code == 'zh-TW' ? const Locale('zh', 'TW') : Locale(code);

/// Picks the closest supported locale for the device locale (any Chinese -> zh_TW).
Locale resolveLocale(Locale? device, List<Locale> supported) {
  if (device == null) return supported.first;
  for (final s in supported) {
    if (s.languageCode == device.languageCode) return s;
  }
  if (device.languageCode == 'tl') return const Locale('fil');
  return supported.first;
}
