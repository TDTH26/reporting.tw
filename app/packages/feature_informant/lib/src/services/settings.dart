import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uavr_ui/uavr_ui.dart';

/// Riverpod retry policy for providers whose errors the UI already handles.
Duration? noRetry(int retryCount, Object error) => null;

/// Locally persisted informant preferences.
class InformantSettings {
  const InformantSettings({this.locale, this.onboarded = false});

  /// Language the user picked, or null to follow the device.
  final Locale? locale;
  final bool onboarded;
}

class InformantSettingsNotifier extends AsyncNotifier<InformantSettings> {
  static const _localeKey = 'uavr.informant.locale';
  static const _onboardedKey = 'uavr.informant.onboarded';

  SharedPreferences? _prefs;

  @override
  Future<InformantSettings> build() async {
    try {
      final p = _prefs = await SharedPreferences.getInstance();
      final tag = p.getString(_localeKey);
      return InformantSettings(
        locale: tag == null ? null : localeFromApi(tag),
        onboarded: p.getBool(_onboardedKey) ?? false,
      );
    } catch (_) {
      return const InformantSettings(); // storage unavailable (private browsing): defaults
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = AsyncData(InformantSettings(locale: locale, onboarded: _current.onboarded));
    await _prefs?.setString(_localeKey, apiLanguage(locale));
  }

  Future<void> setOnboarded(bool done) async {
    state = AsyncData(InformantSettings(locale: _current.locale, onboarded: done));
    await _prefs?.setBool(_onboardedKey, done);
  }

  InformantSettings get _current => state.value ?? const InformantSettings();
}

final informantSettingsProvider =
    AsyncNotifierProvider<InformantSettingsNotifier, InformantSettings>(InformantSettingsNotifier.new, retry: noRetry);

/// Device locale; overridable in tests.
final deviceLocaleProvider = Provider<Locale>((ref) => PlatformDispatcher.instance.locale);

/// The locale the app is shown in: the user's choice, else the closest match to the device.
final appLocaleProvider = Provider<Locale>((ref) {
  final chosen = ref.watch(informantSettingsProvider).value?.locale;
  return chosen ?? resolveLocale(ref.watch(deviceLocaleProvider), informantLocales);
});

/// API language code ('zh-TW', 'en', ...) for the current locale.
final apiLanguageProvider = Provider<String>((ref) => apiLanguage(ref.watch(appLocaleProvider)));
