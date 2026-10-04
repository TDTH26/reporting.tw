import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uavr_api/uavr_api.dart';

import 'config.dart';

/// Thrown by [StaffAuth.login]: wrong credentials, locked account or no connection (see [ApiException]).
typedef LoginException = ApiException;

/// Staff login against the backend's own accounts (username + password).
///
/// Keeps a short-lived access token in memory and the refresh token in secure storage (Keystore on Android,
/// encrypted storage on web), and refreshes the access token shortly before it expires.
class StaffAuth {
  StaffAuth(this.config, {FlutterSecureStorage? storage, UavrApi? api})
      : _storage = storage ?? const FlutterSecureStorage(),
        _api = api ?? UavrApi(config.apiBaseUrl);

  final AppConfig config;
  final FlutterSecureStorage _storage;
  final UavrApi _api;
  final _changes = StreamController<String?>.broadcast();

  static const _refreshKey = 'uavr.staff.refresh.v1';

  String? _access;
  DateTime? _accessExp;
  String? _refresh;
  String? _userId;
  Future<void>? _init;
  Future<String?>? _refreshing;

  String get _client => config.flavor == AppFlavor.field ? 'field' : 'console';

  /// Emits the signed-in user id (or null) whenever it changes.
  Stream<String?> get changes => _changes.stream;
  String? get userId => _userId;
  bool get isLoggedIn => _refresh != null;

  Future<void> init() => _init ??= () async {
        _refresh = await _storage.read(key: _refreshKey);
        if (_refresh != null) await _doRefresh();
      }();

  Future<void> login(String username, String password) async {
    await init();
    final t = await _api.login(username.trim(), password, client: _client);
    await _accept(t);
  }

  Future<void> logout() async {
    await init();
    final r = _refresh;
    await _clear();
    if (r != null) {
      try {
        await _api.logoutSession(r);
      } catch (_) {}
    }
  }

  /// A valid access token, refreshed if it expires within a minute; null when signed out.
  Future<String?> accessToken() async {
    await init();
    if (_access != null && _accessExp != null && _accessExp!.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      return _access;
    }
    if (_refresh == null) return null;
    return _doRefresh();
  }

  Future<String?> _doRefresh() => _refreshing ??= () async {
        try {
          await _accept(await _api.refreshSession(_refresh!));
          return _access;
        } on ApiException catch (e) {
          // Network trouble keeps the session (we may be offline); a rejected session signs out.
          if (!e.isNetwork) await _clear();
          return null;
        } finally {
          _refreshing = null;
        }
      }();

  Future<void> _accept(StaffTokens t) async {
    _access = t.accessToken;
    _accessExp = DateTime.now().add(Duration(seconds: t.expiresIn));
    _refresh = t.refreshToken;
    await _storage.write(key: _refreshKey, value: _refresh);
    final sub = _subject(t.accessToken);
    if (sub != _userId) {
      _userId = sub;
      _changes.add(sub);
    }
  }

  Future<void> _clear() async {
    _access = _accessExp = _refresh = null;
    await _storage.delete(key: _refreshKey);
    if (_userId != null) {
      _userId = null;
      _changes.add(null);
    }
  }

  static String? _subject(String jwt) {
    try {
      final part = jwt.split('.')[1];
      final json = utf8.decode(base64Url.decode(base64Url.normalize(part)));
      return (jsonDecode(json) as Map<String, dynamic>)['sub'] as String?;
    } catch (_) {
      return null;
    }
  }
}
