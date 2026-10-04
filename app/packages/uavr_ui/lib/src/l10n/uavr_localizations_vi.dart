// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'uavr_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class UavrL10nVi extends UavrL10n {
  UavrL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'Báo cáo phương tiện đáng ngờ';

  @override
  String get demoDisclaimer =>
      'Bản demo cho “Taiwan Defense Tech Hackathon 2026”. Không phải dịch vụ chính thức của chính phủ.';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Hủy';

  @override
  String get retry => 'Thử lại';

  @override
  String get close => 'Đóng';

  @override
  String get back => 'Quay lại';

  @override
  String get next => 'Tiếp';

  @override
  String get done => 'Xong';

  @override
  String get save => 'Lưu';

  @override
  String get send => 'Gửi';

  @override
  String get loading => 'Đang tải…';

  @override
  String get errorGeneric => 'Đã xảy ra lỗi.';

  @override
  String get errorNetwork => 'Không kết nối được máy chủ.';

  @override
  String get offline => 'Bạn đang ngoại tuyến';

  @override
  String get severityCritical => 'Khẩn cấp';

  @override
  String get severityMedium => 'Trung bình';

  @override
  String get severityLow => 'Thấp';

  @override
  String get statusReceived => 'Đã tiếp nhận';

  @override
  String get statusInReview => 'Đang xem xét';

  @override
  String get statusInProgress => 'Đang xử lý';

  @override
  String get statusCompleted => 'Đã hoàn tất';

  @override
  String get zoneAirport => 'Sân bay';

  @override
  String get zoneRed => 'Vùng cấm bay (đỏ)';

  @override
  String get zoneYellow => 'Vùng hạn chế (vàng)';

  @override
  String get zoneMilitary => 'Khu quân sự';

  @override
  String get zoneCriticalInfrastructure => 'Cơ sở hạ tầng trọng yếu';

  @override
  String get zoneOutlyingStrict => 'Vùng hạn chế hải đảo';

  @override
  String get zoneResidential => 'Khu dân cư';

  @override
  String get zoneOpen => 'Khu vực mở';

  @override
  String get zoneJurisdiction => 'Khu vực quản lý';

  @override
  String get languageLabel => 'Ngôn ngữ';

  @override
  String get languageSelfName => 'Tiếng Việt';

  @override
  String get justNow => 'vừa xong';

  @override
  String get emergency110 => 'Nếu có người gặp nguy hiểm, hãy gọi ngay 110.';

  @override
  String minutesAgo(int count) {
    return '$count phút trước';
  }

  @override
  String hoursAgo(int count) {
    return '$count giờ trước';
  }
}
