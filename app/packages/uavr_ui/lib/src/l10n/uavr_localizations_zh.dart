// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'uavr_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class UavrL10nZh extends UavrL10n {
  UavrL10nZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '可疑載具通報';

  @override
  String get demoDisclaimer =>
      '本系統為「Taiwan Defense Tech Hackathon 2026」展示用途，並非政府官方服務。';

  @override
  String get ok => '確定';

  @override
  String get cancel => '取消';

  @override
  String get retry => '重試';

  @override
  String get close => '關閉';

  @override
  String get back => '上一步';

  @override
  String get next => '下一步';

  @override
  String get done => '完成';

  @override
  String get save => '儲存';

  @override
  String get send => '送出';

  @override
  String get loading => '載入中…';

  @override
  String get errorGeneric => '發生錯誤。';

  @override
  String get errorNetwork => '無法連線到伺服器。';

  @override
  String get offline => '目前離線';

  @override
  String get severityCritical => '緊急';

  @override
  String get severityMedium => '中度';

  @override
  String get severityLow => '低度';

  @override
  String get statusReceived => '已受理';

  @override
  String get statusInReview => '審查中';

  @override
  String get statusInProgress => '處理中';

  @override
  String get statusCompleted => '已結案';

  @override
  String get zoneAirport => '機場';

  @override
  String get zoneRed => '禁航區（紅區）';

  @override
  String get zoneYellow => '限航區（黃區）';

  @override
  String get zoneMilitary => '軍事管制區';

  @override
  String get zoneCriticalInfrastructure => '關鍵基礎設施';

  @override
  String get zoneOutlyingStrict => '外島限航區';

  @override
  String get zoneResidential => '住宅區';

  @override
  String get zoneOpen => '開放區域';

  @override
  String get zoneJurisdiction => '轄區';

  @override
  String get languageLabel => '語言';

  @override
  String get languageSelfName => '繁體中文';

  @override
  String get justNow => '剛剛';

  @override
  String get emergency110 => '如有人身危險，請立即撥打 110。';

  @override
  String minutesAgo(int count) {
    return '$count 分鐘前';
  }

  @override
  String hoursAgo(int count) {
    return '$count 小時前';
  }
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class UavrL10nZhTw extends UavrL10nZh {
  UavrL10nZhTw() : super('zh_TW');

  @override
  String get appName => '可疑載具通報';

  @override
  String get demoDisclaimer =>
      '本系統為「Taiwan Defense Tech Hackathon 2026」展示用途，並非政府官方服務。';

  @override
  String get ok => '確定';

  @override
  String get cancel => '取消';

  @override
  String get retry => '重試';

  @override
  String get close => '關閉';

  @override
  String get back => '上一步';

  @override
  String get next => '下一步';

  @override
  String get done => '完成';

  @override
  String get save => '儲存';

  @override
  String get send => '送出';

  @override
  String get loading => '載入中…';

  @override
  String get errorGeneric => '發生錯誤。';

  @override
  String get errorNetwork => '無法連線到伺服器。';

  @override
  String get offline => '目前離線';

  @override
  String get severityCritical => '緊急';

  @override
  String get severityMedium => '中度';

  @override
  String get severityLow => '低度';

  @override
  String get statusReceived => '已受理';

  @override
  String get statusInReview => '審查中';

  @override
  String get statusInProgress => '處理中';

  @override
  String get statusCompleted => '已結案';

  @override
  String get zoneAirport => '機場';

  @override
  String get zoneRed => '禁航區（紅區）';

  @override
  String get zoneYellow => '限航區（黃區）';

  @override
  String get zoneMilitary => '軍事管制區';

  @override
  String get zoneCriticalInfrastructure => '關鍵基礎設施';

  @override
  String get zoneOutlyingStrict => '外島限航區';

  @override
  String get zoneResidential => '住宅區';

  @override
  String get zoneOpen => '開放區域';

  @override
  String get zoneJurisdiction => '轄區';

  @override
  String get languageLabel => '語言';

  @override
  String get languageSelfName => '繁體中文';

  @override
  String get justNow => '剛剛';

  @override
  String get emergency110 => '如有人身危險，請立即撥打 110。';

  @override
  String minutesAgo(int count) {
    return '$count 分鐘前';
  }

  @override
  String hoursAgo(int count) {
    return '$count 小時前';
  }
}
