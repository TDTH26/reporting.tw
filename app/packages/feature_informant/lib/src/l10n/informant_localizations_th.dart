// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'informant_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class InformantL10nTh extends InformantL10n {
  InformantL10nTh([String locale = 'th']) : super(locale);

  @override
  String get skip => 'ข้าม';

  @override
  String get notSure => 'ไม่แน่ใจ';

  @override
  String get onboardingLanguageTitle => 'เลือกภาษา';

  @override
  String get onboardingLanguageBody =>
      'คุณเปลี่ยนภาษาได้ทุกเมื่อในหน้าการตั้งค่า';

  @override
  String get onboardingWhatTitle =>
      'แจ้งโดรน เรือไร้คนขับ และยานพาหนะต้องสงสัย';

  @override
  String get onboardingWhatBody =>
      'เห็นโดรนใกล้สนามบินหรือเขตทหาร เรือไร้คนขับนอกชายฝั่ง หรือยานพาหนะขึ้นฝั่งที่ชายหาด? แจ้งได้ภายในหนึ่งนาที รายงานจะส่งตรงถึงหน่วยงานที่รับผิดชอบ: ตำรวจ การบินพลเรือน หน่วยยามฝั่ง หรือฝ่ายป้องกัน';

  @override
  String get onboardingSafetyTitle => 'ความปลอดภัยของคุณสำคัญที่สุด';

  @override
  String get onboardingSafetyApproach =>
      'ห้ามเข้าใกล้หรือติดตามผู้บังคับโดรนโดยเด็ดขาด';

  @override
  String get onboardingSafetyDistance => 'อยู่ห่างจากโดรน และระวังรถรอบตัวคุณ';

  @override
  String get onboardingSafetyDanger =>
      'หากมีผู้ใดตกอยู่ในอันตราย ให้โทร 110 ก่อน';

  @override
  String get onboardingPrivacyTitle => 'ไม่ต้องเปิดเผยตัวตน';

  @override
  String get onboardingPrivacyNoAccount =>
      'เราไม่เคยขอชื่อ หมายเลขโทรศัพท์ หรือบัญชีผู้ใช้ของคุณ';

  @override
  String get onboardingPrivacyCollected =>
      'รายงานประกอบด้วยตำแหน่งของคุณ ทิศทางที่คุณหันโทรศัพท์ รูปภาพ วิดีโอ หรือเสียงที่คุณเพิ่ม และรหัสสุ่มที่สร้างขึ้นตอนติดตั้งแอป';

  @override
  String get onboardingPrivacyUse =>
      'รายงานใช้โดยหน่วยงานรัฐของไต้หวันเพื่อจัดการเหตุเกี่ยวกับโดรนและทางทะเลเท่านั้น';

  @override
  String get onboardingPermissionsTitle => 'การอนุญาต';

  @override
  String get onboardingPermissionsBody =>
      'การอนุญาตแต่ละรายการช่วยให้รายงานของคุณมีประโยชน์มากขึ้น คุณปฏิเสธรายการใดก็ได้และยังคงส่งรายงานได้';

  @override
  String get onboardingStart => 'เริ่มใช้งาน';

  @override
  String get permLocationTitle => 'ตำแหน่ง';

  @override
  String get permLocationBody =>
      'ระบุรายงานของคุณบนแผนที่ เพื่อให้เจ้าหน้าที่รู้ว่าต้องไปตรวจสอบที่ใด';

  @override
  String get permCameraTitle => 'กล้อง';

  @override
  String get permCameraBody => 'ใช้เล็งไปที่โดรน และถ่ายรูปหรือวิดีโอ';

  @override
  String get permMicrophoneTitle => 'ไมโครโฟน';

  @override
  String get permMicrophoneBody => 'บันทึกเสียงใบพัด ซึ่งช่วยระบุประเภทของโดรน';

  @override
  String get permNearbyTitle => 'อุปกรณ์ใกล้เคียง (บลูทูธและ Wi-Fi)';

  @override
  String get permNearbyBody =>
      'รับสัญญาณ Remote ID ที่โดรนส่งออกมา ได้แก่ หมายเลขซีเรียล ตำแหน่ง และบางครั้งตำแหน่งของผู้บังคับด้วย';

  @override
  String get permNotificationsTitle => 'การแจ้งเตือน';

  @override
  String get permNotificationsBody =>
      'แจ้งให้คุณทราบเมื่อเรื่องของคุณมีความคืบหน้า การแจ้งเตือนจะไม่มีรายละเอียดของเรื่อง';

  @override
  String get permAllow => 'อนุญาต';

  @override
  String get permGranted => 'อนุญาตแล้ว';

  @override
  String get permOpenSettings => 'เปิดการตั้งค่า';

  @override
  String get homeReportButton => 'แจ้งเหตุ';

  @override
  String get homeReportHint => 'ใช้เวลาไม่ถึงหนึ่งนาที ไม่ต้องลงทะเบียน';

  @override
  String get homeMyReports => 'รายงานของฉัน';

  @override
  String get homeNoReports => 'คุณยังไม่ได้ส่งรายงานจากอุปกรณ์นี้';

  @override
  String get homeZonesMap => 'แผนที่เขตห้ามบิน';

  @override
  String get homeSettings => 'การตั้งค่า';

  @override
  String get homeWebBanner =>
      'หากโดรนกำลังบินอยู่ แอป Android จะส่งรายงานที่แม่นยำกว่า เพราะวัดทิศทางไปยังโดรนได้และรับสัญญาณ Remote ID ของโดรนได้';

  @override
  String get homeGetAndroidApp => 'ดาวน์โหลดแอป Android';

  @override
  String get homeEvidenceRequested => 'ขอหลักฐานเพิ่มเติม';

  @override
  String get homePendingSend => 'รอส่ง';

  @override
  String get homeStatusOffline => 'สถานะล่าสุดที่ทราบ';

  @override
  String get caseNumberLabel => 'หมายเลขเรื่อง';

  @override
  String get reportTitle => 'แจ้งเหตุ';

  @override
  String get stepAim => 'เล็ง';

  @override
  String get stepDetails => 'รายละเอียด';

  @override
  String get stepEvidence => 'หลักฐาน';

  @override
  String get locationWaiting => 'กำลังหาตำแหน่งของคุณ…';

  @override
  String locationAccuracy(int meters) {
    return 'ตำแหน่ง ±$meters ม.';
  }

  @override
  String get locationUnavailable =>
      'ตำแหน่งปิดอยู่หรือไม่ได้รับอนุญาต โปรดเปิดตำแหน่ง หรือกำหนดตำแหน่งของคุณบนแผนที่';

  @override
  String get locationPickOnMap => 'กำหนดบนแผนที่';

  @override
  String get locationManual => 'กำหนดตำแหน่งบนแผนที่แล้ว';

  @override
  String get mapPickTitle => 'แตะตรงจุดที่คุณอยู่';

  @override
  String get mapPickConfirm => 'ใช้ตำแหน่งนี้';

  @override
  String get remoteIdTitle => 'Remote ID';

  @override
  String remoteIdReceives(String transports) {
    return 'กำลังรับผ่าน: $transports';
  }

  @override
  String remoteIdCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'พบโดรน $count ลำที่ส่ง Remote ID',
      zero: 'ยังไม่พบโดรนที่ส่ง Remote ID ในบริเวณใกล้เคียง',
    );
    return '$_temp0';
  }

  @override
  String get remoteIdUnsupported =>
      'โทรศัพท์เครื่องนี้รับสัญญาณ Remote ID ไม่ได้';

  @override
  String get remoteIdPermission =>
      'โปรดอนุญาต \"อุปกรณ์ใกล้เคียง\" เพื่อให้แอปรับสัญญาณ Remote ID ได้';

  @override
  String get remoteIdUnknownSerial => 'ยังไม่ได้รับหมายเลขซีเรียล';

  @override
  String remoteIdDistance(int meters) {
    return 'ห่าง $meters ม.';
  }

  @override
  String remoteIdHeight(int meters) {
    return 'สูง $meters ม.';
  }

  @override
  String get transportBt4 => 'บลูทูธ';

  @override
  String get transportBt5 => 'บลูทูธระยะไกล';

  @override
  String get transportWifiBeacon => 'Wi-Fi beacon';

  @override
  String get transportWifiNan => 'Wi-Fi Aware';

  @override
  String get aimInstruction =>
      'หันโทรศัพท์ไปที่โดรนหรือเรือ แล้วแตะ \"ล็อกทิศทาง\"';

  @override
  String get aimBearing => 'ทิศทาง';

  @override
  String get aimElevation => 'มุมเงย';

  @override
  String get aimCalibrate =>
      'เข็มทิศต้องปรับเทียบ: ขยับโทรศัพท์เป็นรูปเลข 8 สักสองสามครั้ง';

  @override
  String get aimNoCompass =>
      'อุปกรณ์นี้ไม่มีข้อมูลเข็มทิศ คุณข้ามขั้นตอนนี้ได้';

  @override
  String get aimNoCamera => 'ใช้กล้องไม่ได้';

  @override
  String get aimLock => 'ล็อกทิศทาง';

  @override
  String get aimTakePhoto => 'ถ่ายรูปไปด้วย';

  @override
  String get aimSkip => 'ข้ามการเล็ง';

  @override
  String aimLocked(int bearing, int elevation) {
    return 'ล็อกทิศทางแล้ว: $bearing° เงย $elevation°';
  }

  @override
  String get aimAgain => 'เล็งใหม่';

  @override
  String get detailsTitle => 'คุณเห็นอะไร';

  @override
  String get detailsOptional => 'ทุกข้อในหน้านี้ไม่บังคับ หากรีบสามารถข้ามได้';

  @override
  String get detailsHeight => 'บินสูงประมาณเท่าไร';

  @override
  String get detailsHeightHint => 'อาคาร 10 ชั้นสูงประมาณ 30 ม.';

  @override
  String get heightBelow30 => 'ต่ำกว่า 30 ม.';

  @override
  String get height30to60 => '30–60 ม.';

  @override
  String get height60to120 => '60–120 ม.';

  @override
  String get heightAbove120 => 'สูงกว่า 120 ม.';

  @override
  String get detailsMovement => 'โดรนเคลื่อนที่หรือไม่';

  @override
  String get movementHovering => 'ลอยนิ่ง';

  @override
  String get movementMoving => 'กำลังเคลื่อนที่';

  @override
  String get detailsCount => 'มีโดรนกี่ลำ';

  @override
  String get countOne => '1';

  @override
  String get countTwo => '2';

  @override
  String get countThreePlus => '3 ลำขึ้นไป';

  @override
  String get detailsDescription => 'มีข้อมูลอื่นเพิ่มเติมไหม (ไม่บังคับ)';

  @override
  String get detailsDescriptionHint =>
      'เช่น บินเหนือสนามโรงเรียน มีไฟสีแดง เสียงหึ่งดังมาก';

  @override
  String get evidenceTitle => 'รูปภาพ วิดีโอ และเสียง';

  @override
  String get evidenceSpeedNote =>
      'การส่งให้เร็วสำคัญกว่าหลักฐานที่สมบูรณ์แบบ คุณส่งได้เลยตอนนี้ ไฟล์จะอัปโหลดอยู่เบื้องหลัง';

  @override
  String get mediaPhoto => 'รูปภาพ';

  @override
  String get mediaVideo => 'วิดีโอ';

  @override
  String get mediaAudio => 'เสียงที่บันทึก';

  @override
  String get evidenceRecordSound => 'บันทึกเสียง';

  @override
  String get evidenceStopRecording => 'หยุดบันทึก';

  @override
  String evidenceRecording(int seconds) {
    return 'กำลังบันทึกเสียงใบพัด… $seconds วินาที';
  }

  @override
  String get evidenceNone => 'ยังไม่ได้เพิ่มไฟล์';

  @override
  String get evidenceRemove => 'ลบไฟล์';

  @override
  String get evidenceAimPhoto => 'รูปที่ถ่ายตอนล็อกทิศทาง';

  @override
  String get evidenceCaptureFailed => 'ไม่สามารถรับไฟล์ได้ โปรดลองอีกครั้ง';

  @override
  String get sendNow => 'ส่งรายงานเลย';

  @override
  String get sending => 'กำลังส่ง…';

  @override
  String get sendQueuedTitle => 'บันทึกรายงานแล้ว';

  @override
  String get sendQueuedBody =>
      'ขณะนี้ไม่มีการเชื่อมต่อ รายงานของคุณถูกบันทึกไว้ในโทรศัพท์เครื่องนี้ และจะส่งโดยอัตโนมัติเมื่อกลับมาออนไลน์';

  @override
  String get sendRateLimited =>
      'มีการส่งรายงานจากอุปกรณ์หรือเครือข่ายนี้มากเกินไปในช่วงนี้ โปรดรอสักครู่แล้วลองอีกครั้ง หากมีผู้ใดตกอยู่ในอันตราย ให้โทร 110';

  @override
  String sendRejected(String message) {
    return 'ไม่สามารถรับรายงานได้: $message';
  }

  @override
  String get sendFailedTitle => 'ยังไม่ได้ส่งรายงาน';

  @override
  String get discardTitle => 'ยกเลิกรายงานนี้หรือไม่';

  @override
  String get discardBody => 'ยังไม่มีข้อมูลใดถูกส่งออกไป';

  @override
  String get discard => 'ยกเลิกรายงาน';

  @override
  String get sentTitle => 'ส่งรายงานแล้ว';

  @override
  String get sentBody =>
      'ขอบคุณ รายงานของคุณถูกส่งต่อให้หน่วยงานที่รับผิดชอบแล้ว';

  @override
  String sentUploading(int done, int total) {
    return 'กำลังอัปโหลดไฟล์: $done จาก $total';
  }

  @override
  String get sentUploadsDone => 'อัปโหลดไฟล์ครบแล้ว';

  @override
  String get sentUploadsBackground =>
      'การอัปโหลดจะดำเนินต่อเบื้องหลัง แม้คุณจะปิดแอป';

  @override
  String get sentUploadsKeepOpen =>
      'โปรดเปิดหน้านี้ค้างไว้จนกว่าไฟล์จะอัปโหลดเสร็จ';

  @override
  String get sentKeyNote =>
      'มีเพียงโทรศัพท์เครื่องนี้ที่เก็บกุญแจส่วนตัวสำหรับติดตามรายงานนี้ หากคุณถอนการติดตั้งแอปหรือล้างข้อมูลแอป คุณจะไม่เห็นความคืบหน้าอีก';

  @override
  String get sentKeyNoteWeb =>
      'มีเพียงเบราว์เซอร์นี้ที่เก็บกุญแจส่วนตัวสำหรับติดตามรายงานนี้ หากคุณล้างข้อมูลเบราว์เซอร์ คุณจะไม่เห็นความคืบหน้าอีก';

  @override
  String get sentAndroidHint =>
      'ครั้งหน้า แอป Android สามารถวัดทิศทางไปยังโดรนและรับสัญญาณ Remote ID ได้ ซึ่งทำให้รายงานของคุณมีประโยชน์มากขึ้น';

  @override
  String get sentViewStatus => 'ดูสถานะ';

  @override
  String get sentBackHome => 'กลับหน้าหลัก';

  @override
  String caseTitle(String caseNumber) {
    return 'เรื่อง $caseNumber';
  }

  @override
  String get caseProgress => 'ความคืบหน้า';

  @override
  String get caseOutcome => 'ผลการดำเนินการ';

  @override
  String get caseEvidenceRequests => 'คำขอหลักฐานเพิ่มเติม';

  @override
  String get caseEvidenceSafety =>
      'โปรดส่งเฉพาะสิ่งที่คุณบันทึกได้อย่างปลอดภัยจากจุดที่คุณอยู่';

  @override
  String get caseEvidenceAnswered => 'ตอบแล้ว ขอบคุณ';

  @override
  String caseEvidenceSend(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ส่ง $count ไฟล์',
    );
    return '$_temp0';
  }

  @override
  String get caseEvidenceSent => 'ขอบคุณ กำลังอัปโหลดไฟล์ของคุณ';

  @override
  String get caseEvidenceClosed => 'คำขอนี้ปิดแล้ว';

  @override
  String get caseNotOnDevice => 'ไม่มีรายงานนี้ในอุปกรณ์เครื่องนี้';

  @override
  String caseUpdated(String time) {
    return 'อัปเดตเมื่อ $time';
  }

  @override
  String get zonesTitle => 'เขตห้ามบิน';

  @override
  String get zonesLegend => 'คำอธิบายสัญลักษณ์';

  @override
  String get zonesMyLocation => 'ตำแหน่งของฉัน';

  @override
  String get zonesNote =>
      'แสดงเฉพาะเขตการบินโดรนที่สำนักงานการบินพลเรือน (CAA) ประกาศเท่านั้น พื้นที่หวงห้ามบางแห่งไม่แสดงบนแผนที่สาธารณะ';

  @override
  String get settingsTitle => 'การตั้งค่า';

  @override
  String get settingsPrivacy => 'ความเป็นส่วนตัวและเกี่ยวกับแอป';

  @override
  String get settingsPrivacyBody =>
      'reporting.tw เป็นบริการของรัฐบาลไต้หวันสำหรับแจ้งโดรน เรือไร้คนขับ และยานพาหนะต้องสงสัยอื่น ๆ ทั้งบนฟ้า ในทะเล หรือชายฝั่ง รายงานไม่ระบุตัวตน เราไม่ขอชื่อ เบอร์โทร หรือบัญชีของคุณ รายงานประกอบด้วยตำแหน่งของคุณ ทิศทางที่หันโทรศัพท์ คำตอบของคุณ รูป วิดีโอ หรือเสียงที่คุณเพิ่ม สัญญาณ Remote ID ที่โทรศัพท์รับได้ และรหัสสุ่มที่สร้างตอนติดตั้งแอป รูปอาจถูกวิเคราะห์อัตโนมัติด้วยโมเดล AI เพื่อช่วยเจ้าหน้าที่ประเมิน ข้อมูลนี้ใช้โดยหน่วยงานของไต้หวันเพื่อจัดการเหตุดังกล่าวเท่านั้น';

  @override
  String get settingsClearHistory => 'ล้างประวัติรายงาน';

  @override
  String get settingsClearHistoryBody =>
      'การดำเนินการนี้จะลบรายงานของคุณและกุญแจติดตามส่วนตัวออกจากอุปกรณ์นี้ คุณจะไม่เห็นความคืบหน้าหรือตอบคำขอของรายงานเหล่านี้ได้อีก รายงานที่ส่งไปแล้วจะไม่ถูกถอนคืน';

  @override
  String get settingsClear => 'ล้าง';

  @override
  String get settingsHistoryCleared => 'ล้างประวัติรายงานแล้ว';

  @override
  String get settingsShowIntro => 'ดูคำแนะนำการใช้งานอีกครั้ง';

  @override
  String settingsVersion(String version) {
    return 'เวอร์ชัน $version';
  }
}
