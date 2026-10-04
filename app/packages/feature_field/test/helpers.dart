import 'dart:async';
import 'dart:convert';

import 'package:feature_field/feature_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_capture/uavr_capture.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_native/uavr_native.dart';
import 'package:uavr_ui/uavr_ui.dart';

const apiBase = 'http://api.test/api';

Me fieldOfficer() => Me.fromJson({
      'id': '6b1f8a52-0000-4000-8000-000000000001',
      'username': 'tpe.field',
      'display_name': 'Officer Lin',
      'roles': ['field_officer'],
      'clearance': 1,
      'field_unit': false,
      'on_duty': true,
    });

const myPosition = LatLon(25.0330, 121.5654); // Taipei 101

class FakeSensors implements FieldSensors {
  GpsFix? fix = GpsFix(position: myPosition, accuracyM: 6, at: DateTime.utc(2026, 10, 2, 8));
  RemoteIdCapabilities caps =
      const RemoteIdCapabilities(bluetoothLegacy: true, bluetoothLongRange: true, wifiBeacon: true, wifiNan: false);
  ScanPermissions perms = const ScanPermissions(bluetooth: true, location: true, nearbyWifi: true);
  final drones = StreamController<RemoteIdDrone>.broadcast();
  final orientations = StreamController<OrientationSample>.broadcast();

  @override
  Stream<GpsFix> positions() => fix == null ? const Stream.empty() : Stream.value(fix!);
  @override
  Future<GpsFix?> currentFix() async => fix;
  @override
  Stream<OrientationSample> orientation() => orientations.stream;
  @override
  Future<RemoteIdCapabilities> remoteIdCapabilities() async => caps;
  @override
  Future<ScanPermissions> requestScanPermissions() async => perms;
  @override
  Stream<RemoteIdDrone> remoteIdDrones() => drones.stream;
  @override
  Future<void> openSettings() async {}
}

class FakeLive implements FieldLive {
  final controller = StreamController<LiveMessage>.broadcast();
  int starts = 0;
  @override
  Stream<LiveMessage> get events => controller.stream;
  @override
  void start() => starts++;
}

class FakeUploader implements EvidenceUploader {
  final calls = <(String, List<CapturedMedia>, List<UploadTicket>)>[];
  @override
  Future<void> upload(String caseNumber, List<CapturedMedia> media, List<UploadTicket> tickets) async =>
      calls.add((caseNumber, media, tickets));
}

/// Recorded HTTP request.
class Call {
  Call(this.method, this.path, this.body);
  final String method, path;
  final Object? body;
}

/// MockClient that records requests and answers through [handler]; throw from it to simulate
/// an unreachable server.
class FakeServer {
  FakeServer(this.handler);
  Future<http.Response> Function(http.Request r) handler;
  final calls = <Call>[];

  late final client = MockClient((r) async {
    calls.add(Call(r.method, r.url.path, r.body.isEmpty ? null : jsonDecode(r.body)));
    return handler(r);
  });

  UavrApi api() => UavrApi(apiBase, httpClient: client, accessToken: () async => 'test-token');
}

http.Response jsonResponse(Object? body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status, headers: {'content-type': 'application/json'});

Never offline(http.Request _) => throw const SocketLikeException();

class SocketLikeException implements Exception {
  const SocketLikeException();
  @override
  String toString() => 'SocketException: network unreachable';
}

const testConfig = AppConfig(
  flavor: AppFlavor.field,
  apiBaseUrl: apiBase,
  tileUrlTemplate: 'http://tiles.test/{z}/{x}/{y}.png',
  tileAttribution: 'test',
);

class TestDeps {
  TestDeps(this.server);
  final FakeServer server;
  final sensors = FakeSensors();
  final live = FakeLive();
  final cache = MemoryOfflineCache();
  final outboxStore = MemoryOutboxStore();
  final uploader = FakeUploader();
  Me me = fieldOfficer();

  List<Override> overrides() => [
        configProvider.overrideWithValue(testConfig),
        staffApiProvider.overrideWithValue(server.api()),
        meProvider.overrideWith((ref) async => me),
        fieldSensorsProvider.overrideWithValue(sensors),
        fieldLiveProvider.overrideWithValue(live),
        offlineCacheProvider.overrideWithValue(cache),
        outboxStoreProvider.overrideWithValue(outboxStore),
        evidenceUploaderProvider.overrideWithValue(uploader),
      ];

  Widget wrap(Widget child) => ProviderScope(
        overrides: overrides(),
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: staffLocales,
          localizationsDelegates: fieldLocalizationsDelegates,
          theme: uavrTheme(),
          home: child,
        ),
      );

  Widget app() => ProviderScope(overrides: overrides(), child: const FieldApp());
}
