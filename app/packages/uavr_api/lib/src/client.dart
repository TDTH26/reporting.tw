import 'dart:convert';

import 'package:http/http.dart' as http;

import 'agency.dart';
import 'analytics.dart';
import 'atreides.dart';
import 'informant.dart';
import 'maritime.dart';
import 'geo.dart';
import 'json.dart';

class ApiException implements Exception {
  ApiException(this.status, this.message, [this.body]);
  final int status;
  final String message;
  final Object? body;

  bool get isNetwork => status == 0;
  bool get isRateLimited => status == 429;
  bool get isConflict => status == 409;
  bool get isUnauthorized => status == 401;

  @override
  String toString() => 'ApiException($status): $message';
}

typedef TokenProvider = Future<String?> Function();

/// Client for the reporting.tw API. Paths here are checked against the backend's
/// OpenAPI spec by `tool/check_api.dart` (melos run check-api).
class UavrApi {
  UavrApi(String baseUrl, {this.accessToken, http.Client? httpClient, this.timeout = const Duration(seconds: 20)})
    : baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
      _http = httpClient ?? http.Client();

  final String baseUrl;
  final TokenProvider? accessToken;
  final Duration timeout;
  final http.Client _http;

  Uri uri(String path, [Map<String, Object?>? query]) {
    final q = <String, String>{
      for (final e in (query ?? const {}).entries)
        if (e.value != null)
          e.key: e.value is DateTime ? (e.value as DateTime).toUtc().toIso8601String() : '${e.value}',
    };
    return Uri.parse('$baseUrl$path').replace(queryParameters: q.isEmpty ? null : q);
  }

