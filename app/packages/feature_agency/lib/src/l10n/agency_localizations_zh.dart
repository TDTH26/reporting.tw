// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'agency_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AgencyL10nZh extends AgencyL10n {
  AgencyL10nZh([String locale = 'zh']) : super(locale);

  @override
  String get consoleSubtitle => '警政、民航及國防派遣席位專用，限政府網路使用。';

  @override
  String get signInAgency => '以機關帳號登入';

  @override
  String get signInHint => '帳號由所屬機關管理員建立，所有存取均留存紀錄。';

  @override
  String get requestAccount => '如需帳號，請寄信至 tdth@inxsoft.net 申請。';

  @override
  String get fileReportVia => '民眾通報請使用 https://reporting.tw/';

  @override
  String get signOut => '登出';

  @override
  String get noAccessTitle => '無派遣台使用權限';

  @override
  String get noAccessBody => '您的帳號未具派遣員、督導、全國指揮、分析或系統管理角色，請洽所屬機關管理員申請權限。';

  @override
  String get language => '語言';

  @override
  String get themeLight => '淺色主題';

  @override
  String get themeDark => '深色主題';

  @override
  String get liveConnected => '即時連線';

  @override
  String get liveConnecting => '連線中…';

  @override
  String get liveDisconnected => '離線';

  @override
  String get liveTooltip => '即時更新通道；離線時，重新連線後會自動同步案件清單。';

  @override
  String get onDuty => '值勤中';

  @override
  String get offDuty => '未值勤';

  @override
  String get onDutyTooltip => '派案會略過無人值勤的席位，值勤時請開啟。';

  @override
  String get roles => '角色';

  @override
  String get clearance => '安全等級';

  @override
  String get noDesk => '無派遣台';

  @override
  String get navQueue => '案件佇列';

  @override
  String get navLiveMap => '即時地圖';

  @override
  String get navDashboards => '統計分析';

  @override
  String get navAdmin => '系統管理';

  @override
  String get navAudit => '稽核紀錄';

  @override
  String get actionFailed => '操作失敗';

  @override
  String get open => '開啟';

  @override
  String get dismiss => '關閉提示';

  @override
  String get dismissAll => '全部關閉';

  @override
  String moreAlerts(int count) {
    return '另有 $count 則警示';
  }

  @override
  String get alertCreated => '新案件';

  @override
  String get alertSeverity => '嚴重度提升';

  @override
  String get alertRerouted => '改派至本席';

  @override
  String get alertRealert => '仍未受理';

  @override
  String get alertTransferred => '移轉至本席';

  @override
  String get stateNew => '新案';

  @override
  String get stateAcknowledged => '已受理';

  @override
  String get stateInvestigating => '處理中';

  @override
  String get stateResolved => '已處置';

  @override
  String get stateClosed => '已結案';

  @override
  String get stateMerged => '已合併';

  @override
  String get authLikelyAuthorized => '疑似已核准';

  @override
  String get authNoPermit => '無許可';

  @override
  String get authUnknown => '不明';

  @override
  String get classUnclassified => '一般';

  @override
  String get classRestricted => '限閱';

  @override
  String get classDefense => '國防機密';

  @override
  String get srcInformantAndroid => '民眾（Android App）';

  @override
  String get srcInformantWeb => '民眾（網頁）';

  @override
  String get srcFieldOfficer => '外勤員警';

  @override
  String get srcRemoteId => '遠端識別接收器';

  @override
  String get srcRfSensor => '射頻偵測器';

  @override
  String get srcMdaSensor => '海事感測器（MDA）';

  @override
  String get srcRadar => '雷達';

  @override
  String get reasonNearMannedAircraft => '鄰近有人航空器（ADS-B）';

  @override
  String get reasonZoneAirport => '位於機場管制區';

  @override
  String get reasonZoneMilitary => '位於軍事管制區';

  @override
  String get reasonZoneInfrastructure => '位於關鍵基礎設施區';

  @override
  String get reasonZoneOutlying => '位於金馬限制區域';

  @override
  String get reasonSensorRedZone => '感測器確認於紅區內飛行';

  @override
  String get reasonRestrictedNoPermit => '禁限航區內且無相符許可';

  @override
  String get reasonNoRemoteId => '管制空域內未發送遠端識別';

  @override
  String get reasonHovering => '於住宅區上空滯空';

  @override
  String get reasonValidPermit => '註冊資料相符且具有效許可';

  @override
  String get reasonSingleWebReport => '僅單一未驗證網頁通報';

  @override
  String get evCreated => '立案';

  @override
  String get evAcknowledged => '受理';

  @override
  String get evInvestigating => '開始處理';

  @override
  String get evResolved => '處置完成';

  @override
  String get evClosed => '結案';

  @override
  String get evRerouted => '逾時未受理，改派';

  @override
  String get evTransferred => '移轉';

  @override
  String get evMerged => '併入其他案件';

  @override
  String get evMergedFrom => '併入他案';

  @override
  String get evSeverityUpgraded => '嚴重度提升';

  @override
  String get evSeverityDowngraded => '嚴重度調降';

  @override
  String get evAssigned => '承辦人變更';

  @override
  String get evFieldAssigned => '派遣外勤員警';

  @override
  String get evEvidenceRequested => '向通報人調閱證據';

  @override
  String get evEvidenceReceived => '收到證據';

  @override
  String get evObservationAdded => '新增觀測資料';

  @override
  String get evNote => '備註';

  @override
  String get evRedactedCopySent => '已傳送遮蔽版本';

  @override
  String get hashVerified => '雜湊相符';

  @override
  String get hashMismatch => '雜湊不符';

  @override
  String get hashPending => '待驗證';

  @override
  String get scopeDesk => '本席';

  @override
  String get scopeAgency => '本機關';

  @override
  String get scopeAll => '全部';

  @override
  String caseCount(int count) {
    return '$count 件';
  }

  @override
  String get refresh => '重新整理';

  @override
  String get keyboardHelp => '鍵盤：↑/↓ 選取、A 受理、Enter 開啟';

  @override
  String acknowledged(String number) {
    return '$number 已受理';
  }

  @override
  String get fitAll => '全部顯示';

  @override
  String get zoomIn => '放大';

  @override
  String get zoomOut => '縮小';

  @override
  String get queueEmpty => '沒有符合篩選條件的案件。';

  @override
  String get colSeverity => '嚴重度';

  @override
  String get colCase => '案號';

  @override
  String get colState => '狀態';

  @override
  String get colAck => '受理時限';

  @override
  String get colAge => '經過';

  @override
  String get colObservations => '觀測/通報人';

  @override
  String get colConfidence => '可信度';

  @override
  String get colSignals => '訊號';

  @override
  String get colAuthorization => '許可狀態';

  @override
  String get redactedRow => '遮蔽：本席安全等級不足';

  @override
  String get redactedShort => '已遮蔽';

  @override
  String get sensorConfirmed => '感測器確認';

  @override
  String get remoteId => '遠端識別';

  @override
  String get readOnly => '唯讀';

  @override
  String get actAcknowledge => '受理';

  @override
  String get actInvestigate => '開始處理';

  @override
  String get actTransfer => '移轉';

  @override
  String get actMerge => '合併';

  @override
  String get actSeverity => '調整嚴重度';

  @override
  String get actRequestEvidence => '調閱證據';

  @override
  String get actAssignField => '派遣外勤';

  @override
  String get actResolve => '處置完成';

  @override
  String get actClose => '結案';

  @override
  String get actNote => '新增備註';

  @override
  String get transferred => '案件已移轉';

  @override
  String get merged => '案件已合併';

  @override
  String get resolved => '案件已處置';

  @override
  String get fieldAssigned => '外勤派遣已更新';

  @override
  String get noteAdded => '備註已新增';

  @override
  String evidenceRequested(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已向 $count 位通報人送出調閱',
      zero: '本案無可通知的通報人',
    );
    return '$_temp0';
  }

  @override
  String closeConfirm(String number) {
    return '確定將 $number 結案？結案後即無法再變更。';
  }

  @override
  String get targetDesk => '移轉席位';

  @override
  String get required => '必填';

  @override
  String get reason => '理由';

  @override
  String get reasonRequired => '請填寫理由';

  @override
  String transferHint(String classification) {
    return '僅列出符合本案等級（$classification）的席位。案件將以新案移入並重新起算受理時限，原機關保留閱覽權限。';
  }

  @override
  String mergeHint(String number) {
    return '選擇要併入 $number 的案件，其觀測資料與通報人將一併移轉，並標示為已合併。';
  }

  @override
  String get mergeNoCandidates => '佇列中無其他未結案件。';

  @override
  String get nearby => '鄰近';

  @override
  String get mergeChoose => '請選擇案件';

  @override
  String get mergeReasonHint => '例如：同一架無人機';

  @override
  String get currentSeverity => '目前';

  @override
  String get severityUnchanged => '請選擇不同等級';

  @override
  String get downgradeReasonRequired => '調降嚴重度必須填寫理由';

  @override
  String get reasonMandatory => '理由（必填）';

  @override
  String get reasonOptional => '理由（選填）';

  @override
  String get downgradeExplain => '系統只會自動提升嚴重度；調降須由人員判斷，並記錄您的姓名與理由。';

  @override
  String get upgradeExplain => '提升嚴重度會重新警示席位，並以較短時限重新起算受理時間。';

  @override
  String get send => '送出';

  @override
  String get noTemplates => '無可用範本。';

  @override
  String get evidenceRequestHint => '通報人僅會收到此範本訊息（以其語言顯示），無法傳送自由文字。';

  @override
  String get noFieldOfficers => '本機關無外勤員警。';

  @override
  String get lastPosition => '最後位置';

  @override
  String get outcome => '處置結果';

  @override
  String get countsAsFalseReport => '列為不實通報';

  @override
  String get internalNote => '內部備註';

  @override
  String get internalNoteHint => '不會顯示給通報人';

  @override
  String get resolveInformantHint => '通報人僅會看到處置結果範本文字。';

  @override
  String get defenseOutcomeHint => '國防案件：無論選擇何種結果，通報人一律只會看到「已由相關權責機關處理」。';

  @override
  String get noteText => '備註內容';

  @override
  String get noteInternalHint => '內部使用，僅可檢視本案之人員可見';

  @override
  String get defenseNote => '國防備註（加密）';

  @override
  String get defenseNoteHint => '加密儲存，僅國防等級人員可閱覽';

  @override
  String get panelMap => '地圖';

  @override
  String get operator => '操作人';

  @override
  String get estError => '位置誤差';

  @override
  String get altitude => '高度';

  @override
  String get positionSource => '定位來源';

  @override
  String get panelIncident => '事件資訊';

  @override
  String get severityReasons => '嚴重度判定依據';

  @override
  String get firstSeen => '首次發現';

  @override
  String get lastSeen => '最後發現';

  @override
  String get informantsObservations => '通報人 / 觀測筆數';

  @override
  String get confidence => '可信度';

  @override
  String get none => '無';

  @override
  String get permit => '飛航許可';

  @override
  String get noPermitMatched => '無相符許可';

  @override
  String get permitNo => '許可文號';

  @override
  String get operatorName => '操作人／單位';

  @override
  String get validity => '有效期間';

  @override
  String get maxAltitude => '最高高度';

  @override
  String get registryMatch => '註冊資料比對';

  @override
  String get noRegistryMatch => '無相符註冊資料';

  @override
  String get serial => '序號';

  @override
  String get model => '機型';

  @override
  String get registryStatus => '註冊狀態';

  @override
  String get lookUpRegistry => '查詢註冊資料';

  @override
  String get auditedNotice => '註冊查詢會顯示所有人資料，並記錄於稽核紀錄。';

  @override
  String get weather => '氣象';

  @override
  String get visibility => '能見度';

  @override
  String get wind => '風';

  @override
  String get station => '測站';

  @override
  String get adsbNearby => '鄰近 ADS-B 航空器';

  @override
  String get registryLookup => '註冊資料';

  @override
  String get registered => '已註冊';

  @override
  String get notRegistered => '未註冊';

  @override
  String get registrationNo => '註冊編號';

  @override
  String get owner => '所有人';

  @override
  String get ownerRef => '所有人識別碼';

  @override
  String get mtow => '最大起飛重量';

  @override
  String get permits => '飛航許可';

  @override
  String get noStream => '此攝影機無串流或快照網址。';

  @override
  String get panelCctv => '監視器';

  @override
  String get findCameras => '搜尋附近監視器';

  @override
  String get cctvHint => '搜尋推估位置 3 公里內之監視器。';

  @override
  String get noCameras => '附近無監視器。';

  @override
  String get openStream => '開啟影像';

  @override
  String get cctvAudited => '每次調閱監視器皆會連同本案記錄於稽核紀錄。';

  @override
  String get panelObservations => '觀測資料';

  @override
  String get bearing => '方位';

  @override
  String get elevation => '仰角';

  @override
  String get gpsAccuracy => 'GPS 精度';

  @override
  String get spamScore => '濫報分數';

  @override
  String get fidelity => '資料品質';

  @override
  String get attestation => '裝置驗證';

  @override
  String get machineTranslation => '機器翻譯';

  @override
  String get view => '檢視';

  @override
  String get notUploaded => '尚未上傳';

  @override
  String get captured => '拍攝';

  @override
  String get imageFailed => '影像無法載入';

  @override
  String get panelTimeline => '處理歷程';

  @override
  String mergedInto(String number) {
    return '併入 $number';
  }

  @override
  String mergedFrom(String number) {
    return '來自 $number';
  }

  @override
  String get template => '範本';

  @override
  String officersCount(int count) {
    return '$count 名員警';
  }

  @override
  String get defenseNoteAdded => '國防備註（加密）';

  @override
  String get system => '系統';

  @override
  String get user => '人員';

  @override
  String get defenseNotes => '國防備註';

  @override
  String get ackDue => '受理倒數';

  @override
  String get desk => '席位';

  @override
  String get mergedNotice => '本案已併入其他案件。';

  @override
  String get openSurvivor => '開啟存續案件';

  @override
  String get redactedNotice => '已遮蔽：您的安全等級不足以檢視本案，僅顯示位置、時間及嚴重度。';

  @override
  String readOnlyNotice(String desk) {
    return '唯讀：本案由$desk承辦，僅該席位或其機關督導可進行處理。';
  }

  @override
  String get assignedOfficers => '已派遣外勤員警';

  @override
  String get noPosition => '尚無位置';

  @override
  String get redactedTitle => '遮蔽案件';

  @override
  String get redactedExplain =>
      '本案密等高於您的安全等級，系統僅提供遮蔽版本，讓您知悉該地點有狀況發生，並由具權限之席位處理。觀測資料、證據及通報人資料均不予顯示。';

  @override
  String get severity => '嚴重度';

  @override
  String get location => '位置';

  @override
  String get layerZones => '管制區';

  @override
  String get layerAircraft => '航空器';

  @override
  String get layerOfficers => '外勤員警';

  @override
  String get layerRecentClosed => '近期已結';

  @override
  String liveMapCounts(int cases, int aircraft, int officers) {
    return '$cases 件 · $aircraft 架航空器 · $officers 名員警';
  }

  @override
  String get openCase => '開啟案件';

  @override
  String lastNDays(int days) {
    return '$days 天';
  }

  @override
  String get customRange => '自訂';

  @override
  String get kpiIncidents => '事件數';

  @override
  String kpiObservations(int count) {
    return '$count 筆觀測';
  }

  @override
  String get kpiAuthorizedShare => '核准比例';

  @override
  String get kpiRemoteIdCoverage => '遠端識別涵蓋率';

  @override
  String get kpiSensorConfirmed => '感測器確認';

  @override
  String get kpiFalseReports => '不實通報';

  @override
  String get kpiAckP50 => '受理時間（中位數）';

  @override
  String get kpiAckP90 => '受理時間（P90）';

  @override
  String get minSec => '分:秒';

  @override
  String get hotspots => '熱點分布';

  @override
  String get allSeverities => '所有嚴重度';

  @override
  String get allHours => '所有時段';

  @override
  String get allDays => '每日';

  @override
  String hotspotLegend(int cells, int incidents) {
    return '$cells 個網格 · $incidents 件事件；圓越大越紅表示事件越多。';
  }

  @override
  String get dowMon => '週一';

  @override
  String get dowTue => '週二';

  @override
  String get dowWed => '週三';

  @override
  String get dowThu => '週四';

  @override
  String get dowFri => '週五';

  @override
  String get dowSat => '週六';

  @override
  String get dowSun => '週日';

  @override
  String get timeOfDay => '時段分布（臺北時間）';

  @override
  String timeOfDayHint(int max) {
    return '顏色越深表示事件越多（單一時段最多 $max 件），游標移至格子可查看數量。';
  }

  @override
  String incidentsN(int count) {
    return '$count 件';
  }

  @override
  String get zonesAuthorization => '各管制區核准與未核准比較';

  @override
  String get noData => '此期間無資料。';

  @override
  String get zone => '區域';

  @override
  String get zoneType => '類型';

  @override
  String get responsePerformance => '處理效能';

  @override
  String get byAgency => '依機關';

  @override
  String get byDesk => '依席位';

  @override
  String get ackP50Minutes => '受理中位數（分）';

  @override
  String get ackP90Minutes => '受理 P90（分）';

  @override
  String get agency => '機關';

  @override
  String get cases => '案件數';

  @override
  String get ackP50 => '受理中位數';

  @override
  String get ackP90 => '受理 P90';

  @override
  String get resolveP50 => '處置中位數';

  @override
  String get rerouteRate => '改派率';

  @override
  String get unackedRate => '未受理率';

  @override
  String get sourceQuality => '來源品質';

  @override
  String get source => '來源';

  @override
  String get sensorConfirmedShare => '感測器確認比例';

  @override
  String get falseReportRate => '不實通報率';

  @override
  String get repeatOffenders => '重複違規';

  @override
  String get bySerial => '依遠端識別序號';

  @override
  String get byOwner => '依註冊所有人';

  @override
  String get unauthorized => '未核准';

  @override
  String get caseNumbers => '案號';

  @override
  String get drones => '機數';

  @override
  String get repeatOffendersAudited => '檢視重複違規資料會記錄於稽核紀錄。';

  @override
  String get search => '搜尋';

  @override
  String get newZone => '新增區域';

  @override
  String get editZone => '編輯區域';

  @override
  String get published => '公開';

  @override
  String get publishedHint => '於民眾端 App 顯示（僅限民航局公告區域）';

  @override
  String get selectZone => '請選擇區域或新增區域。';

  @override
  String get saved => '已儲存';

  @override
  String get zoneFieldsRequired => '代碼及中英文名稱為必填';

  @override
  String get zoneNeedsPolygon => '請在地圖上至少點選三個頂點';

  @override
  String get undo => '復原';

  @override
  String get clear => '清除';

  @override
  String vertexHelp(int count) {
    return '$count 個頂點 · 點地圖新增、拖曳移動、長按刪除';
  }

  @override
  String get code => '代碼';

  @override
  String get nameEn => '名稱（英文）';

  @override
  String get nameZh => '名稱（中文）';

  @override
  String get classification => '密等';

  @override
  String get priority => '優先順序';

  @override
  String get primaryDesk => '主責席位';

  @override
  String get backupChain => '備援順序';

  @override
  String get addBackupDesk => '新增備援席位';

  @override
  String get backupChainHint => '逾時未受理之案件依序改派，最終一律由全國總機席位承接。';

  @override
  String get ackTimeouts => '受理時限（秒，空白為預設）';

  @override
  String get defaultValue => '預設';

  @override
  String get tabZones => '區域與派案';

  @override
  String get tabTemplates => '訊息範本';

  @override
  String get tabFeedClients => '資料介接';

  @override
  String get templatesHint => '範本是通報人唯一會收到的訊息，每個範本須提供六種語言。';

  @override
  String get newTemplate => '新增範本';

  @override
  String get editTemplate => '編輯範本';

  @override
  String get outcomeTemplates => '處置結果';

  @override
  String get evidenceTemplates => '證據調閱';

  @override
  String get languages => '語言';

  @override
  String get allLanguagesRequired => '六種語言皆為必填。';

  @override
  String get feedClientsHint => '感測器、遠端識別、ADS-B、氣象、註冊、許可及監視器資料介接金鑰。';

  @override
  String get newFeedClient => '新增介接端';

  @override
  String get name => '名稱';

  @override
  String get sources => '資料來源';

  @override
  String get status => '狀態';

  @override
  String get lastUsed => '最後使用';

  @override
  String get active => '啟用';

  @override
  String get revoke => '撤銷';

  @override
  String get revoked => '已撤銷';

  @override
  String revokeConfirm(String name) {
    return '確定撤銷 $name 的金鑰？該資料介接將立即停止。';
  }

  @override
  String get feedKeyTitle => '介接金鑰';

  @override
  String get feedKeyOnce => '此金鑰僅顯示一次，請立即存放於介接系統的機密儲存區。';

  @override
  String get copy => '複製';

  @override
  String get copied => '已複製';

  @override
  String get keyStored => '我已妥善保存金鑰';

  @override
  String get auditUser => '使用者';

  @override
  String get auditActionPrefix => '動作（前綴）';

  @override
  String get auditObjectId => '物件 ID';

  @override
  String get apply => '套用';

  @override
  String get auditViewAudited => '檢視稽核紀錄本身亦會被記錄。';

  @override
  String get time => '時間';

  @override
  String get auditAction => '動作';

  @override
  String get auditObject => '物件';

  @override
  String get details => '詳細資料';

  @override
  String get domainAerial => '空中';

  @override
  String get domainSurface => '水面';

  @override
  String get domainSubsurface => '水下';

  @override
  String get domainShore => '岸際';

  @override
  String get domainUnknown => '類別不明';

  @override
  String get craftUavMultirotor => '多旋翼無人機';

  @override
  String get craftUavFixedWing => '固定翼無人機';

  @override
  String get craftUav => '無人機';

  @override
  String get craftBalloon => '氣球／飛艇';

  @override
  String get craftUsv => '無人水面載具（USV）';

  @override
  String get craftSmallBoat => '小艇';

  @override
  String get craftFishingVessel => '漁船';

  @override
  String get craftShip => '船舶';

  @override
  String get craftVessel => '船隻';

  @override
  String get craftSubmarine => '潛艦（潛望鏡／桅杆）';

  @override
  String get craftUuv => '無人水下載具';

  @override
  String get craftLandedBoat => '船隻搶灘／靠岸';

  @override
  String get craftObjectAshore => '不明物體漂上岸';

  @override
  String get craftUnknownSubsurface => '不明水下目標';

  @override
  String get panelAi => 'AI 初判（僅供參考）';

  @override
  String get aiAdvisoryNote => '僅供參考：模型最多將嚴重度提高一級，須有佐證才會升為緊急，且不會降級或結案。';

  @override
  String get aiThreat => '威脅研判';

  @override
  String get aiCraft => '辨識結果';

  @override
  String get aiSilhouette => '外形描述';

  @override
  String get aiUnmanned => '無人載具可能性';

  @override
  String get aiSpam => '無關影像可能性';

  @override
  String get aiConfidence => '模型信心';

  @override
  String get aiMatchesReport => '與通報內容一致';

  @override
  String get aiModel => '模型';

  @override
  String get aiNone => '尚無 AI 研判（照片上傳後才會分析）。';

  @override
  String get panelMaritime => '海上態勢';

  @override
  String get vesselAis => 'AIS 船舶';

  @override
  String get darkVessel => '疑似關閉 AIS：此海域有 AIS 涵蓋，但目標附近無船舶訊號';

  @override
  String get noAisCoverage => '此海域無 AIS 涵蓋';

  @override
  String get mdaTrack => '海域感知目標（未識別）';

  @override
  String get interviewAnswers => '通報人問答';

  @override
  String get craftDomain => '類別';

  @override
  String get layerVessels => '船舶（AIS／海域感知）';

  @override
  String get layerCameras => '影像來源';

  @override
  String get videoFeeds => '影像來源';

  @override
  String get reasonSubsurface => '水下目標';

  @override
  String get reasonPeopleUnloading => '有人搬運物品上岸';

  @override
  String get reasonCraftLanded => '載具靠岸／搶灘';

  @override
  String get reasonUsv => '無人水面載具';

  @override
  String get reasonUsvProtected => '無人艇位於管制／防護水域';

  @override
  String get reasonUsvApproaching => '無人艇正接近岸際';

  @override
  String get reasonDarkProtected => '關閉 AIS 船隻位於防護水域';

  @override
  String get reasonDarkTerritorial => '關閉 AIS 船隻位於領海';

  @override
  String get reasonUnidentifiedRestricted => '限制水域內不明船隻';

  @override
  String get reasonVesselRestricted => '船隻進入限制水域';

  @override
  String get reasonUnidentifiedProtected => '防護水域內不明載具';

  @override
  String get reasonAi => 'AI 研判（參考）';

  @override
  String get zoneDomains => '適用類別';

  @override
  String get loginUsername => '帳號';

  @override
  String get loginPassword => '密碼';

  @override
  String get loginWrongCredentials => '帳號或密碼錯誤。';

  @override
  String get loginLocked => '登入失敗次數過多，帳號已鎖定 15 分鐘。';

  @override
  String get loginTooMany => '此網路登入嘗試過多，請稍後再試。';

  @override
  String get tabUsers => '使用者';

  @override
  String get newUser => '新增使用者';

  @override
  String get editUser => '編輯使用者';

  @override
  String get usersHint => '主控台與外勤 App 的人員帳號。密碼至少 12 個字元。';

  @override
  String get displayName => '顯示名稱';

  @override
  String get fieldUnitLabel => '國防外勤單位';

  @override
  String get initialPassword => '初始密碼';

  @override
  String get resetPassword => '新密碼（留空則不變更）';

  @override
  String get deactivate => '停用';

  @override
  String get reactivate => '重新啟用';

  @override
  String get deactivated => '已停用';

  @override
  String get lockedLabel => '鎖定中';

  @override
  String get lastSeenLabel => '最後上線';

  @override
  String get userSaved => '已儲存';

  @override
  String get navAtreides => 'Atreides';

  @override
  String get atreidesTitle => 'Atreides 海事感測';

  @override
  String get atreidesSubtitle =>
      'Atreides 提供的非合作式海域偵測（MDA）。這不是 AIS：沒有船舶身分、航速或航向。每筆偵測分類為移動目標、固定設施或不明。';

  @override
  String get atreidesAllBatches => '全部匯入';

  @override
  String get atreidesAllRoles => '全部';

  @override
  String get atreidesDetections => '偵測';

  @override
  String get atreidesTracks => '航跡';

  @override
  String atreidesTrackSplit(int routes, int singles) {
    final intl.NumberFormat routesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String routesString = routesNumberFormat.format(routes);
    final intl.NumberFormat singlesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String singlesString = singlesNumberFormat.format(singles);

    return '$routesString 條航線 · $singlesString 個單點目標';
  }

  @override
  String get atreidesRoleMobile => '移動目標';

  @override
  String get atreidesRoleFixed => '固定設施';

  @override
  String get atreidesRoleAmbiguous => '不明';

  @override
  String get atreidesPeriod => '期間';

  @override
  String get atreidesHighConfidence => '僅顯示高可信度';

  @override
  String get atreidesRoutesOnly => '僅顯示航線';

  @override
  String atreidesTrackFacts(int count, String km) {
    return '$count 筆偵測 · $km 公里';
  }

  @override
  String get atreidesSingleContact => '單點目標';

  @override
  String atreidesSourceView(String role, String confidence, String reasoning) {
    return '來源感測器：$role（$confidence）— $reasoning';
  }

  @override
  String get atreidesEmpty => '尚未匯入 Atreides 資料。';

  @override
  String atreidesShowing(int shown, int total) {
    return '顯示 $shown / $total';
  }

  @override
  String atreidesConfidence(String level) {
    return '$level可信度';
  }

  @override
  String get atreidesConfHigh => '高';

  @override
  String get atreidesConfLow => '低';

  @override
  String get consoleTitle => 'Reporting.tw：監控可疑空中及水域活動通報';

  @override
  String get navMaritime => '海事警示';

  @override
  String get maritimeTitle => '海上異常行為警示';

  @override
  String get maritimeSubtitle =>
      '來自 AIS、Atreides 與模擬航跡的異常停留、偏離航道、海上會合、回報中斷及進入保護水域。供人員判讀：警示不等於定論。';

  @override
  String get tabAlerts => '警示';

  @override
  String get tabThresholds => '門檻設定';

  @override
  String get tabEvaluation => '規則與統計比較';

  @override
  String get maritimeStatusOpen => '待處理';

  @override
  String get maritimeStatusAcknowledged => '已確認';

  @override
  String get maritimeStatusFalseAlarm => '誤報';

  @override
  String get maritimeStatusDismissed => '已撤銷';

  @override
  String get maritimeStatusEscalated => '已轉為案件';

  @override
  String get maritimeStatusReopened => '重新開啟';

  @override
  String get maritimeShowClosed => '顯示已結束';

  @override
  String get maritimeAllKinds => '全部行為';

  @override
  String get kindStop => '停留／徘徊';

  @override
  String get kindDeviation => '偏離常用航道';

  @override
  String get kindCluster => '船舶會合';

  @override
  String get kindZoneEntry => '進入保護水域';

  @override
  String get kindApproach => '接近保護水域';

  @override
  String get kindGap => '回報中斷';

  @override
  String get kindStatistical => '統計異常';

  @override
  String get methodRules => '規則';

  @override
  String get methodStat => '統計';

  @override
  String get methodBoth => '規則＋統計';

  @override
  String maritimeRisk(int score) {
    return '風險 $score';
  }

  @override
  String maritimeQuality(int pct) {
    return '資料品質 $pct%';
  }

  @override
  String get maritimeWhy => '警示原因';

  @override
  String get maritimeUncertainty => '不確定性';

  @override
  String get maritimeTimeline => '時間軸';

  @override
  String maritimeValue(String value, String threshold) {
    return '量測 $value · 門檻 $threshold';
  }

  @override
  String get maritimeAck => '確認';

  @override
  String get maritimeFalseAlarm => '標記誤報';

  @override
  String get maritimeDismiss => '撤銷';

  @override
  String get maritimeReopen => '重新開啟';

  @override
  String get maritimeEscalate => '轉為案件';

  @override
  String get maritimeOpenCase => '開啟案件';

  @override
  String get maritimeAddNote => '新增備註';

  @override
  String get maritimeNoteHint => '時間軸備註';

  @override
  String get maritimeSuppressHours => '靜默時數';

  @override
  String get maritimeFalseAlarmTitle => '標記為誤報';

  @override
  String get maritimeNone => '沒有符合的警示。';

  @override
  String get maritimeSelect => '選擇警示以查看原因。';

  @override
  String get maritimeSave => '儲存並重新偵測';

  @override
  String get maritimeSaved => '門檻已儲存並重新偵測。';

  @override
  String maritimeDefault(String value) {
    return '預設 $value';
  }

  @override
  String get maritimeReadOnly => '僅督導及管理員可變更門檻。';

  @override
  String evalIntro(int tracks, int anomalous) {
    return '臺灣周邊模擬航行並標記異常行為：共檢查 $tracks 條航跡，其中 $anomalous 條異常。精確率：警示中確為異常的比例；召回率：異常被找出的比例。';
  }

  @override
  String get evalMethod => '方法';

  @override
  String get evalPrecision => '精確率';

  @override
  String get evalRecall => '召回率';

  @override
  String get evalF1 => 'F1';

  @override
  String get evalFalseAlarms => '每百條正常航跡誤報數';

  @override
  String get evalCombined => '綜合風險分數（操作人員所見）';

  @override
  String get evalByKind => '各類注入行為偵測數';

  @override
  String get evalRun => '重新比較';

  @override
  String get evalResimulate => '重新產生模擬航行';

  @override
  String get evalNone => '尚無比較結果。';

  @override
  String evalRanAt(String when) {
    return '執行時間 $when';
  }

  @override
  String get eventDetected => '偵測';

  @override
  String get eventUpdated => '更新';

  @override
  String get eventNote => '備註';

  @override
  String get maritimeSourceSim => '模擬';

  @override
  String get maritimeSourceAtreides => 'Atreides';

  @override
  String get evRecommendation => '已處理建議';

  @override
  String get recTitle => '建議行動';

  @override
  String get recIntro => '僅為決策輔助，不會控制任何裝置。接受派遣外勤人員會將該員指派至本案；其他行動為模擬並留存紀錄。';

  @override
  String get recAccept => '接受';

  @override
  String get recReject => '拒絕';

  @override
  String get recModify => '修改';

  @override
  String get recModifyTitle => '修改建議';

  @override
  String get recNewText => '實際執行內容';

  @override
  String get recNote => '備註（選填）';

  @override
  String get recAccepted => '已接受';

  @override
  String get recRejected => '已拒絕';

  @override
  String get recModified => '已修改';

  @override
  String recBy(String who, String when) {
    return '$who，$when';
  }

  @override
  String get recNone => '本案目前沒有建議。';

  @override
  String get recReadOnly => '僅由承辦本案的席位決定。';

  @override
  String get navCctv => '監視器';

  @override
  String get cctvTitle => '監視器目標追蹤';

  @override
  String get cctvSubtitle =>
      '以 AI 影像分析（Featherless AI）在監視器畫面中持續追蹤的無人機與船隻。僅供參考：每條追蹤都由人員審查。';

  @override
  String get cctvCameras => '監視器';

  @override
  String get cctvTracks => '追蹤';

  @override
  String get cctvNoTracks => '未偵測到可疑活動。';

  @override
  String get cctvNoCameras => '尚未連接任何監視器。';

  @override
  String get cctvInactive => '停用';

  @override
  String cctvLastSample(String time) {
    return '最後畫面 $time';
  }

  @override
  String cctvTrackFacts(int hits, String from, String to) {
    return '$hits 個畫面 · $from – $to';
  }

  @override
  String get cctvFrameLegend => '最後畫面：追蹤路徑（橘色）、偵測框與警戒區（紅色）';

  @override
  String get cctvNoFrame => '此追蹤沒有儲存的畫面。';

  @override
  String cctvOpenCase(String number) {
    return '開啟案件 $number';
  }

  @override
  String get cctvTrackActive => '追蹤中';

  @override
  String get cctvTrackLost => '已失去目標';

  @override
  String get cctvBehLoiter => '滯留';

  @override
  String get cctvBehApproaching => '接近中';

  @override
  String get cctvBehFast => '快速移動';

  @override
  String get cctvBehZone => '警戒區';

  @override
  String cctvOpenCases(int count) {
    return '$count 件未結案件';
  }
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AgencyL10nZhTw extends AgencyL10nZh {
  AgencyL10nZhTw() : super('zh_TW');

  @override
  String get consoleSubtitle => '警政、民航及國防派遣席位專用，限政府網路使用。';

  @override
  String get signInAgency => '以機關帳號登入';

  @override
  String get signInHint => '帳號由所屬機關管理員建立，所有存取均留存紀錄。';

  @override
  String get requestAccount => '如需帳號，請寄信至 tdth@inxsoft.net 申請。';

  @override
  String get fileReportVia => '民眾通報請使用 https://reporting.tw/';

  @override
  String get signOut => '登出';

  @override
  String get noAccessTitle => '無派遣台使用權限';

  @override
  String get noAccessBody => '您的帳號未具派遣員、督導、全國指揮、分析或系統管理角色，請洽所屬機關管理員申請權限。';

  @override
  String get language => '語言';

  @override
  String get themeLight => '淺色主題';

  @override
  String get themeDark => '深色主題';

  @override
  String get liveConnected => '即時連線';

  @override
  String get liveConnecting => '連線中…';

  @override
  String get liveDisconnected => '離線';

  @override
  String get liveTooltip => '即時更新通道；離線時，重新連線後會自動同步案件清單。';

  @override
  String get onDuty => '值勤中';

  @override
  String get offDuty => '未值勤';

  @override
  String get onDutyTooltip => '派案會略過無人值勤的席位，值勤時請開啟。';

  @override
  String get roles => '角色';

  @override
  String get clearance => '安全等級';

  @override
  String get noDesk => '無派遣台';

  @override
  String get navQueue => '案件佇列';

  @override
  String get navLiveMap => '即時地圖';

  @override
  String get navDashboards => '統計分析';

  @override
  String get navAdmin => '系統管理';

  @override
  String get navAudit => '稽核紀錄';

  @override
  String get actionFailed => '操作失敗';

  @override
  String get open => '開啟';

  @override
  String get dismiss => '關閉提示';

  @override
  String get dismissAll => '全部關閉';

  @override
  String moreAlerts(int count) {
    return '另有 $count 則警示';
  }

  @override
  String get alertCreated => '新案件';

  @override
  String get alertSeverity => '嚴重度提升';

  @override
  String get alertRerouted => '改派至本席';

  @override
  String get alertRealert => '仍未受理';

  @override
  String get alertTransferred => '移轉至本席';

  @override
  String get stateNew => '新案';

  @override
  String get stateAcknowledged => '已受理';

  @override
  String get stateInvestigating => '處理中';

  @override
  String get stateResolved => '已處置';

  @override
  String get stateClosed => '已結案';

  @override
  String get stateMerged => '已合併';

  @override
  String get authLikelyAuthorized => '疑似已核准';

  @override
  String get authNoPermit => '無許可';

  @override
  String get authUnknown => '不明';

  @override
  String get classUnclassified => '一般';

  @override
  String get classRestricted => '限閱';

  @override
  String get classDefense => '國防機密';

  @override
  String get srcInformantAndroid => '民眾（Android App）';

  @override
  String get srcInformantWeb => '民眾（網頁）';

  @override
  String get srcFieldOfficer => '外勤員警';

  @override
  String get srcRemoteId => '遠端識別接收器';

  @override
  String get srcRfSensor => '射頻偵測器';

  @override
  String get srcMdaSensor => '海事感測器（MDA）';

  @override
  String get srcRadar => '雷達';

  @override
  String get reasonNearMannedAircraft => '鄰近有人航空器（ADS-B）';

  @override
  String get reasonZoneAirport => '位於機場管制區';

  @override
  String get reasonZoneMilitary => '位於軍事管制區';

  @override
  String get reasonZoneInfrastructure => '位於關鍵基礎設施區';

  @override
  String get reasonZoneOutlying => '位於金馬限制區域';

  @override
  String get reasonSensorRedZone => '感測器確認於紅區內飛行';

  @override
  String get reasonRestrictedNoPermit => '禁限航區內且無相符許可';

  @override
  String get reasonNoRemoteId => '管制空域內未發送遠端識別';

  @override
  String get reasonHovering => '於住宅區上空滯空';

  @override
  String get reasonValidPermit => '註冊資料相符且具有效許可';

  @override
  String get reasonSingleWebReport => '僅單一未驗證網頁通報';

  @override
  String get evCreated => '立案';

  @override
  String get evAcknowledged => '受理';

  @override
  String get evInvestigating => '開始處理';

  @override
  String get evResolved => '處置完成';

  @override
  String get evClosed => '結案';

  @override
  String get evRerouted => '逾時未受理，改派';

  @override
  String get evTransferred => '移轉';

  @override
  String get evMerged => '併入其他案件';

  @override
  String get evMergedFrom => '併入他案';

  @override
  String get evSeverityUpgraded => '嚴重度提升';

  @override
  String get evSeverityDowngraded => '嚴重度調降';

  @override
  String get evAssigned => '承辦人變更';

  @override
  String get evFieldAssigned => '派遣外勤員警';

  @override
  String get evEvidenceRequested => '向通報人調閱證據';

  @override
  String get evEvidenceReceived => '收到證據';

  @override
  String get evObservationAdded => '新增觀測資料';

  @override
  String get evNote => '備註';

  @override
  String get evRedactedCopySent => '已傳送遮蔽版本';

  @override
  String get hashVerified => '雜湊相符';

  @override
  String get hashMismatch => '雜湊不符';

  @override
  String get hashPending => '待驗證';

  @override
  String get scopeDesk => '本席';

  @override
  String get scopeAgency => '本機關';

  @override
  String get scopeAll => '全部';

  @override
  String caseCount(int count) {
    return '$count 件';
  }

  @override
  String get refresh => '重新整理';

  @override
  String get keyboardHelp => '鍵盤：↑/↓ 選取、A 受理、Enter 開啟';

  @override
  String acknowledged(String number) {
    return '$number 已受理';
  }

  @override
  String get fitAll => '全部顯示';

  @override
  String get zoomIn => '放大';

  @override
  String get zoomOut => '縮小';

  @override
  String get queueEmpty => '沒有符合篩選條件的案件。';

  @override
  String get colSeverity => '嚴重度';

  @override
  String get colCase => '案號';

  @override
  String get colState => '狀態';

  @override
  String get colAck => '受理時限';

  @override
  String get colAge => '經過';

  @override
  String get colObservations => '觀測/通報人';

  @override
  String get colConfidence => '可信度';

  @override
  String get colSignals => '訊號';

  @override
  String get colAuthorization => '許可狀態';

  @override
  String get redactedRow => '遮蔽：本席安全等級不足';

  @override
  String get redactedShort => '已遮蔽';

  @override
  String get sensorConfirmed => '感測器確認';

  @override
  String get remoteId => '遠端識別';

  @override
  String get readOnly => '唯讀';

  @override
  String get actAcknowledge => '受理';

  @override
  String get actInvestigate => '開始處理';

  @override
  String get actTransfer => '移轉';

  @override
  String get actMerge => '合併';

  @override
  String get actSeverity => '調整嚴重度';

  @override
  String get actRequestEvidence => '調閱證據';

  @override
  String get actAssignField => '派遣外勤';

  @override
  String get actResolve => '處置完成';

  @override
  String get actClose => '結案';

  @override
  String get actNote => '新增備註';

  @override
  String get transferred => '案件已移轉';

  @override
  String get merged => '案件已合併';

  @override
  String get resolved => '案件已處置';

  @override
  String get fieldAssigned => '外勤派遣已更新';

  @override
  String get noteAdded => '備註已新增';

  @override
  String evidenceRequested(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已向 $count 位通報人送出調閱',
      zero: '本案無可通知的通報人',
    );
    return '$_temp0';
  }

  @override
  String closeConfirm(String number) {
    return '確定將 $number 結案？結案後即無法再變更。';
  }

  @override
  String get targetDesk => '移轉席位';

  @override
  String get required => '必填';

  @override
  String get reason => '理由';

  @override
  String get reasonRequired => '請填寫理由';

  @override
  String transferHint(String classification) {
    return '僅列出符合本案等級（$classification）的席位。案件將以新案移入並重新起算受理時限，原機關保留閱覽權限。';
  }

  @override
  String mergeHint(String number) {
    return '選擇要併入 $number 的案件，其觀測資料與通報人將一併移轉，並標示為已合併。';
  }

  @override
  String get mergeNoCandidates => '佇列中無其他未結案件。';

  @override
  String get nearby => '鄰近';

  @override
  String get mergeChoose => '請選擇案件';

  @override
  String get mergeReasonHint => '例如：同一架無人機';

  @override
  String get currentSeverity => '目前';

  @override
  String get severityUnchanged => '請選擇不同等級';

  @override
  String get downgradeReasonRequired => '調降嚴重度必須填寫理由';

  @override
  String get reasonMandatory => '理由（必填）';

  @override
  String get reasonOptional => '理由（選填）';

  @override
  String get downgradeExplain => '系統只會自動提升嚴重度；調降須由人員判斷，並記錄您的姓名與理由。';

  @override
  String get upgradeExplain => '提升嚴重度會重新警示席位，並以較短時限重新起算受理時間。';

  @override
  String get send => '送出';

  @override
  String get noTemplates => '無可用範本。';

  @override
  String get evidenceRequestHint => '通報人僅會收到此範本訊息（以其語言顯示），無法傳送自由文字。';

  @override
  String get noFieldOfficers => '本機關無外勤員警。';

  @override
  String get lastPosition => '最後位置';

  @override
  String get outcome => '處置結果';

  @override
  String get countsAsFalseReport => '列為不實通報';

  @override
  String get internalNote => '內部備註';

  @override
  String get internalNoteHint => '不會顯示給通報人';

  @override
  String get resolveInformantHint => '通報人僅會看到處置結果範本文字。';

  @override
  String get defenseOutcomeHint => '國防案件：無論選擇何種結果，通報人一律只會看到「已由相關權責機關處理」。';

  @override
  String get noteText => '備註內容';

  @override
  String get noteInternalHint => '內部使用，僅可檢視本案之人員可見';

  @override
  String get defenseNote => '國防備註（加密）';

  @override
  String get defenseNoteHint => '加密儲存，僅國防等級人員可閱覽';

  @override
  String get panelMap => '地圖';

  @override
  String get operator => '操作人';

  @override
  String get estError => '位置誤差';

  @override
  String get altitude => '高度';

  @override
  String get positionSource => '定位來源';

  @override
  String get panelIncident => '事件資訊';

  @override
  String get severityReasons => '嚴重度判定依據';

  @override
  String get firstSeen => '首次發現';

  @override
  String get lastSeen => '最後發現';

  @override
  String get informantsObservations => '通報人 / 觀測筆數';

  @override
  String get confidence => '可信度';

  @override
  String get none => '無';

  @override
  String get permit => '飛航許可';

  @override
  String get noPermitMatched => '無相符許可';

  @override
  String get permitNo => '許可文號';

  @override
  String get operatorName => '操作人／單位';

  @override
  String get validity => '有效期間';

  @override
  String get maxAltitude => '最高高度';

  @override
  String get registryMatch => '註冊資料比對';

  @override
  String get noRegistryMatch => '無相符註冊資料';

  @override
  String get serial => '序號';

  @override
  String get model => '機型';

  @override
  String get registryStatus => '註冊狀態';

  @override
  String get lookUpRegistry => '查詢註冊資料';

  @override
  String get auditedNotice => '註冊查詢會顯示所有人資料，並記錄於稽核紀錄。';

  @override
  String get weather => '氣象';

  @override
  String get visibility => '能見度';

  @override
  String get wind => '風';

  @override
  String get station => '測站';

  @override
  String get adsbNearby => '鄰近 ADS-B 航空器';

  @override
  String get registryLookup => '註冊資料';

  @override
  String get registered => '已註冊';

  @override
  String get notRegistered => '未註冊';

  @override
  String get registrationNo => '註冊編號';

  @override
  String get owner => '所有人';

  @override
  String get ownerRef => '所有人識別碼';

  @override
  String get mtow => '最大起飛重量';

  @override
  String get permits => '飛航許可';

  @override
  String get noStream => '此攝影機無串流或快照網址。';

  @override
  String get panelCctv => '監視器';

  @override
  String get findCameras => '搜尋附近監視器';

  @override
  String get cctvHint => '搜尋推估位置 3 公里內之監視器。';

  @override
  String get noCameras => '附近無監視器。';

  @override
  String get openStream => '開啟影像';

  @override
  String get cctvAudited => '每次調閱監視器皆會連同本案記錄於稽核紀錄。';

  @override
  String get panelObservations => '觀測資料';

  @override
  String get bearing => '方位';

  @override
  String get elevation => '仰角';

  @override
  String get gpsAccuracy => 'GPS 精度';

  @override
  String get spamScore => '濫報分數';

  @override
  String get fidelity => '資料品質';

  @override
  String get attestation => '裝置驗證';

  @override
  String get machineTranslation => '機器翻譯';

  @override
  String get view => '檢視';

  @override
  String get notUploaded => '尚未上傳';

  @override
  String get captured => '拍攝';

  @override
  String get imageFailed => '影像無法載入';

  @override
  String get panelTimeline => '處理歷程';

  @override
  String mergedInto(String number) {
    return '併入 $number';
  }

  @override
  String mergedFrom(String number) {
    return '來自 $number';
  }

  @override
  String get template => '範本';

  @override
  String officersCount(int count) {
    return '$count 名員警';
  }

  @override
  String get defenseNoteAdded => '國防備註（加密）';

  @override
  String get system => '系統';

  @override
  String get user => '人員';

  @override
  String get defenseNotes => '國防備註';

  @override
  String get ackDue => '受理倒數';

  @override
  String get desk => '席位';

  @override
  String get mergedNotice => '本案已併入其他案件。';

  @override
  String get openSurvivor => '開啟存續案件';

  @override
  String get redactedNotice => '已遮蔽：您的安全等級不足以檢視本案，僅顯示位置、時間及嚴重度。';

  @override
  String readOnlyNotice(String desk) {
    return '唯讀：本案由$desk承辦，僅該席位或其機關督導可進行處理。';
  }

  @override
  String get assignedOfficers => '已派遣外勤員警';

  @override
  String get noPosition => '尚無位置';

  @override
  String get redactedTitle => '遮蔽案件';

  @override
  String get redactedExplain =>
      '本案密等高於您的安全等級，系統僅提供遮蔽版本，讓您知悉該地點有狀況發生，並由具權限之席位處理。觀測資料、證據及通報人資料均不予顯示。';

  @override
  String get severity => '嚴重度';

  @override
  String get location => '位置';

  @override
  String get layerZones => '管制區';

  @override
  String get layerAircraft => '航空器';

  @override
  String get layerOfficers => '外勤員警';

  @override
  String get layerRecentClosed => '近期已結';

  @override
  String liveMapCounts(int cases, int aircraft, int officers) {
    return '$cases 件 · $aircraft 架航空器 · $officers 名員警';
  }

  @override
  String get openCase => '開啟案件';

  @override
  String lastNDays(int days) {
    return '$days 天';
  }

  @override
  String get customRange => '自訂';

  @override
  String get kpiIncidents => '事件數';

  @override
  String kpiObservations(int count) {
    return '$count 筆觀測';
  }

  @override
  String get kpiAuthorizedShare => '核准比例';

  @override
  String get kpiRemoteIdCoverage => '遠端識別涵蓋率';

  @override
  String get kpiSensorConfirmed => '感測器確認';

  @override
  String get kpiFalseReports => '不實通報';

  @override
  String get kpiAckP50 => '受理時間（中位數）';

  @override
  String get kpiAckP90 => '受理時間（P90）';

  @override
  String get minSec => '分:秒';

  @override
  String get hotspots => '熱點分布';

  @override
  String get allSeverities => '所有嚴重度';

  @override
  String get allHours => '所有時段';

  @override
  String get allDays => '每日';

  @override
  String hotspotLegend(int cells, int incidents) {
    return '$cells 個網格 · $incidents 件事件；圓越大越紅表示事件越多。';
  }

  @override
  String get dowMon => '週一';

  @override
  String get dowTue => '週二';

  @override
  String get dowWed => '週三';

  @override
  String get dowThu => '週四';

  @override
  String get dowFri => '週五';

  @override
  String get dowSat => '週六';

  @override
  String get dowSun => '週日';

  @override
  String get timeOfDay => '時段分布（臺北時間）';

  @override
  String timeOfDayHint(int max) {
    return '顏色越深表示事件越多（單一時段最多 $max 件），游標移至格子可查看數量。';
  }

  @override
  String incidentsN(int count) {
    return '$count 件';
  }

  @override
  String get zonesAuthorization => '各管制區核准與未核准比較';

  @override
  String get noData => '此期間無資料。';

  @override
  String get zone => '區域';

  @override
  String get zoneType => '類型';

  @override
  String get responsePerformance => '處理效能';

  @override
  String get byAgency => '依機關';

  @override
  String get byDesk => '依席位';

  @override
  String get ackP50Minutes => '受理中位數（分）';

  @override
  String get ackP90Minutes => '受理 P90（分）';

  @override
  String get agency => '機關';

  @override
  String get cases => '案件數';

  @override
  String get ackP50 => '受理中位數';

  @override
  String get ackP90 => '受理 P90';

  @override
  String get resolveP50 => '處置中位數';

  @override
  String get rerouteRate => '改派率';

  @override
  String get unackedRate => '未受理率';

  @override
  String get sourceQuality => '來源品質';

  @override
  String get source => '來源';

  @override
  String get sensorConfirmedShare => '感測器確認比例';

  @override
  String get falseReportRate => '不實通報率';

  @override
  String get repeatOffenders => '重複違規';

  @override
  String get bySerial => '依遠端識別序號';

  @override
  String get byOwner => '依註冊所有人';

  @override
  String get unauthorized => '未核准';

  @override
  String get caseNumbers => '案號';

  @override
  String get drones => '機數';

  @override
  String get repeatOffendersAudited => '檢視重複違規資料會記錄於稽核紀錄。';

  @override
  String get search => '搜尋';

  @override
  String get newZone => '新增區域';

  @override
  String get editZone => '編輯區域';

  @override
  String get published => '公開';

  @override
  String get publishedHint => '於民眾端 App 顯示（僅限民航局公告區域）';

  @override
  String get selectZone => '請選擇區域或新增區域。';

  @override
  String get saved => '已儲存';

  @override
  String get zoneFieldsRequired => '代碼及中英文名稱為必填';

  @override
  String get zoneNeedsPolygon => '請在地圖上至少點選三個頂點';

  @override
  String get undo => '復原';

  @override
  String get clear => '清除';

  @override
  String vertexHelp(int count) {
    return '$count 個頂點 · 點地圖新增、拖曳移動、長按刪除';
  }

  @override
  String get code => '代碼';

  @override
  String get nameEn => '名稱（英文）';

  @override
  String get nameZh => '名稱（中文）';

  @override
  String get classification => '密等';

  @override
  String get priority => '優先順序';

  @override
  String get primaryDesk => '主責席位';

  @override
  String get backupChain => '備援順序';

  @override
  String get addBackupDesk => '新增備援席位';

  @override
  String get backupChainHint => '逾時未受理之案件依序改派，最終一律由全國總機席位承接。';

  @override
  String get ackTimeouts => '受理時限（秒，空白為預設）';

  @override
  String get defaultValue => '預設';

  @override
  String get tabZones => '區域與派案';

  @override
  String get tabTemplates => '訊息範本';

  @override
  String get tabFeedClients => '資料介接';

  @override
  String get templatesHint => '範本是通報人唯一會收到的訊息，每個範本須提供六種語言。';

  @override
  String get newTemplate => '新增範本';

  @override
  String get editTemplate => '編輯範本';

  @override
  String get outcomeTemplates => '處置結果';

  @override
  String get evidenceTemplates => '證據調閱';

  @override
  String get languages => '語言';

  @override
  String get allLanguagesRequired => '六種語言皆為必填。';

  @override
  String get feedClientsHint => '感測器、遠端識別、ADS-B、氣象、註冊、許可及監視器資料介接金鑰。';

  @override
  String get newFeedClient => '新增介接端';

  @override
  String get name => '名稱';

  @override
  String get sources => '資料來源';

  @override
  String get status => '狀態';

  @override
  String get lastUsed => '最後使用';

  @override
  String get active => '啟用';

  @override
  String get revoke => '撤銷';

  @override
  String get revoked => '已撤銷';

  @override
  String revokeConfirm(String name) {
    return '確定撤銷 $name 的金鑰？該資料介接將立即停止。';
  }

  @override
  String get feedKeyTitle => '介接金鑰';

  @override
  String get feedKeyOnce => '此金鑰僅顯示一次，請立即存放於介接系統的機密儲存區。';

  @override
  String get copy => '複製';

  @override
  String get copied => '已複製';

  @override
  String get keyStored => '我已妥善保存金鑰';

  @override
  String get auditUser => '使用者';

  @override
  String get auditActionPrefix => '動作（前綴）';

  @override
  String get auditObjectId => '物件 ID';

  @override
  String get apply => '套用';

  @override
  String get auditViewAudited => '檢視稽核紀錄本身亦會被記錄。';

  @override
  String get time => '時間';

  @override
  String get auditAction => '動作';

  @override
  String get auditObject => '物件';

  @override
  String get details => '詳細資料';

  @override
  String get domainAerial => '空中';

  @override
  String get domainSurface => '水面';

  @override
  String get domainSubsurface => '水下';

  @override
  String get domainShore => '岸際';

  @override
  String get domainUnknown => '類別不明';

  @override
  String get craftUavMultirotor => '多旋翼無人機';

  @override
  String get craftUavFixedWing => '固定翼無人機';

  @override
  String get craftUav => '無人機';

  @override
  String get craftBalloon => '氣球／飛艇';

  @override
  String get craftUsv => '無人水面載具（USV）';

  @override
  String get craftSmallBoat => '小艇';

  @override
  String get craftFishingVessel => '漁船';

  @override
  String get craftShip => '船舶';

  @override
  String get craftVessel => '船隻';

  @override
  String get craftSubmarine => '潛艦（潛望鏡／桅杆）';

  @override
  String get craftUuv => '無人水下載具';

  @override
  String get craftLandedBoat => '船隻搶灘／靠岸';

  @override
  String get craftObjectAshore => '不明物體漂上岸';

  @override
  String get craftUnknownSubsurface => '不明水下目標';

  @override
  String get panelAi => 'AI 初判（僅供參考）';

  @override
  String get aiAdvisoryNote => '僅供參考：模型最多將嚴重度提高一級，須有佐證才會升為緊急，且不會降級或結案。';

  @override
  String get aiThreat => '威脅研判';

  @override
  String get aiCraft => '辨識結果';

  @override
  String get aiSilhouette => '外形描述';

  @override
  String get aiUnmanned => '無人載具可能性';

  @override
  String get aiSpam => '無關影像可能性';

  @override
  String get aiConfidence => '模型信心';

  @override
  String get aiMatchesReport => '與通報內容一致';

  @override
  String get aiModel => '模型';

  @override
  String get aiNone => '尚無 AI 研判（照片上傳後才會分析）。';

  @override
  String get panelMaritime => '海上態勢';

  @override
  String get vesselAis => 'AIS 船舶';

  @override
  String get darkVessel => '疑似關閉 AIS：此海域有 AIS 涵蓋，但目標附近無船舶訊號';

  @override
  String get noAisCoverage => '此海域無 AIS 涵蓋';

  @override
  String get mdaTrack => '海域感知目標（未識別）';

  @override
  String get interviewAnswers => '通報人問答';

  @override
  String get craftDomain => '類別';

  @override
  String get layerVessels => '船舶（AIS／海域感知）';

  @override
  String get layerCameras => '影像來源';

  @override
  String get videoFeeds => '影像來源';

  @override
  String get reasonSubsurface => '水下目標';

  @override
  String get reasonPeopleUnloading => '有人搬運物品上岸';

  @override
  String get reasonCraftLanded => '載具靠岸／搶灘';

  @override
  String get reasonUsv => '無人水面載具';

  @override
  String get reasonUsvProtected => '無人艇位於管制／防護水域';

  @override
  String get reasonUsvApproaching => '無人艇正接近岸際';

  @override
  String get reasonDarkProtected => '關閉 AIS 船隻位於防護水域';

  @override
  String get reasonDarkTerritorial => '關閉 AIS 船隻位於領海';

  @override
  String get reasonUnidentifiedRestricted => '限制水域內不明船隻';

  @override
  String get reasonVesselRestricted => '船隻進入限制水域';

  @override
  String get reasonUnidentifiedProtected => '防護水域內不明載具';

  @override
  String get reasonAi => 'AI 研判（參考）';

  @override
  String get zoneDomains => '適用類別';

  @override
  String get loginUsername => '帳號';

  @override
  String get loginPassword => '密碼';

  @override
  String get loginWrongCredentials => '帳號或密碼錯誤。';

  @override
  String get loginLocked => '登入失敗次數過多，帳號已鎖定 15 分鐘。';

  @override
  String get loginTooMany => '此網路登入嘗試過多，請稍後再試。';

  @override
  String get tabUsers => '使用者';

  @override
  String get newUser => '新增使用者';

  @override
  String get editUser => '編輯使用者';

  @override
  String get usersHint => '主控台與外勤 App 的人員帳號。密碼至少 12 個字元。';

  @override
  String get displayName => '顯示名稱';

  @override
  String get fieldUnitLabel => '國防外勤單位';

  @override
  String get initialPassword => '初始密碼';

  @override
  String get resetPassword => '新密碼（留空則不變更）';

  @override
  String get deactivate => '停用';

  @override
  String get reactivate => '重新啟用';

  @override
  String get deactivated => '已停用';

  @override
  String get lockedLabel => '鎖定中';

  @override
  String get lastSeenLabel => '最後上線';

  @override
  String get userSaved => '已儲存';

  @override
  String get navAtreides => 'Atreides';

  @override
  String get atreidesTitle => 'Atreides 海事感測';

  @override
  String get atreidesSubtitle =>
      'Atreides 提供的非合作式海域偵測（MDA）。這不是 AIS：沒有船舶身分、航速或航向。每筆偵測分類為移動目標、固定設施或不明。';

  @override
  String get atreidesAllBatches => '全部匯入';

  @override
  String get atreidesAllRoles => '全部';

  @override
  String get atreidesDetections => '偵測';

  @override
  String get atreidesTracks => '航跡';

  @override
  String atreidesTrackSplit(int routes, int singles) {
    final intl.NumberFormat routesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String routesString = routesNumberFormat.format(routes);
    final intl.NumberFormat singlesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String singlesString = singlesNumberFormat.format(singles);

    return '$routesString 條航線 · $singlesString 個單點目標';
  }

  @override
  String get atreidesRoleMobile => '移動目標';

  @override
  String get atreidesRoleFixed => '固定設施';

  @override
  String get atreidesRoleAmbiguous => '不明';

  @override
  String get atreidesPeriod => '期間';

  @override
  String get atreidesHighConfidence => '僅顯示高可信度';

  @override
  String get atreidesRoutesOnly => '僅顯示航線';

  @override
  String atreidesTrackFacts(int count, String km) {
    return '$count 筆偵測 · $km 公里';
  }

  @override
  String get atreidesSingleContact => '單點目標';

  @override
  String atreidesSourceView(String role, String confidence, String reasoning) {
    return '來源感測器：$role（$confidence）— $reasoning';
  }

  @override
  String get atreidesEmpty => '尚未匯入 Atreides 資料。';

  @override
  String atreidesShowing(int shown, int total) {
    return '顯示 $shown / $total';
  }

  @override
  String atreidesConfidence(String level) {
    return '$level可信度';
  }

  @override
  String get atreidesConfHigh => '高';

  @override
  String get atreidesConfLow => '低';

  @override
  String get consoleTitle => 'Reporting.tw：監控可疑空中及水域活動通報';

  @override
  String get navMaritime => '海事警示';

  @override
  String get maritimeTitle => '海上異常行為警示';

  @override
  String get maritimeSubtitle =>
      '來自 AIS、Atreides 與模擬航跡的異常停留、偏離航道、海上會合、回報中斷及進入保護水域。供人員判讀：警示不等於定論。';

  @override
  String get tabAlerts => '警示';

  @override
  String get tabThresholds => '門檻設定';

  @override
  String get tabEvaluation => '規則與統計比較';

  @override
  String get maritimeStatusOpen => '待處理';

  @override
  String get maritimeStatusAcknowledged => '已確認';

  @override
  String get maritimeStatusFalseAlarm => '誤報';

  @override
  String get maritimeStatusDismissed => '已撤銷';

  @override
  String get maritimeStatusEscalated => '已轉為案件';

  @override
  String get maritimeStatusReopened => '重新開啟';

  @override
  String get maritimeShowClosed => '顯示已結束';

  @override
  String get maritimeAllKinds => '全部行為';

  @override
  String get kindStop => '停留／徘徊';

  @override
  String get kindDeviation => '偏離常用航道';

  @override
  String get kindCluster => '船舶會合';

  @override
  String get kindZoneEntry => '進入保護水域';

  @override
  String get kindApproach => '接近保護水域';

  @override
  String get kindGap => '回報中斷';

  @override
  String get kindStatistical => '統計異常';

  @override
  String get methodRules => '規則';

  @override
  String get methodStat => '統計';

  @override
  String get methodBoth => '規則＋統計';

  @override
  String maritimeRisk(int score) {
    return '風險 $score';
  }

  @override
  String maritimeQuality(int pct) {
    return '資料品質 $pct%';
  }

  @override
  String get maritimeWhy => '警示原因';

  @override
  String get maritimeUncertainty => '不確定性';

  @override
  String get maritimeTimeline => '時間軸';

  @override
  String maritimeValue(String value, String threshold) {
    return '量測 $value · 門檻 $threshold';
  }

  @override
  String get maritimeAck => '確認';

  @override
  String get maritimeFalseAlarm => '標記誤報';

  @override
  String get maritimeDismiss => '撤銷';

  @override
  String get maritimeReopen => '重新開啟';

  @override
  String get maritimeEscalate => '轉為案件';

  @override
  String get maritimeOpenCase => '開啟案件';

  @override
  String get maritimeAddNote => '新增備註';

  @override
  String get maritimeNoteHint => '時間軸備註';

  @override
  String get maritimeSuppressHours => '靜默時數';

  @override
  String get maritimeFalseAlarmTitle => '標記為誤報';

  @override
  String get maritimeNone => '沒有符合的警示。';

  @override
  String get maritimeSelect => '選擇警示以查看原因。';

  @override
  String get maritimeSave => '儲存並重新偵測';

  @override
  String get maritimeSaved => '門檻已儲存並重新偵測。';

  @override
  String maritimeDefault(String value) {
    return '預設 $value';
  }

  @override
  String get maritimeReadOnly => '僅督導及管理員可變更門檻。';

  @override
  String evalIntro(int tracks, int anomalous) {
    return '臺灣周邊模擬航行並標記異常行為：共檢查 $tracks 條航跡，其中 $anomalous 條異常。精確率：警示中確為異常的比例；召回率：異常被找出的比例。';
  }

  @override
  String get evalMethod => '方法';

  @override
  String get evalPrecision => '精確率';

  @override
  String get evalRecall => '召回率';

  @override
  String get evalF1 => 'F1';

  @override
  String get evalFalseAlarms => '每百條正常航跡誤報數';

  @override
  String get evalCombined => '綜合風險分數（操作人員所見）';

  @override
  String get evalByKind => '各類注入行為偵測數';

  @override
  String get evalRun => '重新比較';

  @override
  String get evalResimulate => '重新產生模擬航行';

  @override
  String get evalNone => '尚無比較結果。';

  @override
  String evalRanAt(String when) {
    return '執行時間 $when';
  }

  @override
  String get eventDetected => '偵測';

  @override
  String get eventUpdated => '更新';

  @override
  String get eventNote => '備註';

  @override
  String get maritimeSourceSim => '模擬';

  @override
  String get maritimeSourceAtreides => 'Atreides';

  @override
  String get evRecommendation => '已處理建議';

  @override
  String get recTitle => '建議行動';

  @override
  String get recIntro => '僅為決策輔助，不會控制任何裝置。接受派遣外勤人員會將該員指派至本案；其他行動為模擬並留存紀錄。';

  @override
  String get recAccept => '接受';

  @override
  String get recReject => '拒絕';

  @override
  String get recModify => '修改';

  @override
  String get recModifyTitle => '修改建議';

  @override
  String get recNewText => '實際執行內容';

  @override
  String get recNote => '備註（選填）';

  @override
  String get recAccepted => '已接受';

  @override
  String get recRejected => '已拒絕';

  @override
  String get recModified => '已修改';

  @override
  String recBy(String who, String when) {
    return '$who，$when';
  }

  @override
  String get recNone => '本案目前沒有建議。';

  @override
  String get recReadOnly => '僅由承辦本案的席位決定。';

  @override
  String get navCctv => '監視器';

  @override
  String get cctvTitle => '監視器目標追蹤';

  @override
  String get cctvSubtitle =>
      '以 AI 影像分析（Featherless AI）在監視器畫面中持續追蹤的無人機與船隻。僅供參考：每條追蹤都由人員審查。';

  @override
  String get cctvCameras => '監視器';

  @override
  String get cctvTracks => '追蹤';

  @override
  String get cctvNoTracks => '未偵測到可疑活動。';

  @override
  String get cctvNoCameras => '尚未連接任何監視器。';

  @override
  String get cctvInactive => '停用';

  @override
  String cctvLastSample(String time) {
    return '最後畫面 $time';
  }

  @override
  String cctvTrackFacts(int hits, String from, String to) {
    return '$hits 個畫面 · $from – $to';
  }

  @override
  String get cctvFrameLegend => '最後畫面：追蹤路徑（橘色）、偵測框與警戒區（紅色）';

  @override
  String get cctvNoFrame => '此追蹤沒有儲存的畫面。';

  @override
  String cctvOpenCase(String number) {
    return '開啟案件 $number';
  }

  @override
  String get cctvTrackActive => '追蹤中';

  @override
  String get cctvTrackLost => '已失去目標';

  @override
  String get cctvBehLoiter => '滯留';

  @override
  String get cctvBehApproaching => '接近中';

  @override
  String get cctvBehFast => '快速移動';

  @override
  String get cctvBehZone => '警戒區';

  @override
  String cctvOpenCases(int count) {
    return '$count 件未結案件';
  }
}
