// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'informant_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class InformantL10nZh extends InformantL10n {
  InformantL10nZh([String locale = 'zh']) : super(locale);

  @override
  String get skip => '略過';

  @override
  String get notSure => '不確定';

  @override
  String get onboardingLanguageTitle => '請選擇語言';

  @override
  String get onboardingLanguageBody => '之後可隨時在「設定」中變更。';

  @override
  String get onboardingWhatTitle => '通報可疑無人機、無人艇與其他不明載具';

  @override
  String get onboardingWhatBody =>
      '在機場或軍事設施附近看到無人機、在海上看到無人小艇，或有船隻在海灘靠岸？一分鐘內就能完成通報，系統會直接轉給負責的機關：警察、民航、海巡或國防單位。';

  @override
  String get onboardingSafetyTitle => '安全第一';

  @override
  String get onboardingSafetyApproach => '切勿靠近或跟蹤無人機操作者。';

  @override
  String get onboardingSafetyDistance => '與無人機保持距離，並注意周遭交通。';

  @override
  String get onboardingSafetyDanger => '如有人身危險，請先撥打 110。';

  @override
  String get onboardingPrivacyTitle => '全程匿名';

  @override
  String get onboardingPrivacyNoAccount => '我們不會要求您提供姓名、電話號碼或註冊帳號。';

  @override
  String get onboardingPrivacyCollected =>
      '通報內容包括：您的位置、手機指向的方向、您加入的照片、影片或聲音，以及安裝 App 時產生的隨機識別碼。';

  @override
  String get onboardingPrivacyUse => '通報資料僅供臺灣政府主管機關處理無人機與海上事件使用。';

  @override
  String get onboardingPermissionsTitle => '權限說明';

  @override
  String get onboardingPermissionsBody => '每項權限都能讓通報更有用。任何一項都可以拒絕，仍然可以通報。';

  @override
  String get onboardingStart => '開始使用';

  @override
  String get permLocationTitle => '位置';

  @override
  String get permLocationBody => '將通報標示在地圖上，讓執勤人員知道要到哪裡查看。';

  @override
  String get permCameraTitle => '相機';

  @override
  String get permCameraBody => '讓您對準無人機，並拍攝照片或影片。';

  @override
  String get permMicrophoneTitle => '麥克風';

  @override
  String get permMicrophoneBody => '錄下螺旋槳的聲音，有助於辨識無人機機型。';

  @override
  String get permNearbyTitle => '鄰近裝置（藍牙與 Wi-Fi）';

  @override
  String get permNearbyBody => '接收無人機發出的遙控識別（Remote ID）訊號：包括序號、位置，有時還有操作者的位置。';

  @override
  String get permNotificationsTitle => '通知';

  @override
  String get permNotificationsBody => '案件有新進度時通知您。通知內容不會包含任何案件細節。';

  @override
  String get permAllow => '允許';

  @override
  String get permGranted => '已允許';

  @override
  String get permOpenSettings => '開啟設定';

  @override
  String get homeReportButton => '我要通報';

  @override
  String get homeReportHint => '不到一分鐘即可完成，免註冊。';

  @override
  String get homeMyReports => '我的通報';

  @override
  String get homeNoReports => '這支裝置尚未送出任何通報。';

  @override
  String get homeZonesMap => '禁限航區地圖';

  @override
  String get homeSettings => '設定';

  @override
  String get homeWebBanner =>
      '若無人機正在飛行，建議使用 Android App 通報，資料更準確：可測量無人機的方向，並接收其遙控識別（Remote ID）訊號。';

  @override
  String get homeGetAndroidApp => '下載 Android App';

  @override
  String get homeEvidenceRequested => '需補充資料';

  @override
  String get homePendingSend => '等待送出';

  @override
  String get homeStatusOffline => '最後已知狀態';

  @override
  String get caseNumberLabel => '案件編號';

  @override
  String get reportTitle => '通報';

  @override
  String get stepAim => '對準';

  @override
  String get stepDetails => '詳細資料';

  @override
  String get stepEvidence => '佐證資料';

  @override
  String get locationWaiting => '正在取得您的位置…';

  @override
  String locationAccuracy(int meters) {
    return '位置誤差 ±$meters 公尺';
  }

  @override
  String get locationUnavailable => '定位未開啟或未獲允許。請開啟定位，或在地圖上設定您的位置。';

  @override
  String get locationPickOnMap => '在地圖上設定';

  @override
  String get locationManual => '已在地圖上設定位置';

  @override
  String get mapPickTitle => '請點選您所在的位置';

  @override
  String get mapPickConfirm => '使用此位置';

  @override
  String get remoteIdTitle => '遙控識別（Remote ID）';

  @override
  String remoteIdReceives(String transports) {
    return '接收方式：$transports';
  }

  @override
  String remoteIdCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '偵測到 $count 架發送遙控識別的無人機',
      zero: '附近尚未偵測到發送遙控識別的無人機',
    );
    return '$_temp0';
  }

  @override
  String get remoteIdUnsupported => '這支手機無法接收遙控識別訊號。';

  @override
  String get remoteIdPermission => '請允許「鄰近裝置」權限，以便接收遙控識別訊號。';

  @override
  String get remoteIdUnknownSerial => '尚未收到序號';

  @override
  String remoteIdDistance(int meters) {
    return '距離 $meters 公尺';
  }

  @override
  String remoteIdHeight(int meters) {
    return '高度 $meters 公尺';
  }

  @override
  String get transportBt4 => '藍牙';

  @override
  String get transportBt5 => '藍牙長距離';

  @override
  String get transportWifiBeacon => 'Wi-Fi 信標';

  @override
  String get transportWifiNan => 'Wi-Fi Aware';

  @override
  String get aimInstruction => '將手機對準無人機或船隻，再點「鎖定方向」。';

  @override
  String get aimBearing => '方向';

  @override
  String get aimElevation => '仰角';

  @override
  String get aimCalibrate => '指南針需要校正：請將手機以 8 字形移動幾次。';

  @override
  String get aimNoCompass => '這支裝置沒有指南針資料，可以略過此步驟。';

  @override
  String get aimNoCamera => '無法使用相機';

  @override
  String get aimLock => '鎖定方向';

  @override
  String get aimTakePhoto => '同時拍一張照片';

  @override
  String get aimSkip => '略過對準';

  @override
  String aimLocked(int bearing, int elevation) {
    return '已鎖定方向：$bearing°，仰角 $elevation°';
  }

  @override
  String get aimAgain => '重新對準';

  @override
  String get detailsTitle => '您看到了什麼？';

  @override
  String get detailsOptional => '以下皆為選填，趕時間可以直接略過。';

  @override
  String get detailsHeight => '大約多高？';

  @override
  String get detailsHeightHint => '10 層樓的建築物約 30 公尺高。';

  @override
  String get heightBelow30 => '30 公尺以下';

  @override
  String get height30to60 => '30–60 公尺';

  @override
  String get height60to120 => '60–120 公尺';

  @override
  String get heightAbove120 => '120 公尺以上';

  @override
  String get detailsMovement => '是否在移動？';

  @override
  String get movementHovering => '停在空中';

  @override
  String get movementMoving => '移動中';

  @override
  String get detailsCount => '有幾架無人機？';

  @override
  String get countOne => '1 架';

  @override
  String get countTwo => '2 架';

  @override
  String get countThreePlus => '3 架以上';

  @override
  String get detailsDescription => '其他補充說明（選填）';

  @override
  String get detailsDescriptionHint => '例如：在學校操場上空飛行、有紅色燈光、嗡嗡聲很大';

  @override
  String get evidenceTitle => '照片、影片與聲音';

  @override
  String get evidenceSpeedNote => '儘快送出比完美的佐證更重要。您可以現在就送出，檔案會在背景上傳。';

  @override
  String get mediaPhoto => '照片';

  @override
  String get mediaVideo => '影片';

  @override
  String get mediaAudio => '錄音';

  @override
  String get evidenceRecordSound => '錄下聲音';

  @override
  String get evidenceStopRecording => '停止錄音';

  @override
  String evidenceRecording(int seconds) {
    return '正在錄下螺旋槳聲音… $seconds 秒';
  }

  @override
  String get evidenceNone => '尚未加入任何檔案。';

  @override
  String get evidenceRemove => '移除檔案';

  @override
  String get evidenceAimPhoto => '鎖定方向時拍攝的照片';

  @override
  String get evidenceCaptureFailed => '無法取得檔案，請再試一次。';

  @override
  String get sendNow => '立即送出通報';

  @override
  String get sending => '傳送中…';

  @override
  String get sendQueuedTitle => '通報已儲存';

  @override
  String get sendQueuedBody => '目前沒有網路連線。您的通報已儲存在這支手機上，恢復連線後會自動送出。';

  @override
  String get sendRateLimited => '這支裝置或網路近期送出的通報過多。請稍候幾分鐘再試。如有人身危險，請撥打 110。';

  @override
  String sendRejected(String message) {
    return '無法受理此通報：$message';
  }

  @override
  String get sendFailedTitle => '通報未送出';

  @override
  String get discardTitle => '要捨棄這筆通報嗎？';

  @override
  String get discardBody => '目前尚未送出任何資料。';

  @override
  String get discard => '捨棄';

  @override
  String get sentTitle => '通報已送出';

  @override
  String get sentBody => '感謝您的通報，已轉交負責機關處理。';

  @override
  String sentUploading(int done, int total) {
    return '正在上傳檔案：$done／$total';
  }

  @override
  String get sentUploadsDone => '所有檔案已上傳完成。';

  @override
  String get sentUploadsBackground => '即使關閉 App，檔案仍會在背景繼續上傳。';

  @override
  String get sentUploadsKeepOpen => '請保持此頁面開啟，直到檔案上傳完成。';

  @override
  String get sentKeyNote => '只有這支手機保存追蹤此通報的專屬金鑰。若解除安裝 App 或清除其資料，將無法再查看進度。';

  @override
  String get sentKeyNoteWeb => '只有這個瀏覽器保存追蹤此通報的專屬金鑰。若清除瀏覽器資料，將無法再查看進度。';

  @override
  String get sentAndroidHint =>
      '下次可使用 Android App，它能測量無人機的方向並接收遙控識別訊號，讓您的通報更有用。';

  @override
  String get sentViewStatus => '查看進度';

  @override
  String get sentBackHome => '回到首頁';

  @override
  String caseTitle(String caseNumber) {
    return '案件 $caseNumber';
  }

  @override
  String get caseProgress => '處理進度';

  @override
  String get caseOutcome => '處理結果';

  @override
  String get caseEvidenceRequests => '補充資料請求';

  @override
  String get caseEvidenceSafety => '請只在您所在的位置安全地拍攝或錄製。';

  @override
  String get caseEvidenceAnswered => '已回覆，謝謝您。';

  @override
  String caseEvidenceSend(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '送出 $count 個檔案',
    );
    return '$_temp0';
  }

  @override
  String get caseEvidenceSent => '謝謝您，檔案正在上傳。';

  @override
  String get caseEvidenceClosed => '此請求已結束。';

  @override
  String get caseNotOnDevice => '這支裝置上沒有這筆通報。';

  @override
  String caseUpdated(String time) {
    return '更新時間：$time';
  }

  @override
  String get zonesTitle => '禁限航區';

  @override
  String get zonesLegend => '圖例';

  @override
  String get zonesMyLocation => '我的位置';

  @override
  String get zonesNote => '僅顯示民航局公告的無人機禁限航區，部分管制區域不會在公開地圖上顯示。';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsPrivacy => '隱私權與關於';

  @override
  String get settingsPrivacyBody =>
      'reporting.tw 是我國政府提供的可疑無人機、無人艇及其他不明空中、海上或岸際載具通報服務。通報全程匿名：我們不會要求您的姓名、電話或帳號。通報內容包含您的位置、手機對準的方向、您對問題的回答、您提供的照片、影片或聲音、手機收到的遙控識別（Remote ID）訊號，以及安裝 App 時隨機產生的識別碼。照片可能由 AI 模型自動分析，協助值勤人員研判。這些資料僅供我國主管機關處理相關事件使用。';

  @override
  String get settingsClearHistory => '清除通報紀錄';

  @override
  String get settingsClearHistoryBody =>
      '這會從這支裝置上刪除您的通報紀錄及其專屬追蹤金鑰。刪除後將無法再查看這些通報的進度或回覆補充資料請求。已送出的通報不會撤回。';

  @override
  String get settingsClear => '清除';

  @override
  String get settingsHistoryCleared => '通報紀錄已清除。';

  @override
  String get settingsShowIntro => '重新查看使用說明';

  @override
  String settingsVersion(String version) {
    return '版本 $version';
  }
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class InformantL10nZhTw extends InformantL10nZh {
  InformantL10nZhTw() : super('zh_TW');

  @override
  String get skip => '略過';

  @override
  String get notSure => '不確定';

  @override
  String get onboardingLanguageTitle => '請選擇語言';

  @override
  String get onboardingLanguageBody => '之後可隨時在「設定」中變更。';

  @override
  String get onboardingWhatTitle => '通報可疑無人機、無人艇與其他不明載具';

  @override
  String get onboardingWhatBody =>
      '在機場或軍事設施附近看到無人機、在海上看到無人小艇，或有船隻在海灘靠岸？一分鐘內就能完成通報，系統會直接轉給負責的機關：警察、民航、海巡或國防單位。';

  @override
  String get onboardingSafetyTitle => '安全第一';

  @override
  String get onboardingSafetyApproach => '切勿靠近或跟蹤無人機操作者。';

  @override
  String get onboardingSafetyDistance => '與無人機保持距離，並注意周遭交通。';

  @override
  String get onboardingSafetyDanger => '如有人身危險，請先撥打 110。';

  @override
  String get onboardingPrivacyTitle => '全程匿名';

  @override
  String get onboardingPrivacyNoAccount => '我們不會要求您提供姓名、電話號碼或註冊帳號。';

  @override
  String get onboardingPrivacyCollected =>
      '通報內容包括：您的位置、手機指向的方向、您加入的照片、影片或聲音，以及安裝 App 時產生的隨機識別碼。';

  @override
  String get onboardingPrivacyUse => '通報資料僅供臺灣政府主管機關處理無人機與海上事件使用。';

  @override
  String get onboardingPermissionsTitle => '權限說明';

  @override
  String get onboardingPermissionsBody => '每項權限都能讓通報更有用。任何一項都可以拒絕，仍然可以通報。';

  @override
  String get onboardingStart => '開始使用';

  @override
  String get permLocationTitle => '位置';

  @override
  String get permLocationBody => '將通報標示在地圖上，讓執勤人員知道要到哪裡查看。';

  @override
  String get permCameraTitle => '相機';

  @override
  String get permCameraBody => '讓您對準無人機，並拍攝照片或影片。';

  @override
  String get permMicrophoneTitle => '麥克風';

  @override
  String get permMicrophoneBody => '錄下螺旋槳的聲音，有助於辨識無人機機型。';

  @override
  String get permNearbyTitle => '鄰近裝置（藍牙與 Wi-Fi）';

  @override
  String get permNearbyBody => '接收無人機發出的遙控識別（Remote ID）訊號：包括序號、位置，有時還有操作者的位置。';

  @override
  String get permNotificationsTitle => '通知';

  @override
  String get permNotificationsBody => '案件有新進度時通知您。通知內容不會包含任何案件細節。';

  @override
  String get permAllow => '允許';

  @override
  String get permGranted => '已允許';

  @override
  String get permOpenSettings => '開啟設定';

  @override
  String get homeReportButton => '我要通報';

  @override
  String get homeReportHint => '不到一分鐘即可完成，免註冊。';

  @override
  String get homeMyReports => '我的通報';

  @override
  String get homeNoReports => '這支裝置尚未送出任何通報。';

  @override
  String get homeZonesMap => '禁限航區地圖';

  @override
  String get homeSettings => '設定';

  @override
  String get homeWebBanner =>
      '若無人機正在飛行，建議使用 Android App 通報，資料更準確：可測量無人機的方向，並接收其遙控識別（Remote ID）訊號。';

  @override
  String get homeGetAndroidApp => '下載 Android App';

  @override
  String get homeEvidenceRequested => '需補充資料';

  @override
  String get homePendingSend => '等待送出';

  @override
  String get homeStatusOffline => '最後已知狀態';

  @override
  String get caseNumberLabel => '案件編號';

  @override
  String get reportTitle => '通報';

  @override
  String get stepAim => '對準';

  @override
  String get stepDetails => '詳細資料';

  @override
  String get stepEvidence => '佐證資料';

  @override
  String get locationWaiting => '正在取得您的位置…';

  @override
  String locationAccuracy(int meters) {
    return '位置誤差 ±$meters 公尺';
  }

  @override
  String get locationUnavailable => '定位未開啟或未獲允許。請開啟定位，或在地圖上設定您的位置。';

  @override
  String get locationPickOnMap => '在地圖上設定';

  @override
  String get locationManual => '已在地圖上設定位置';

  @override
  String get mapPickTitle => '請點選您所在的位置';

  @override
  String get mapPickConfirm => '使用此位置';

  @override
  String get remoteIdTitle => '遙控識別（Remote ID）';

  @override
  String remoteIdReceives(String transports) {
    return '接收方式：$transports';
  }

  @override
  String remoteIdCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '偵測到 $count 架發送遙控識別的無人機',
      zero: '附近尚未偵測到發送遙控識別的無人機',
    );
    return '$_temp0';
  }

  @override
  String get remoteIdUnsupported => '這支手機無法接收遙控識別訊號。';

  @override
  String get remoteIdPermission => '請允許「鄰近裝置」權限，以便接收遙控識別訊號。';

  @override
  String get remoteIdUnknownSerial => '尚未收到序號';

  @override
  String remoteIdDistance(int meters) {
    return '距離 $meters 公尺';
  }

  @override
  String remoteIdHeight(int meters) {
    return '高度 $meters 公尺';
  }

  @override
  String get transportBt4 => '藍牙';

  @override
  String get transportBt5 => '藍牙長距離';

  @override
  String get transportWifiBeacon => 'Wi-Fi 信標';

  @override
  String get transportWifiNan => 'Wi-Fi Aware';

  @override
  String get aimInstruction => '將手機對準無人機或船隻，再點「鎖定方向」。';

  @override
  String get aimBearing => '方向';

  @override
  String get aimElevation => '仰角';

  @override
  String get aimCalibrate => '指南針需要校正：請將手機以 8 字形移動幾次。';

  @override
  String get aimNoCompass => '這支裝置沒有指南針資料，可以略過此步驟。';

  @override
  String get aimNoCamera => '無法使用相機';

  @override
  String get aimLock => '鎖定方向';

  @override
  String get aimTakePhoto => '同時拍一張照片';

  @override
  String get aimSkip => '略過對準';

  @override
  String aimLocked(int bearing, int elevation) {
    return '已鎖定方向：$bearing°，仰角 $elevation°';
  }

  @override
  String get aimAgain => '重新對準';

  @override
  String get detailsTitle => '您看到了什麼？';

  @override
  String get detailsOptional => '以下皆為選填，趕時間可以直接略過。';

  @override
  String get detailsHeight => '大約多高？';

  @override
  String get detailsHeightHint => '10 層樓的建築物約 30 公尺高。';

  @override
  String get heightBelow30 => '30 公尺以下';

  @override
  String get height30to60 => '30–60 公尺';

  @override
  String get height60to120 => '60–120 公尺';

  @override
  String get heightAbove120 => '120 公尺以上';

  @override
  String get detailsMovement => '是否在移動？';

  @override
  String get movementHovering => '停在空中';

  @override
  String get movementMoving => '移動中';

  @override
  String get detailsCount => '有幾架無人機？';

  @override
  String get countOne => '1 架';

  @override
  String get countTwo => '2 架';

  @override
  String get countThreePlus => '3 架以上';

  @override
  String get detailsDescription => '其他補充說明（選填）';

  @override
  String get detailsDescriptionHint => '例如：在學校操場上空飛行、有紅色燈光、嗡嗡聲很大';

  @override
  String get evidenceTitle => '照片、影片與聲音';

  @override
  String get evidenceSpeedNote => '儘快送出比完美的佐證更重要。您可以現在就送出，檔案會在背景上傳。';

  @override
  String get mediaPhoto => '照片';

  @override
  String get mediaVideo => '影片';

  @override
  String get mediaAudio => '錄音';

  @override
  String get evidenceRecordSound => '錄下聲音';

  @override
  String get evidenceStopRecording => '停止錄音';

  @override
  String evidenceRecording(int seconds) {
    return '正在錄下螺旋槳聲音… $seconds 秒';
  }

  @override
  String get evidenceNone => '尚未加入任何檔案。';

  @override
  String get evidenceRemove => '移除檔案';

  @override
  String get evidenceAimPhoto => '鎖定方向時拍攝的照片';

  @override
  String get evidenceCaptureFailed => '無法取得檔案，請再試一次。';

  @override
  String get sendNow => '立即送出通報';

  @override
  String get sending => '傳送中…';

  @override
  String get sendQueuedTitle => '通報已儲存';

  @override
  String get sendQueuedBody => '目前沒有網路連線。您的通報已儲存在這支手機上，恢復連線後會自動送出。';

  @override
  String get sendRateLimited => '這支裝置或網路近期送出的通報過多。請稍候幾分鐘再試。如有人身危險，請撥打 110。';

  @override
  String sendRejected(String message) {
    return '無法受理此通報：$message';
  }

  @override
  String get sendFailedTitle => '通報未送出';

  @override
  String get discardTitle => '要捨棄這筆通報嗎？';

  @override
  String get discardBody => '目前尚未送出任何資料。';

  @override
  String get discard => '捨棄';

  @override
  String get sentTitle => '通報已送出';

  @override
  String get sentBody => '感謝您的通報，已轉交負責機關處理。';

  @override
  String sentUploading(int done, int total) {
    return '正在上傳檔案：$done／$total';
  }

  @override
  String get sentUploadsDone => '所有檔案已上傳完成。';

  @override
  String get sentUploadsBackground => '即使關閉 App，檔案仍會在背景繼續上傳。';

  @override
  String get sentUploadsKeepOpen => '請保持此頁面開啟，直到檔案上傳完成。';

  @override
  String get sentKeyNote => '只有這支手機保存追蹤此通報的專屬金鑰。若解除安裝 App 或清除其資料，將無法再查看進度。';

  @override
  String get sentKeyNoteWeb => '只有這個瀏覽器保存追蹤此通報的專屬金鑰。若清除瀏覽器資料，將無法再查看進度。';

  @override
  String get sentAndroidHint =>
      '下次可使用 Android App，它能測量無人機的方向並接收遙控識別訊號，讓您的通報更有用。';

  @override
  String get sentViewStatus => '查看進度';

  @override
  String get sentBackHome => '回到首頁';

  @override
  String caseTitle(String caseNumber) {
    return '案件 $caseNumber';
  }

  @override
  String get caseProgress => '處理進度';

  @override
  String get caseOutcome => '處理結果';

  @override
  String get caseEvidenceRequests => '補充資料請求';

  @override
  String get caseEvidenceSafety => '請只在您所在的位置安全地拍攝或錄製。';

  @override
  String get caseEvidenceAnswered => '已回覆，謝謝您。';

  @override
  String caseEvidenceSend(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '送出 $count 個檔案',
    );
    return '$_temp0';
  }

  @override
  String get caseEvidenceSent => '謝謝您，檔案正在上傳。';

  @override
  String get caseEvidenceClosed => '此請求已結束。';

  @override
  String get caseNotOnDevice => '這支裝置上沒有這筆通報。';

  @override
  String caseUpdated(String time) {
    return '更新時間：$time';
  }

  @override
  String get zonesTitle => '禁限航區';

  @override
  String get zonesLegend => '圖例';

  @override
  String get zonesMyLocation => '我的位置';

  @override
  String get zonesNote => '僅顯示民航局公告的無人機禁限航區，部分管制區域不會在公開地圖上顯示。';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsPrivacy => '隱私權與關於';

  @override
  String get settingsPrivacyBody =>
      'reporting.tw 是我國政府提供的可疑無人機、無人艇及其他不明空中、海上或岸際載具通報服務。通報全程匿名：我們不會要求您的姓名、電話或帳號。通報內容包含您的位置、手機對準的方向、您對問題的回答、您提供的照片、影片或聲音、手機收到的遙控識別（Remote ID）訊號，以及安裝 App 時隨機產生的識別碼。照片可能由 AI 模型自動分析，協助值勤人員研判。這些資料僅供我國主管機關處理相關事件使用。';

  @override
  String get settingsClearHistory => '清除通報紀錄';

  @override
  String get settingsClearHistoryBody =>
      '這會從這支裝置上刪除您的通報紀錄及其專屬追蹤金鑰。刪除後將無法再查看這些通報的進度或回覆補充資料請求。已送出的通報不會撤回。';

  @override
  String get settingsClear => '清除';

  @override
  String get settingsHistoryCleared => '通報紀錄已清除。';

  @override
  String get settingsShowIntro => '重新查看使用說明';

  @override
  String settingsVersion(String version) {
    return '版本 $version';
  }
}