  /// WebSocket URL for the live channel.
  Uri wsUri(String token) {
    final u = Uri.parse('$baseUrl/v1/ws');
    return u.replace(scheme: u.scheme == 'https' ? 'wss' : 'ws', queryParameters: {'token': token});
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, Object?>? query,
    Map<String, String>? headers,
    bool auth = true,
  }) async {
    final h = <String, String>{'Accept': 'application/json', ...?headers};
    if (body != null) h['Content-Type'] = 'application/json';
    if (auth && accessToken != null) {
      final t = await accessToken!();
      if (t != null) h['Authorization'] = 'Bearer $t';
    }
    final req = http.Request(method, uri(path, query))..headers.addAll(h);
    if (body != null) req.body = jsonEncode(body);
    http.Response res;
    try {
      res = await http.Response.fromStream(await _http.send(req).timeout(timeout));
    } catch (e) {
      throw ApiException(0, 'network error: $e');
    }
    final text = utf8.decode(res.bodyBytes);
    final decoded = text.isEmpty ? null : _tryJson(text);
    if (res.statusCode >= 400) {
      final detail = decoded is Map ? decoded['detail'] : null;
      final msg = detail is String ? detail : (detail is Map ? '${detail['message'] ?? detail}' : res.reasonPhrase);
      throw ApiException(res.statusCode, msg ?? 'HTTP ${res.statusCode}', decoded);
    }
    return decoded;
  }

  static Object? _tryJson(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return s;
    }
  }

  Future<dynamic> _get(String p, {Map<String, Object?>? query, Map<String, String>? headers, bool auth = true}) =>
      _send('GET', p, query: query, headers: headers, auth: auth);
  Future<dynamic> _post(String p, [Object? body, Map<String, String>? headers, bool auth = true]) =>
      _send('POST', p, body: body ?? const {}, headers: headers, auth: auth);
  Future<dynamic> _put(String p, Object body, [Map<String, String>? headers, bool auth = true]) =>
      _send('PUT', p, body: body, headers: headers, auth: auth);

  // ------------------------------------------------------------------ informant (anonymous)

  Future<ReportResponse> submitReport(ReportRequest r) async =>
      ReportResponse.fromJson(await _post('/v1/reports', r.toJson(), null, false) as Json);

  Map<String, String> _rt(String token) => {'X-Report-Token': token};

  Future<List<InformantCase>> informantCases(String token, {String? lang}) async => listOf(
    await _get('/v1/informant/cases', query: {'lang': lang}, headers: _rt(token), auth: false),
    InformantCase.fromJson,
  );

  Future<List<UploadTicket>> answerEvidenceRequest(
    String token,
    String requestId,
    List<MediaDeclaration> media,
  ) async => listOf(
    await _post(
      '/v1/informant/evidence-requests/$requestId/responses',
      {'media': media.map((m) => m.toJson()).toList()},
      _rt(token),
      false,
    ),
    UploadTicket.fromJson,
  );

  Future<void> registerPush(String token, String pushToken, {String platform = 'android', String? language}) => _put(
    '/v1/informant/push',
    compact({'push_token': pushToken, 'platform': platform, 'language': language}),
    _rt(token),
    false,
  );

  Future<List<Zone>> publicZones() async =>
      Zone.fromFeatureCollection(await _get('/v1/public/zones', auth: false) as Json);

  Future<Interview> interview(String lang) async =>
      Interview.fromJson(await _get('/v1/public/interview', query: {'lang': lang}, auth: false) as Json);

  Future<PublicConfig> publicConfig() async =>
      PublicConfig.fromJson(await _get('/v1/public/config', auth: false) as Json);

  // ------------------------------------------------------------------ staff login (built in)

  Future<StaffTokens> login(String username, String password, {String client = 'console'}) async =>
      StaffTokens.fromJson(
        await _post('/v1/auth/login', {'username': username, 'password': password, 'client': client}, null, false)
            as Json,
      );

  Future<StaffTokens> refreshSession(String refreshToken) async =>
      StaffTokens.fromJson(await _post('/v1/auth/refresh', {'refresh_token': refreshToken}, null, false) as Json);

  Future<void> logoutSession(String refreshToken) =>
      _post('/v1/auth/logout', {'refresh_token': refreshToken}, null, false);

  Future<void> changePassword(String current, String next) =>
      _post('/v1/auth/password', {'current_password': current, 'new_password': next});

  // ------------------------------------------------------------------ agency

  Future<Me> me() async => Me.fromJson(await _get('/v1/agency/me') as Json);

  Future<bool> setDuty(bool onDuty) async =>
      ((await _put('/v1/agency/me/duty', {'on_duty': onDuty})) as Json)['on_duty'] == true;

  Future<List<Desk>> desks() async => listOf(await _get('/v1/agency/desks'), Desk.fromJson);

  Future<List<RosterEntry>> roster({int? deskId}) async =>
      listOf(await _get('/v1/agency/roster', query: {'desk_id': deskId}), RosterEntry.fromJson);

  Future<List<Template>> templates() async => listOf(await _get('/v1/agency/templates'), Template.fromJson);

  Future<({int seq, List<CaseSummary> cases})> queue({String scope = 'desk', List<String>? states}) async {
    final j = await _get('/v1/agency/queue', query: {'scope': scope, 'states': states?.join(',')}) as Json;
    return (seq: toInt(j['seq']) ?? 0, cases: listOf(j['cases'], CaseSummary.fromJson));
  }

  Future<CaseDetail> caseDetail(String id) async => CaseDetail.fromJson(await _get('/v1/agency/cases/$id') as Json);

  Future<CaseDetail> caseByNumber(String number) async =>
      CaseDetail.fromJson(await _get('/v1/agency/cases/by-number/$number') as Json);

  Future<CaseSummary> _act(String id, String action, [Object? body]) async =>
      CaseSummary.fromJson(await _post('/v1/agency/cases/$id/$action', body) as Json);

  Future<CaseSummary> acknowledge(String id) => _act(id, 'acknowledge');
  Future<CaseSummary> investigate(String id) => _act(id, 'investigate');
  Future<CaseSummary> transfer(String id, int deskId, String reason) =>
      _act(id, 'transfer', {'desk_id': deskId, 'reason': reason});
  Future<CaseSummary> merge(String survivorId, String otherId, String reason) =>
      _act(survivorId, 'merge', {'other_case_id': otherId, 'reason': reason});
  Future<CaseSummary> setSeverity(String id, int severity, String reason) =>
      _act(id, 'severity', {'severity': severity, 'reason': reason});
  Future<CaseSummary> resolve(String id, String outcomeCode, {String? note}) =>
      _act(id, 'resolve', compact({'outcome_code': outcomeCode, 'note': note}));
  Future<CaseSummary> closeCase(String id) => _act(id, 'close');
  Future<CaseSummary> addNote(String id, String text, {bool defense = false}) =>
      _act(id, 'notes', {'text': text, 'defense': defense});
  Future<CaseSummary> assign(String id, String? userId) => _act(id, 'assign', {'user_id': userId});
  Future<CaseSummary> assignField(String id, List<String> userIds) => _act(id, 'field-assign', {'user_ids': userIds});

  Future<int> requestEvidence(String id, String templateCode) async =>
      toInt(
        ((await _post('/v1/agency/cases/$id/evidence-requests', {'template_code': templateCode}))
            as Json)['informants'],
      ) ??
      0;

  Future<({String url, String status, String? sha256})> evidenceUrl(String evidenceId) async {
    final j = await _get('/v1/agency/evidence/$evidenceId/url') as Json;
    return (url: '${j['url']}', status: '${j['status']}', sha256: j['sha256'] as String?);
  }

  Future<RegistryLookup> registry(String serial) async =>
      RegistryLookup.fromJson(await _get('/v1/agency/registry/${Uri.encodeComponent(serial)}') as Json);

  Future<List<CctvCamera>> cctvNear(LatLon p, {double radiusM = 3000}) async => listOf(
    await _get('/v1/agency/cctv', query: {'lat': p.lat, 'lon': p.lon, 'radius_m': radiusM}),
    CctvCamera.fromJson,
  );

  Future<({String? streamUrl, String? snapshotUrl})> cctvStream(String cameraId, {String? caseId}) async {
    final j = await _get('/v1/agency/cctv/$cameraId/stream', query: {'case_id': caseId}) as Json;
    return (streamUrl: j['stream_url'] as String?, snapshotUrl: j['snapshot_url'] as String?);
  }

  Future<LiveMap> liveMap({int minutes = 60, int vesselMinutes = 30}) async => LiveMap.fromJson(
    await _get('/v1/agency/map/live', query: {'minutes': minutes, 'vessel_minutes': vesselMinutes}) as Json,
  );

  // ------------------------------------------------------------------ response recommendations

  Future<({List<Recommendation> items, bool canAct})> caseRecommendations(String caseId) async {
    final j = await _get('/v1/agency/cases/$caseId/recommendations') as Json;
    return (items: listOf(j['recommendations'], Recommendation.fromJson), canAct: j['can_act'] == true);
  }

  Future<Recommendation> decideRecommendation(String caseId, int recId, String decision,
          {String? text, String? note}) async =>
      Recommendation.fromJson(await _post('/v1/agency/cases/$caseId/recommendations/$recId',
          compact({'decision': decision, 'text': text, 'note': note})) as Json);

  // ------------------------------------------------------------------ maritime behaviour alerts

  Future<({List<MaritimeAlert> alerts, Map<String, int> counts})> maritimeAlerts({
    String status = 'open,acknowledged',
    String? kind,
    String? sourceId,
    int minScore = 0,
  }) async {
    final j =
        await _get(
              '/v1/maritime/alerts',
              query: {'status': status, 'kind': kind, 'source_id': sourceId, 'min_score': minScore},
            )
            as Json;
    return (
      alerts: listOf(j['alerts'], MaritimeAlert.fromJson),
      counts: {for (final e in (obj(j['counts']) ?? const {}).entries) e.key: toInt(e.value) ?? 0},
    );
  }

  Future<MaritimeAlertDetail> maritimeAlert(int id) async =>
      MaritimeAlertDetail.fromJson(await _get('/v1/maritime/alerts/$id') as Json);

  Future<MaritimeAlert> maritimeDecide(int id, String status, {String? note, double? suppressHours}) async =>
      MaritimeAlert.fromJson(
        await _post(
              '/v1/maritime/alerts/$id/status',
              compact({'status': status, 'note': note, 'suppress_hours': suppressHours}),
            )
            as Json,
      );

  Future<void> maritimeNote(int id, String text) => _post('/v1/maritime/alerts/$id/notes', {'text': text});

  Future<MaritimeAlert> maritimeEscalate(int id) async =>
      MaritimeAlert.fromJson(await _post('/v1/maritime/alerts/$id/escalate') as Json);

  Future<List<AnomalySettingItem>> maritimeSettings() async =>
      listOf(await _get('/v1/maritime/settings'), AnomalySettingItem.fromJson);

  Future<List<AnomalySettingItem>> saveMaritimeSettings(Map<String, double> values) async =>
      listOf(await _put('/v1/maritime/settings', values), AnomalySettingItem.fromJson);

  Future<AnomalyEvaluation?> maritimeEvaluation() async {
    final j = await _get('/v1/maritime/evaluation');
    return j is Map ? AnomalyEvaluation.fromJson(j.cast<String, dynamic>()) : null;
  }

  Future<AnomalyEvaluation> runMaritimeEvaluation({bool resimulate = false}) async =>
      AnomalyEvaluation.fromJson(await _post('/v1/maritime/evaluation', {'resimulate': resimulate}) as Json);

  // ------------------------------------------------------------------ Atreides maritime sensor (MDA)

  Future<List<AtreidesBatch>> atreidesBatches() async =>
      listOf(await _get('/v1/atreides/batches'), AtreidesBatch.fromJson);

  Future<AtreidesSummary> atreidesSummary({int? batchId}) async =>
      AtreidesSummary.fromJson(await _get('/v1/atreides/summary', query: {'batch_id': batchId}) as Json);

  Future<List<AtreidesTrack>> atreidesTracks({
    int? batchId,
    String? role,
    int minPoints = 1,
    bool highConfidence = false,
    int limit = 6000,
  }) async => listOf(
    await _get(
      '/v1/atreides/tracks',
      query: {
        'batch_id': batchId,
        'role': role,
        'min_points': minPoints,
        'high_confidence': highConfidence ? 'true' : null,
        'limit': limit,
      },
    ),
    AtreidesTrack.fromJson,
  );

  Future<List<VideoFeedInfo>> videoFeeds() async =>
      listOf(await _get('/v1/agency/video-feeds'), VideoFeedInfo.fromJson);

  Future<({String? streamUrl, String? snapshotUrl})> videoFeedStream(String feedId, {String? caseId}) async {
    final j = await _get('/v1/agency/video-feeds/$feedId/stream', query: {'case_id': caseId}) as Json;
    return (streamUrl: j['stream_url'] as String?, snapshotUrl: j['snapshot_url'] as String?);
  }

  Future<List<Zone>> staffZones() async => Zone.fromFeatureCollection(await _get('/v1/agency/zones') as Json);

  // ------------------------------------------------------------------ field app

  Future<List<CaseSummary>> assignments() async => listOf(await _get('/v1/field/assignments'), CaseSummary.fromJson);

  Future<CaseDetail> fieldCase(String id) async => CaseDetail.fromJson(await _get('/v1/field/cases/$id') as Json);

  Future<void> postPosition(LatLon p, {double? accuracyM}) =>
      _post('/v1/field/position', compact({'lat': p.lat, 'lon': p.lon, 'accuracy_m': accuracyM}));

  Future<List<UploadTicket>> postFieldObservation(String caseId, Json body) async =>
      listOf(((await _post('/v1/field/cases/$caseId/observations', body)) as Json)['uploads'], UploadTicket.fromJson);

  // ------------------------------------------------------------------ analytics

  Map<String, Object?> _range(DateTime? from, DateTime? to) => {'from': from, 'to': to};

  Future<AnalyticsSummary> analyticsSummary({DateTime? from, DateTime? to}) async =>
      AnalyticsSummary(await _get('/v1/analytics/summary', query: _range(from, to)) as Json);

  Future<List<HotspotCell>> hotspots({
    DateTime? from,
    DateTime? to,
    double cellDeg = 0.01,
    int severityMin = 1,
    int? hour,
    int? dow,
  }) async => listOf(
    ((await _get(
          '/v1/analytics/hotspots',
          query: {..._range(from, to), 'cell_deg': cellDeg, 'severity_min': severityMin, 'hour': hour, 'dow': dow},
        ))
        as Json)['cells'],
    HotspotCell.fromJson,
  );

  Future<TimeOfDay> timeOfDay({DateTime? from, DateTime? to}) async =>
      TimeOfDay.fromJson(await _get('/v1/analytics/time-of-day', query: _range(from, to)) as Json);

  Future<List<StatRow>> zoneStats({DateTime? from, DateTime? to}) async =>
      listOf(await _get('/v1/analytics/zones', query: _range(from, to)), StatRow.new);

  Future<({List<StatRow> bySerial, List<StatRow> byOwner})> repeatOffenders({DateTime? from, DateTime? to}) async {
    final j = await _get('/v1/analytics/repeat-offenders', query: _range(from, to)) as Json;
    return (bySerial: listOf(j['by_serial'], StatRow.new), byOwner: listOf(j['by_owner'], StatRow.new));
  }

  Future<List<StatRow>> responseStats({DateTime? from, DateTime? to, String group = 'agency'}) async =>
      listOf(await _get('/v1/analytics/response', query: {..._range(from, to), 'group': group}), StatRow.new);

  Future<List<StatRow>> sourceQuality({DateTime? from, DateTime? to}) async =>
      listOf(await _get('/v1/analytics/source-quality', query: _range(from, to)), StatRow.new);

  // ------------------------------------------------------------------ admin

  Future<int> createZone(Zone z) async => toInt(((await _post('/v1/admin/zones', z.toAdminJson())) as Json)['id'])!;

  Future<void> updateZone(int id, Zone z) => _put('/v1/admin/zones/$id', z.toAdminJson());

  Future<void> upsertTemplate(Template t) => _put('/v1/admin/templates/${t.code}', t.toJson());

  Future<List<StatRow>> feedClients() async => listOf(await _get('/v1/admin/feed-clients'), StatRow.new);

  Future<({int id, String key})> createFeedClient(String name, List<String> sources, {int classification = 0}) async {
    final j =
        await _post('/v1/admin/feed-clients', {'name': name, 'sources': sources, 'classification': classification})
            as Json;
    return (id: toInt(j['id'])!, key: '${j['key']}');
  }

  Future<void> revokeFeedClient(int id) => _post('/v1/admin/feed-clients/$id/revoke');

  Future<List<StaffAccount>> users() async => listOf(await _get('/v1/admin/users'), StaffAccount.fromJson);

  Future<StaffAccount> createUser(StaffAccount u, String password) async => StaffAccount.fromJson(
    await _post('/v1/admin/users', {...u.toEditJson(), 'username': u.username, 'password': password}) as Json,
  );

  Future<StaffAccount> updateUser(StaffAccount u, {String? newPassword, bool? active}) async => StaffAccount.fromJson(
    await _put('/v1/admin/users/${u.id}', compact({...u.toEditJson(), 'password': newPassword, 'active': active}))
        as Json,
  );

  Future<List<AuditEntry>> audit({String? user, String? action, String? objectId, int limit = 200}) async => listOf(
    await _get('/v1/admin/audit', query: {'user': user, 'action': action, 'object_id': objectId, 'limit': limit}),
    AuditEntry.fromJson,
  );

  void dispose() => _http.close();
}
