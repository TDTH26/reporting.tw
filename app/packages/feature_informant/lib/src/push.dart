import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_core/uavr_core.dart';

import 'services/my_reports.dart';
import 'services/sensors.dart';
import 'services/settings.dart';

/// Current FCM token, or null when push is not configured or not allowed.
class PushTokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String token) => state = token;
}

final pushTokenProvider = NotifierProvider<PushTokenNotifier, String?>(PushTokenNotifier.new);

/// FCM push, enabled only when the Firebase options are passed via --dart-define.
/// The token is linked to cases, never to a person, and notifications carry no case
/// details: a message only makes the app refresh statuses.
class InformantPush {
  InformantPush(this._ref);
  final Ref _ref;
  bool _started = false;

  static const _apiKey = String.fromEnvironment('UAVR_FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('UAVR_FIREBASE_APP_ID');
  static const _senderId = String.fromEnvironment('UAVR_FIREBASE_SENDER_ID');
  static const _projectId = String.fromEnvironment('UAVR_FIREBASE_PROJECT_ID');

  static bool get configured =>
      _apiKey.isNotEmpty && _appId.isNotEmpty && _senderId.isNotEmpty && _projectId.isNotEmpty;

  Future<void> start() async {
    if (_started || !configured) return;
    _started = true;
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: _apiKey,
          appId: _appId,
          messagingSenderId: _senderId,
          projectId: _projectId,
        ),
      );
      final messaging = FirebaseMessaging.instance;
      messaging.onTokenRefresh.listen(_onToken);
      FirebaseMessaging.onMessage.listen((_) => refreshStatuses());
      FirebaseMessaging.onMessageOpenedApp.listen((_) => refreshStatuses());
      _ref.listen(apiLanguageProvider, (_, _) => registerAll());
      final token = await messaging.getToken();
      if (token != null) await _onToken(token);
    } catch (_) {
      // Push is a convenience: without it the app refreshes when opened.
    }
  }

  Future<void> _onToken(String token) async {
    _ref.read(pushTokenProvider.notifier).set(token);
    await registerAll();
  }

  /// Links the current push token to every report stored on this device.
  Future<void> registerAll() async {
    final token = _ref.read(pushTokenProvider);
    if (token == null) return;
    final api = _ref.read(publicApiProvider);
    final platform = _ref.read(informantSensorsProvider).platform;
    final lang = _ref.read(apiLanguageProvider);
    for (final r in await _ref.read(informantStoreProvider).reports()) {
      try {
        await api.registerPush(r.token, token, platform: platform, language: lang);
      } catch (_) {
        // Offline or the token was revoked; the next start or token refresh retries.
      }
    }
  }

  void refreshStatuses() {
    _ref.invalidate(myReportsProvider);
    _ref.invalidate(informantCaseProvider);
  }
}

final informantPushProvider = Provider<InformantPush>(InformantPush.new);
