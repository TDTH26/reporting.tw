import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:feature_informant/feature_informant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_capture/uavr_capture.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_native/uavr_native.dart';

const testConfig = AppConfig(
  flavor: AppFlavor.informant,
  apiBaseUrl: 'http://test/api',
  tileUrlTemplate: 'http://test/tiles/{z}/{x}/{y}.png',
  tileAttribution: 'test',
  playCloudProjectNumber: 1234,
);

class FakeSensors implements InformantSensors {
  final fixes = StreamController<LocationFix>.broadcast();
  final orientations = StreamController<OrientationSample>.broadcast();
  final drones = StreamController<RemoteIdDrone>.broadcast();
  final integrityHashes = <String>[];
  bool withCamera = true;

  @override
  String platform = 'android';

  @override
  Stream<LocationFix> locationFixes() => fixes.stream;
  @override
  Stream<OrientationSample> orientation() => orientations.stream;
  @override
  bool get remoteIdSupported => true;
  @override
  Future<List<String>> remoteIdTransports() async => const ['bt4', 'bt5'];
  @override
  Stream<RemoteIdDrone> remoteIdDrones() => drones.stream;
  @override
  Future<void> setDeclinationLocation(LocationFix fix) async {}
  @override
  Future<String?> integrityToken(String requestHash, int cloudProjectNumber) async {
    integrityHashes.add(requestHash);
    return 'integrity-token';
  }

  @override
  Future<AimCamera?> openBackCamera() async => withCamera ? FakeCamera() : null;
}

class FakeCamera implements AimCamera {
  @override
  Widget preview() => const ColoredBox(color: Colors.blueGrey);
  @override
  Future<XFile> takePicture() async =>
      XFile.fromData(Uint8List.fromList(List.filled(2048, 7)), name: 'aim.jpg', mimeType: 'image/jpeg');
  @override
  Future<void> dispose() async {}
}

class FakeCapture implements EvidenceCapture {
  int _n = 0;

  Future<CapturedMedia> _make(MediaKind kind, String mime) =>
      ingestBytes(Uint8List.fromList(utf8.encode('${kind.name} ${++_n}')), kind, mime, slot: '${kind.name}$_n');

  @override
  Future<CapturedMedia?> photo() => _make(MediaKind.photo, 'image/jpeg');
  @override
  Future<CapturedMedia?> video() => _make(MediaKind.video, 'video/mp4');
  @override
  Future<bool> startAudio() async => true;
  @override
  Future<CapturedMedia?> stopAudio() => _make(MediaKind.audio, 'audio/mp4');
  @override
  Stream<double> amplitude() => const Stream.empty();
  @override
  Future<CapturedMedia> ingest(XFile file, MediaKind kind, String slot) async =>
      ingestBytes(await file.readAsBytes(), kind, file.mimeType ?? 'image/jpeg', slot: slot);
  @override
  Future<void> dispose() async {}
}

class FakeUploads implements EvidenceUploads {
  final enqueued = <({String caseNumber, List<String> slots, List<UploadTicket> tickets})>[];
  final _changes = StreamController<List<UploadJob>>.broadcast();
  int runs = 0;

  @override
  Stream<List<UploadJob>> get changes => _changes.stream;
  @override
  List<UploadJob> get jobs => const [];
  @override
  Future<void> enqueue(String caseNumber, List<CapturedMedia> media, List<UploadTicket> tickets) async =>
      enqueued.add((caseNumber: caseNumber, slots: [for (final m in media) m.slot], tickets: tickets));
  @override
  Future<void> run() async => runs++;
  @override
  Future<void> kickBackground() async {}
}

class FakePermissions implements PermissionGate {
  @override
  bool get asksUpFront => false;
  @override
  Future<bool> isGranted(InformantPermission p) async => true;
  @override
  Future<bool> request(InformantPermission p) async => true;
  @override
  Future<void> openSettings() async {}
}

/// Records every request; [handler] returns the response.
class FakeBackend {
  FakeBackend(this.handler);
  Future<http.Response> Function(http.Request) handler;
  final requests = <http.Request>[];

  late final client = MockClient((r) {
    requests.add(r);
    return handler(r);
  });

  UavrApi api() => UavrApi(testConfig.apiBaseUrl, httpClient: client);

  List<Map<String, dynamic>> bodiesFor(String method, String path) => [
        for (final r in requests)
          if (r.method == method && r.url.path.endsWith(path)) jsonDecode(r.body) as Map<String, dynamic>,
      ];
}

http.Response jsonResponse(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

/// Overrides that replace every device and network dependency of the informant app.
List<Override> overridesFor({
  required FakeBackend backend,
  FakeSensors? sensors,
  FakeCapture? capture,
  FakeUploads? uploads,
}) =>
    [
      configProvider.overrideWithValue(testConfig),
      publicApiProvider.overrideWithValue(backend.api()),
      informantSensorsProvider.overrideWithValue(sensors ?? FakeSensors()),
      evidenceCaptureProvider.overrideWith((ref) => capture ?? FakeCapture()),
      evidenceUploadsProvider.overrideWithValue(uploads ?? FakeUploads()),
      permissionGateProvider.overrideWithValue(FakePermissions()),
      deviceLocaleProvider.overrideWithValue(const Locale('en')),
    ];

LocationFix fixAt(double lat, double lon, {double accuracy = 6}) =>
    LocationFix(position: LatLon(lat, lon), accuracyM: accuracy, at: DateTime.now().toUtc());

OrientationSample sample({double az = 123.4, double el = 25.0, int accuracy = 2}) => OrientationSample(
      azimuthDeg: az,
      magneticAzimuthDeg: az,
      elevationDeg: el,
      declinationDeg: -4.5,
      accuracy: accuracy,
      at: DateTime.now().toUtc(),
    );
