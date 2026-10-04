// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'field_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class FieldL10nZh extends FieldL10n {
  FieldL10nZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '可疑載具通報 外勤';

  @override
  String get loginSubtitle => '外勤員警專用。請以機關帳號登入。';

  @override
  String get signIn => '登入';

  @override
  String get signInFailed => '登入失敗，請確認網路連線後再試一次。';

  @override
  String get signOut => '登出';

  @override
  String get signOutConfirm => '確定要登出外勤 App？';

  @override
  String signOutPendingWarning(int count) {
    return '尚有 $count 筆未送出的現場紀錄將被刪除。仍要登出？';
  }

  @override
  String get mdmNote => '本裝置由所屬機關管理。如有遺失或遭竊，請立即通報，裝置將以 MDM 遠端抹除。';

  @override
  String get noAccessTitle => '無外勤員警權限';

  @override
  String get noAccessBody => '您的帳號未具外勤員警角色，請洽所屬單位系統管理員。';

  @override
  String get assignmentsTitle => '我的勤務指派';

  @override
  String get noAssignments => '目前沒有指派給您的案件。';

  @override
  String get outboxTitle => '待送清單';

  @override
  String get outboxEmpty => '所有資料皆已送出。';

  @override
  String get outboxExplanation => '已存於本機、尚未送達伺服器的現場紀錄。恢復連線後會自動重送。';

  @override
  String get retryNow => '立即重送';

  @override
  String get discard => '刪除';

  @override
  String get discardConfirm => '確定刪除這筆未送出的紀錄？刪除後無法復原。';

  @override
  String attempts(int count) {
    return '已嘗試 $count 次';
  }

  @override
  String mediaCount(int count) {
    return '$count 個檔案';
  }

  @override
  String get rejected => '伺服器拒收';

  @override
  String offlineBanner(String when) {
    return '離線中－最後更新：$when';
  }

  @override
  String get defenseFieldUnit => '國防現地單位';

  @override
  String get caseTitle => '案件';

  @override
  String get caseUnavailable => '此案件已不再指派給您，或目前無法檢視。';

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
  String get stateMerged => '已併案';

  @override
  String get authLikelyAuthorized => '可能已核准';

  @override
  String get authNoPermit => '無許可';

  @override
  String get authUnknown => '許可狀態不明';

  @override
  String get sourceRemoteId => '遠端識別（Remote ID）';

  @override
  String get sourceTriangulated => '交會定位';

  @override
  String get sourceSensor => '偵測器';

  @override
  String get sourceInformant => '民眾通報推估';

  @override
  String get compassPoints => '北|東北|東|東南|南|西南|西|西北';

  @override
  String get positionUnknown => '位置不明';

  @override
  String get waitingForGps => '等待 GPS 定位…';

  @override
  String gpsAccuracy(int meters) {
    return 'GPS 精度 ±$meters 公尺';
  }

  @override
  String lastSeen(String when) {
    return '最後目擊 $when';
  }

  @override
  String get redactedShort => '限閱';

  @override
  String get redactedExplanation =>
      '本案為國防機密案件，僅國防現地單位可檢視完整內容；您僅能看到位置、時間與嚴重程度。請依勤務指揮中心指示執行。';

  @override
  String get sensorConfirmed => '偵測器確認';

  @override
  String get operator => '操作者';

  @override
  String get me => '我';

  @override
  String get fitMap => '顯示全部';

  @override
  String get toDrone => '無人機';

  @override
  String get toOperator => '操作者位置';

  @override
  String get positionSharingOn => '正在向勤指中心分享我的位置（點選停止）';

  @override
  String get positionSharingOff => '位置分享已關閉（點選開啟）';

  @override
  String get basicInfo => '基本資料';

  @override
  String get severity => '嚴重程度';

  @override
  String get location => '位置';

  @override
  String get firstSeenLabel => '首次目擊';

  @override
  String get lastSeenLabel => '最後目擊';

  @override
  String get remoteIdScan => 'Remote ID 掃描';

  @override
  String get captureEvidence => '現場蒐證';

  @override
  String get incidentFacts => '事件資訊';

  @override
  String get positionSource => '定位來源';

  @override
  String get estError => '定位誤差';

  @override
  String get estAltitude => '推估高度';

  @override
  String get reports => '觀測筆數';

  @override
  String distinctInformants(int count) {
    return '$count 位通報人';
  }

  @override
  String get authorization => '許可狀態';

  @override
  String get zones => '所在區域';

  @override
  String get none => '無';

  @override
  String get permit => '飛航許可';

  @override
  String get permitNo => '許可編號';

  @override
  String get operatorName => '操作人';

  @override
  String get validity => '有效期間';

  @override
  String get maxAltitude => '最高高度';

  @override
  String get remoteIdSerials => '遠端識別（Remote ID）';

  @override
  String get registryMatch => '登記比對';

  @override
  String get noRemoteId => '本案尚未接收到 Remote ID。';

  @override
  String get registryLookup => '查詢登記';

  @override
  String registryTitle(String serial) {
    return '登記查詢：$serial';
  }

  @override
  String get registryFailed => '登記查詢失敗。';

  @override
  String get registered => '已登記';

  @override
  String get notRegistered => '未登記';

  @override
  String get registrationNo => '登記編號';

  @override
  String get owner => '所有人';

  @override
  String get model => '型號';

  @override
  String get mtow => '最大起飛重量';

  @override
  String get registryStatus => '狀態';

  @override
  String get permits => '飛航許可';

  @override
  String get adsbNearby => '附近航空器（ADS-B）';

  @override
  String get weather => '天氣';

  @override
  String get weatherStation => '測站';

  @override
  String get visibility => '能見度';

  @override
  String get wind => '風速風向';

  @override
  String observationsCount(int count) {
    return '觀測紀錄（$count 筆）';
  }

  @override
  String get srcFieldOfficer => '外勤員警';

  @override
  String get srcRemoteId => 'Remote ID 接收器';

  @override
  String get srcRfSensor => '射頻偵測器';

  @override
  String get srcMdaSensor => '海事感測器（MDA）';

  @override
  String get srcRadar => '雷達';

  @override
  String get srcInformant => '民眾通報';

  @override
  String get fieldOfficers => '指派員警';

  @override
  String get notes => '工作紀錄';

  @override
  String get noteHint => '新增給勤指中心的紀錄…';

  @override
  String get addNote => '新增紀錄';

  @override
  String get noteAdded => '已新增紀錄。';

  @override
  String get noteFailed => '無法新增紀錄（可能離線）。';

  @override
  String get restartScan => '重新掃描';

  @override
  String scanFor(String caseNumber) {
    return '本機接收到的無人機。可附加至案件 $caseNumber，將其 Remote ID 與位置列為現場證據。';
  }

  @override
  String get capBt4 => '藍牙 4';

  @override
  String get capBt5 => '藍牙 5 長距離';

  @override
  String get capWifiBeacon => 'Wi-Fi Beacon';

  @override
  String get capWifiNan => 'Wi-Fi NAN';

  @override
  String get noRemoteIdHardware => '本裝置無法接收 Remote ID（無支援的藍牙或 Wi-Fi 接收功能）。';

  @override
  String get scanPermissionError =>
      'Remote ID 掃描需要「鄰近裝置」（藍牙／Wi-Fi）與「位置」權限。請授權，或至設定中開啟。';

  @override
  String get scanPermissionPartial => '部分權限未授予，僅能掃描部分傳輸方式。';

  @override
  String get grantPermission => '授權';

  @override
  String get openSettings => '開啟設定';

  @override
  String scanError(String error) {
    return '掃描錯誤：$error';
  }

  @override
  String get scanningNoDrones => '掃描中…尚未接收到 Remote ID 廣播。';

  @override
  String get unknownSerial => '識別碼不明';

  @override
  String get live => '即時';

  @override
  String secondsAgo(int seconds) {
    return '$seconds 秒前';
  }

  @override
  String get idType => '識別類型';

  @override
  String get idTypeSerial => '序號';

  @override
  String get idTypeCaa => '民航局登記號碼';

  @override
  String get idTypeUtm => 'UTM 指配';

  @override
  String get idTypeSession => '工作階段識別碼';

  @override
  String get uaType => '航空器類型';

  @override
  String get dronePosition => '無人機位置';

  @override
  String get fromMe => '與我距離';

  @override
  String get height => '高度';

  @override
  String get altGeo => '幾何高度';

  @override
  String get speedDirection => '速度／航向';

  @override
  String get operatorPosition => '操作者位置';

  @override
  String get operatorFromMe => '操作者與我距離';

  @override
  String get operatorId => '操作者識別碼';

  @override
  String get selfId => '自我描述';

  @override
  String get transport => '接收方式';

  @override
  String get rssi => '訊號強度';

  @override
  String get attachToCase => '附加至案件';

  @override
  String get attachAgain => '已附加－再次附加';

  @override
  String get noGpsFix => '尚未取得 GPS 定位，請移至空曠處後再試。';

  @override
  String get observationSent => '已送至案件。';

  @override
  String get observationQueued => '已存入待送清單，恢復連線後自動送出。';

  @override
  String get observationDuplicate => '伺服器已收到此筆紀錄。';

  @override
  String get observationRejected => '伺服器拒收此筆紀錄，請查看待送清單。';

  @override
  String evidenceFor(String caseNumber) {
    return '案件 $caseNumber 現場蒐證。檔案於拍攝時即計算雜湊值，並於背景上傳。';
  }

  @override
  String get media => '照片／影片／錄音';

  @override
  String get photo => '拍照';

  @override
  String get video => '錄影';

  @override
  String get audio => '旋翼聲錄音';

  @override
  String get stopAudio => '停止錄音';

  @override
  String get remove => '移除';

  @override
  String get captureFailed => '擷取失敗。';

  @override
  String get micPermission => '錄音需要麥克風權限。';

  @override
  String get bearing => '無人機方位';

  @override
  String get bearingHint => '選填：開啟後，將手機背面對準無人機並鎖定方位。';

  @override
  String get waitingForCompass => '等待電子羅盤…';

  @override
  String elevation(int degrees) {
    return '仰角 $degrees°';
  }

  @override
  String get compassLowAccuracy => '電子羅盤精度偏低：請以 8 字形移動手機校正。';

  @override
  String get lockBearing => '鎖定方位';

  @override
  String lockedBearing(String bearing, int elevation) {
    return '已鎖定：$bearing，仰角 $elevation°';
  }

  @override
  String get note => '備註';

  @override
  String get evidenceNoteHint => '現場狀況（機型、操作者、行為）';

  @override
  String get submitEvidence => '送出';

  @override
  String get craft => '載具';

  @override
  String get darkVessel => '疑似關閉 AIS：附近無船舶訊號';

  @override
  String get aiAssessment => 'AI 研判（參考）';

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
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class FieldL10nZhTw extends FieldL10nZh {
  FieldL10nZhTw() : super('zh_TW');

  @override
  String get appTitle => '可疑載具通報 外勤';

  @override
  String get loginSubtitle => '外勤員警專用。請以機關帳號登入。';

  @override
  String get signIn => '登入';

  @override
  String get signInFailed => '登入失敗，請確認網路連線後再試一次。';

  @override
  String get signOut => '登出';

  @override
  String get signOutConfirm => '確定要登出外勤 App？';

  @override
  String signOutPendingWarning(int count) {
    return '尚有 $count 筆未送出的現場紀錄將被刪除。仍要登出？';
  }

  @override
  String get mdmNote => '本裝置由所屬機關管理。如有遺失或遭竊，請立即通報，裝置將以 MDM 遠端抹除。';

  @override
  String get noAccessTitle => '無外勤員警權限';

  @override
  String get noAccessBody => '您的帳號未具外勤員警角色，請洽所屬單位系統管理員。';

  @override
  String get assignmentsTitle => '我的勤務指派';

  @override
  String get noAssignments => '目前沒有指派給您的案件。';

  @override
  String get outboxTitle => '待送清單';

  @override
  String get outboxEmpty => '所有資料皆已送出。';

  @override
  String get outboxExplanation => '已存於本機、尚未送達伺服器的現場紀錄。恢復連線後會自動重送。';

  @override
  String get retryNow => '立即重送';

  @override
  String get discard => '刪除';

  @override
  String get discardConfirm => '確定刪除這筆未送出的紀錄？刪除後無法復原。';

  @override
  String attempts(int count) {
    return '已嘗試 $count 次';
  }

  @override
  String mediaCount(int count) {
    return '$count 個檔案';
  }

  @override
  String get rejected => '伺服器拒收';

  @override
  String offlineBanner(String when) {
    return '離線中－最後更新：$when';
  }

  @override
  String get defenseFieldUnit => '國防現地單位';

  @override
  String get caseTitle => '案件';

  @override
  String get caseUnavailable => '此案件已不再指派給您，或目前無法檢視。';

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
  String get stateMerged => '已併案';

  @override
  String get authLikelyAuthorized => '可能已核准';

  @override
  String get authNoPermit => '無許可';

  @override
  String get authUnknown => '許可狀態不明';

  @override
  String get sourceRemoteId => '遠端識別（Remote ID）';

  @override
  String get sourceTriangulated => '交會定位';

  @override
  String get sourceSensor => '偵測器';

  @override
  String get sourceInformant => '民眾通報推估';

  @override
  String get compassPoints => '北|東北|東|東南|南|西南|西|西北';

  @override
  String get positionUnknown => '位置不明';

  @override
  String get waitingForGps => '等待 GPS 定位…';

  @override
  String gpsAccuracy(int meters) {
    return 'GPS 精度 ±$meters 公尺';
  }

  @override
  String lastSeen(String when) {
    return '最後目擊 $when';
  }

  @override
  String get redactedShort => '限閱';

  @override
  String get redactedExplanation =>
      '本案為國防機密案件，僅國防現地單位可檢視完整內容；您僅能看到位置、時間與嚴重程度。請依勤務指揮中心指示執行。';

  @override
  String get sensorConfirmed => '偵測器確認';

  @override
  String get operator => '操作者';

  @override
  String get me => '我';

  @override
  String get fitMap => '顯示全部';

  @override
  String get toDrone => '無人機';

  @override
  String get toOperator => '操作者位置';

  @override
  String get positionSharingOn => '正在向勤指中心分享我的位置（點選停止）';

  @override
  String get positionSharingOff => '位置分享已關閉（點選開啟）';

  @override
  String get basicInfo => '基本資料';

  @override
  String get severity => '嚴重程度';

  @override
  String get location => '位置';

  @override
  String get firstSeenLabel => '首次目擊';

  @override
  String get lastSeenLabel => '最後目擊';

  @override
  String get remoteIdScan => 'Remote ID 掃描';

  @override
  String get captureEvidence => '現場蒐證';

  @override
  String get incidentFacts => '事件資訊';

  @override
  String get positionSource => '定位來源';

  @override
  String get estError => '定位誤差';

  @override
  String get estAltitude => '推估高度';

  @override
  String get reports => '觀測筆數';

  @override
  String distinctInformants(int count) {
    return '$count 位通報人';
  }

  @override
  String get authorization => '許可狀態';

  @override
  String get zones => '所在區域';

  @override
  String get none => '無';

  @override
  String get permit => '飛航許可';

  @override
  String get permitNo => '許可編號';

  @override
  String get operatorName => '操作人';

  @override
  String get validity => '有效期間';

  @override
  String get maxAltitude => '最高高度';

  @override
  String get remoteIdSerials => '遠端識別（Remote ID）';

  @override
  String get registryMatch => '登記比對';

  @override
  String get noRemoteId => '本案尚未接收到 Remote ID。';

  @override
  String get registryLookup => '查詢登記';

  @override
  String registryTitle(String serial) {
    return '登記查詢：$serial';
  }

  @override
  String get registryFailed => '登記查詢失敗。';

  @override
  String get registered => '已登記';

  @override
  String get notRegistered => '未登記';

  @override
  String get registrationNo => '登記編號';

  @override
  String get owner => '所有人';

  @override
  String get model => '型號';

  @override
  String get mtow => '最大起飛重量';

  @override
  String get registryStatus => '狀態';

  @override
  String get permits => '飛航許可';

  @override
  String get adsbNearby => '附近航空器（ADS-B）';

  @override
  String get weather => '天氣';

  @override
  String get weatherStation => '測站';

  @override
  String get visibility => '能見度';

  @override
  String get wind => '風速風向';

  @override
  String observationsCount(int count) {
    return '觀測紀錄（$count 筆）';
  }

  @override
  String get srcFieldOfficer => '外勤員警';

  @override
  String get srcRemoteId => 'Remote ID 接收器';

  @override
  String get srcRfSensor => '射頻偵測器';

  @override
  String get srcMdaSensor => '海事感測器（MDA）';

  @override
  String get srcRadar => '雷達';

  @override
  String get srcInformant => '民眾通報';

  @override
  String get fieldOfficers => '指派員警';

  @override
  String get notes => '工作紀錄';

  @override
  String get noteHint => '新增給勤指中心的紀錄…';

  @override
  String get addNote => '新增紀錄';

  @override
  String get noteAdded => '已新增紀錄。';

  @override
  String get noteFailed => '無法新增紀錄（可能離線）。';

  @override
  String get restartScan => '重新掃描';

  @override
  String scanFor(String caseNumber) {
    return '本機接收到的無人機。可附加至案件 $caseNumber，將其 Remote ID 與位置列為現場證據。';
  }

  @override
  String get capBt4 => '藍牙 4';

  @override
  String get capBt5 => '藍牙 5 長距離';

  @override
  String get capWifiBeacon => 'Wi-Fi Beacon';

  @override
  String get capWifiNan => 'Wi-Fi NAN';

  @override
  String get noRemoteIdHardware => '本裝置無法接收 Remote ID（無支援的藍牙或 Wi-Fi 接收功能）。';

  @override
  String get scanPermissionError =>
      'Remote ID 掃描需要「鄰近裝置」（藍牙／Wi-Fi）與「位置」權限。請授權，或至設定中開啟。';

  @override
  String get scanPermissionPartial => '部分權限未授予，僅能掃描部分傳輸方式。';

  @override
  String get grantPermission => '授權';

  @override
  String get openSettings => '開啟設定';

  @override
  String scanError(String error) {
    return '掃描錯誤：$error';
  }

  @override
  String get scanningNoDrones => '掃描中…尚未接收到 Remote ID 廣播。';

  @override
  String get unknownSerial => '識別碼不明';

  @override
  String get live => '即時';

  @override
  String secondsAgo(int seconds) {
    return '$seconds 秒前';
  }

  @override
  String get idType => '識別類型';

  @override
  String get idTypeSerial => '序號';

  @override
  String get idTypeCaa => '民航局登記號碼';

  @override
  String get idTypeUtm => 'UTM 指配';

  @override
  String get idTypeSession => '工作階段識別碼';

  @override
  String get uaType => '航空器類型';

  @override
  String get dronePosition => '無人機位置';

  @override
  String get fromMe => '與我距離';

  @override
  String get height => '高度';

  @override
  String get altGeo => '幾何高度';

  @override
  String get speedDirection => '速度／航向';

  @override
  String get operatorPosition => '操作者位置';

  @override
  String get operatorFromMe => '操作者與我距離';

  @override
  String get operatorId => '操作者識別碼';

  @override
  String get selfId => '自我描述';

  @override
  String get transport => '接收方式';

  @override
  String get rssi => '訊號強度';

  @override
  String get attachToCase => '附加至案件';

  @override
  String get attachAgain => '已附加－再次附加';

  @override
  String get noGpsFix => '尚未取得 GPS 定位，請移至空曠處後再試。';

  @override
  String get observationSent => '已送至案件。';

  @override
  String get observationQueued => '已存入待送清單，恢復連線後自動送出。';

  @override
  String get observationDuplicate => '伺服器已收到此筆紀錄。';

  @override
  String get observationRejected => '伺服器拒收此筆紀錄，請查看待送清單。';

  @override
  String evidenceFor(String caseNumber) {
    return '案件 $caseNumber 現場蒐證。檔案於拍攝時即計算雜湊值，並於背景上傳。';
  }

  @override
  String get media => '照片／影片／錄音';

  @override
  String get photo => '拍照';

  @override
  String get video => '錄影';

  @override
  String get audio => '旋翼聲錄音';

  @override
  String get stopAudio => '停止錄音';

  @override
  String get remove => '移除';

  @override
  String get captureFailed => '擷取失敗。';

  @override
  String get micPermission => '錄音需要麥克風權限。';

  @override
  String get bearing => '無人機方位';

  @override
  String get bearingHint => '選填：開啟後，將手機背面對準無人機並鎖定方位。';

  @override
  String get waitingForCompass => '等待電子羅盤…';

  @override
  String elevation(int degrees) {
    return '仰角 $degrees°';
  }

  @override
  String get compassLowAccuracy => '電子羅盤精度偏低：請以 8 字形移動手機校正。';

  @override
  String get lockBearing => '鎖定方位';

  @override
  String lockedBearing(String bearing, int elevation) {
    return '已鎖定：$bearing，仰角 $elevation°';
  }

  @override
  String get note => '備註';

  @override
  String get evidenceNoteHint => '現場狀況（機型、操作者、行為）';

  @override
  String get submitEvidence => '送出';

  @override
  String get craft => '載具';

  @override
  String get darkVessel => '疑似關閉 AIS：附近無船舶訊號';

  @override
  String get aiAssessment => 'AI 研判（參考）';

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
}
