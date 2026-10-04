import 'package:flutter/foundation.dart';

enum AppFlavor { informant, agency, field }

/// Build-time configuration from `--dart-define`s, with dev defaults that work against
/// `make up` (nginx on :8480).
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.apiBaseUrl,
    required this.tileUrlTemplate,
    required this.tileAttribution,
    this.playCloudProjectNumber,
    this.androidAppUrl = 'https://play.google.com/store/apps/details?id=tw.reporting.app',
    this.appVersion = '1.0.0',
  });

  final AppFlavor flavor;
  final String apiBaseUrl;

  /// Raster tile template ({z}/{x}/{y}). Production points at the self-hosted tile server.
  final String tileUrlTemplate;
  final String tileAttribution;
  final int? playCloudProjectNumber;
  final String androidAppUrl;
  final String appVersion;

  static const _api = String.fromEnvironment('UAVR_API');
  static const _tiles = String.fromEnvironment('UAVR_TILES');
  static const _play = int.fromEnvironment('UAVR_PLAY_PROJECT');
  static const _version = String.fromEnvironment('UAVR_VERSION', defaultValue: '1.0.0');

  /// NLSC (內政部國土測繪中心) EMAP basemap: the official Taiwan map, used until the self-hosted
  /// tile server is configured via UAVR_TILES.
  static const nlscEmap = 'https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}';

  factory AppConfig.fromEnvironment(AppFlavor flavor) {
    String api = _api;
    if (api.isEmpty) {
      if (kIsWeb) {
        // Served behind the same nginx as the API: https://host/api
        api = '${Uri.base.origin}/api';
      } else {
        api = 'http://10.0.2.2:8480/api'; // Android emulator -> host machine
      }
    }
    return AppConfig(
      flavor: flavor,
      apiBaseUrl: api,
      tileUrlTemplate: _tiles.isEmpty ? nlscEmap : _tiles,
      tileAttribution: _tiles.isEmpty ? '© 內政部國土測繪中心 NLSC' : '© OpenStreetMap contributors',
      playCloudProjectNumber: _play == 0 ? null : _play,
      appVersion: _version,
    );
  }
}
