import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_capture/uavr_capture.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_native/uavr_native.dart';
import 'package:uuid/uuid.dart';

import '../../push.dart';
import '../../services/outbox.dart';
import '../../services/report_sender.dart';
import '../../services/sensors.dart';

enum ReportStep { aim, details, evidence }

/// Height estimate chips and the altitude sent for each.
enum HeightBand {
  below30(20),
  from30to60(45),
  from60to120(90),
  above120(150),
  unknown(null);

  const HeightBand(this.altitudeM);
  final double? altitudeM;
}

/// Direction captured when the informant tapped "Lock direction".
class DirectionLock {
  const DirectionLock({required this.bearingDeg, required this.elevationDeg, required this.accuracy});

  final double bearingDeg;
  final double elevationDeg;

  /// Android sensor accuracy 0..3.
  final int accuracy;

  /// Bearing uncertainty sent to the server for each sensor accuracy level.
  double get bearingAccuracyDeg => switch (accuracy) {
        >= 3 => 8,
        2 => 12,
        1 => 20,
        _ => 35,
      };

  bool get calibrated => accuracy >= 2;

  factory DirectionLock.fromSample(OrientationSample s) => DirectionLock(
        bearingDeg: s.azimuthDeg % 360,
        elevationDeg: s.elevationDeg.clamp(-10, 90).toDouble(), // API range
        accuracy: s.accuracy,
      );
}

const _keep = Object();

class ReportDraft {
  const ReportDraft({
    required this.observedAt,
    this.step = ReportStep.aim,
    this.fix,
    this.locationProblem,
    this.lock,
    this.height,
    this.movement,
    this.droneCount,
    this.description = '',
    this.answers = const {},
    this.interviewVersion,
    this.media = const [],
    this.drones = const {},
    this.transports = const [],
    this.remoteIdSupported = false,
    this.remoteIdPermissionMissing = false,
    this.sending = false,
  });

  /// When the informant opened the flow: the sighting time.
  final DateTime observedAt;
  final ReportStep step;
  final LocationFix? fix;
  final LocationProblem? locationProblem;
  final DirectionLock? lock;
  final HeightBand? height;
  final String? movement;
  final int? droneCount;
  final String description;

  /// Structured interview answers (question id -> option value) and the version they belong to.
  final Map<String, String> answers;
  final String? interviewVersion;

  /// aerial unless the informant said otherwise.
  String get domain => answers['domain'] ?? 'aerial';
  final List<CapturedMedia> media;

  /// Remote ID drones heard during this report, by source address.
  final Map<String, RemoteIdDrone> drones;
  final List<String> transports;
  final bool remoteIdSupported;
  final bool remoteIdPermissionMissing;
  final bool sending;

  bool get canSend => fix != null && !sending;

  ReportDraft copyWith({
    ReportStep? step,
    Object? fix = _keep,
    Object? locationProblem = _keep,
    Object? lock = _keep,
    Object? height = _keep,
    Object? movement = _keep,
    Object? droneCount = _keep,
    String? description,
    Map<String, String>? answers,
    String? interviewVersion,
    List<CapturedMedia>? media,
    Map<String, RemoteIdDrone>? drones,
    List<String>? transports,
    bool? remoteIdPermissionMissing,
    bool? sending,
  }) =>
      ReportDraft(
        observedAt: observedAt,
        step: step ?? this.step,
        fix: identical(fix, _keep) ? this.fix : fix as LocationFix?,
        locationProblem: identical(locationProblem, _keep) ? this.locationProblem : locationProblem as LocationProblem?,
        lock: identical(lock, _keep) ? this.lock : lock as DirectionLock?,
        height: identical(height, _keep) ? this.height : height as HeightBand?,
        movement: identical(movement, _keep) ? this.movement : movement as String?,
        droneCount: identical(droneCount, _keep) ? this.droneCount : droneCount as int?,
        description: description ?? this.description,
        answers: answers ?? this.answers,
        interviewVersion: interviewVersion ?? this.interviewVersion,
        media: media ?? this.media,
        drones: drones ?? this.drones,
        transports: transports ?? this.transports,
        remoteIdSupported: remoteIdSupported,
        remoteIdPermissionMissing: remoteIdPermissionMissing ?? this.remoteIdPermissionMissing,
        sending: sending ?? this.sending,
      );
}

/// State of one report being made. Starts GPS and the Remote ID scan as soon as the flow opens.
class ReportFlow extends Notifier<ReportDraft> {
  StreamSubscription<LocationFix>? _location;
  StreamSubscription<RemoteIdDrone>? _remoteId;
  bool _declinationSet = false;

  @override
  ReportDraft build() {
    final sensors = ref.watch(informantSensorsProvider);
    ref.onDispose(() {
      _location?.cancel();
      _remoteId?.cancel();
    });
    final draft = ReportDraft(observedAt: DateTime.now().toUtc(), remoteIdSupported: sensors.remoteIdSupported);
    // Subscriptions emit asynchronously, after build has returned the initial state.
    _startLocation(sensors);
    if (sensors.remoteIdSupported) _startRemoteId(sensors);
    return draft;
  }

