import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConsoleSettings {
  const ConsoleSettings({this.dark = false, this.locale = const Locale('zh', 'TW')});
  final bool dark;
  final Locale locale;

  ConsoleSettings copyWith({bool? dark, Locale? locale}) =>
      ConsoleSettings(dark: dark ?? this.dark, locale: locale ?? this.locale);
}

/// Theme + language, persisted per browser.
class SettingsController extends Notifier<ConsoleSettings> {
  static const _kDark = 'agency.dark', _kLocale = 'agency.locale';

  @override
  ConsoleSettings build() {
    _load();
    return const ConsoleSettings();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (!ref.mounted) return;
      final loc = p.getString(_kLocale);
      state = ConsoleSettings(
        dark: p.getBool(_kDark) ?? false,
        locale: loc == 'en' ? const Locale('en') : const Locale('zh', 'TW'),
      );
    } catch (_) {
      // Storage unavailable (private window): keep defaults.
    }
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kDark, state.dark);
      await p.setString(_kLocale, state.locale.languageCode == 'en' ? 'en' : 'zh_TW');
    } catch (_) {}
  }

  void toggleDark() {
    state = state.copyWith(dark: !state.dark);
    _save();
  }

  void setLocale(Locale l) {
    state = state.copyWith(locale: l);
    _save();
  }
}

final settingsProvider = NotifierProvider<SettingsController, ConsoleSettings>(SettingsController.new);
