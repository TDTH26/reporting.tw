// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'uavr_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class UavrL10nTh extends UavrL10n {
  UavrL10nTh([String locale = 'th']) : super(locale);

  @override
  String get appName => 'แจ้งยานพาหนะต้องสงสัย';

  @override
  String get demoDisclaimer =>
      'เดโมสำหรับ “Taiwan Defense Tech Hackathon 2026” ไม่ใช่บริการอย่างเป็นทางการของรัฐบาล';

  @override
  String get ok => 'ตกลง';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get retry => 'ลองอีกครั้ง';

  @override
  String get close => 'ปิด';

  @override
  String get back => 'ย้อนกลับ';

  @override
  String get next => 'ถัดไป';

  @override
  String get done => 'เสร็จสิ้น';

  @override
  String get save => 'บันทึก';

  @override
  String get send => 'ส่ง';

  @override
  String get loading => 'กำลังโหลด…';

  @override
  String get errorGeneric => 'เกิดข้อผิดพลาด';

  @override
  String get errorNetwork => 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้';

  @override
  String get offline => 'คุณออฟไลน์อยู่';

  @override
  String get severityCritical => 'วิกฤต';

  @override
  String get severityMedium => 'ปานกลาง';

  @override
  String get severityLow => 'ต่ำ';

  @override
  String get statusReceived => 'ได้รับแล้ว';

  @override
  String get statusInReview => 'กำลังตรวจสอบ';

  @override
  String get statusInProgress => 'กำลังดำเนินการ';

  @override
  String get statusCompleted => 'เสร็จสิ้น';

  @override
  String get zoneAirport => 'สนามบิน';

  @override
  String get zoneRed => 'เขตห้ามบิน (แดง)';

  @override
  String get zoneYellow => 'เขตจำกัด (เหลือง)';

  @override
  String get zoneMilitary => 'เขตทหาร';

  @override
  String get zoneCriticalInfrastructure => 'โครงสร้างพื้นฐานสำคัญ';

  @override
  String get zoneOutlyingStrict => 'เขตจำกัดเกาะนอกชายฝั่ง';

  @override
  String get zoneResidential => 'เขตที่อยู่อาศัย';

  @override
  String get zoneOpen => 'พื้นที่เปิด';

  @override
  String get zoneJurisdiction => 'เขตอำนาจ';

  @override
  String get languageLabel => 'ภาษา';

  @override
  String get languageSelfName => 'ภาษาไทย';

  @override
  String get justNow => 'เมื่อสักครู่';

  @override
  String get emergency110 => 'หากมีผู้ตกอยู่ในอันตราย โทร 110 ทันที';

  @override
  String minutesAgo(int count) {
    return '$count นาทีที่แล้ว';
  }

  @override
  String hoursAgo(int count) {
    return '$count ชั่วโมงที่แล้ว';
  }
}