  void _startLocation(InformantSensors sensors) {
    _location?.cancel();
    _location = sensors.locationFixes().listen(
      (fix) {
        if (state.fix?.manual ?? false) return;
        state = state.copyWith(fix: fix, locationProblem: null);
        if (!_declinationSet) {
          _declinationSet = true;
          sensors.setDeclinationLocation(fix).catchError((_) {});
        }
      },
      onError: (Object e) {
        if (state.fix != null) return;
        state = state.copyWith(
          locationProblem: e is LocationException ? e.problem : LocationProblem.unavailable,
        );
      },
    );
  }

  void _startRemoteId(InformantSensors sensors) {
    sensors.remoteIdTransports().then((t) {
      if (ref.mounted) state = state.copyWith(transports: t);
    });
    _remoteId = sensors.remoteIdDrones().listen(
      (d) => state = state.copyWith(drones: {...state.drones, d.sourceAddress: d}),
      onError: (Object e) {
        if (e is PlatformException && e.code == 'permission') {
          state = state.copyWith(remoteIdPermissionMissing: true);
        }
      },
    );
  }

  void retryLocation() {
    state = state.copyWith(locationProblem: null);
    _startLocation(ref.read(informantSensorsProvider));
  }

  void setManualLocation(LatLon p) =>
      state = state.copyWith(fix: LocationFix(position: p, at: DateTime.now().toUtc(), manual: true), locationProblem: null);

  void goTo(ReportStep step) => state = state.copyWith(step: step);

  void lockDirection(DirectionLock lock, {CapturedMedia? photo}) => state = state.copyWith(
        lock: lock,
        media: photo == null ? null : [...state.media.where((m) => m.slot != photo.slot), photo],
        step: ReportStep.details,
      );

  void skipAiming() => state = state.copyWith(lock: null, step: ReportStep.details);

  void setHeight(HeightBand? h) => state = state.copyWith(height: h);
  void setMovement(String? m) => state = state.copyWith(movement: m);
  void setDroneCount(int? n) => state = state.copyWith(droneCount: n);
  void setDescription(String text) => state = state.copyWith(description: text);

  /// Answer (or clear, with null) one interview question; answers that no longer apply are dropped.
  void answer(Interview iv, String questionId, String? value) {
    final next = Map<String, String>.of(state.answers);
    value == null ? next.remove(questionId) : next[questionId] = value;
    final pruned = iv.prune(next);
    final count = {'1': 1, '2': 2, '3plus': 3}[pruned['count']];
    final aerial = (pruned['domain'] ?? 'aerial') == 'aerial';
    state = state.copyWith(
      answers: pruned,
      interviewVersion: iv.version,
      droneCount: count,
      // Height and movement chips only describe things in the air.
      height: aerial ? state.height : null,
      movement: aerial ? state.movement : null,
    );
  }

  void addMedia(CapturedMedia m) => state = state.copyWith(media: [...state.media, m]);
  void removeMedia(String slot) => state = state.copyWith(media: state.media.where((m) => m.slot != slot).toList());

  /// Builds the metadata packet. Each call mints a new client_report_id and token secret.
  Future<ReportRequest> buildRequest({required String language}) async {
    final d = state;
    final fix = d.fix!;
    final config = ref.read(configProvider);
    final sensors = ref.read(informantSensorsProvider);
    final description = d.description.trim();
    return ReportRequest(
      clientReportId: const Uuid().v4(),
      tokenSecret: InformantStore.newSecret(),
      platform: sensors.platform,
      appVersion: config.appVersion,
      language: language,
      deviceId: await ref.read(informantStoreProvider).deviceId(),
      observedAt: d.observedAt,
      observer: fix.position,
      observerAccuracyM: fix.accuracyM,
      bearingDeg: d.lock?.bearingDeg,
      elevationDeg: d.lock?.elevationDeg,
      bearingAccuracyDeg: d.lock?.bearingAccuracyDeg,
      compassCalibrated: d.lock?.calibrated,
      craftDomain: d.answers['domain'],
      interviewVersion: d.answers.isEmpty ? null : d.interviewVersion,
      interview: d.answers.isEmpty ? null : d.answers,
      estAltitudeM: d.height?.altitudeM,
      movement: d.movement,
      droneCount: d.droneCount,
      description: description.isEmpty ? null : description,
      remoteId: [for (final drone in d.drones.values) RemoteIdMessage.fromJson(drone.toApiJson())],
      remoteIdTransports: d.transports,
      media: [for (final m in d.media) m.toDeclaration()],
      pushToken: ref.read(pushTokenProvider),
    );
  }

  Future<SendOutcome> send({required String language}) async {
    if (!state.canSend) return const SendQueued();
    state = state.copyWith(sending: true);
    try {
      final request = await buildRequest(language: language);
      final pending = PendingReport(request: request, media: state.media, createdAt: DateTime.now().toUtc());
      return await ref.read(reportSenderProvider).submit(pending);
    } finally {
      if (ref.mounted) state = state.copyWith(sending: false);
    }
  }
}

final reportFlowProvider = NotifierProvider.autoDispose<ReportFlow, ReportDraft>(ReportFlow.new);
