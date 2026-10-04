// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'informant_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class InformantL10nVi extends InformantL10n {
  InformantL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get skip => 'Bỏ qua';

  @override
  String get notSure => 'Không chắc';

  @override
  String get onboardingLanguageTitle => 'Chọn ngôn ngữ';

  @override
  String get onboardingLanguageBody =>
      'Bạn có thể đổi lại bất cứ lúc nào trong phần Cài đặt.';

  @override
  String get onboardingWhatTitle =>
      'Báo cáo thiết bị bay, xuồng không người lái và phương tiện đáng ngờ';

  @override
  String get onboardingWhatBody =>
      'Thấy thiết bị bay gần sân bay hay khu quân sự, xuồng không người lái ngoài khơi, hoặc phương tiện cập bãi biển? Báo cáo trong chưa đầy một phút. Báo cáo được chuyển thẳng đến cơ quan phụ trách: cảnh sát, hàng không dân dụng, tuần duyên hoặc quốc phòng.';

  @override
  String get onboardingSafetyTitle => 'An toàn của bạn là trên hết';

  @override
  String get onboardingSafetyApproach =>
      'Tuyệt đối không tiếp cận hoặc đi theo người điều khiển drone.';

  @override
  String get onboardingSafetyDistance =>
      'Giữ khoảng cách với drone và chú ý xe cộ xung quanh.';

  @override
  String get onboardingSafetyDanger =>
      'Nếu có người gặp nguy hiểm, hãy gọi 110 trước.';

  @override
  String get onboardingPrivacyTitle => 'Hoàn toàn ẩn danh';

  @override
  String get onboardingPrivacyNoAccount =>
      'Chúng tôi không bao giờ hỏi tên, số điện thoại hay yêu cầu tạo tài khoản.';

  @override
  String get onboardingPrivacyCollected =>
      'Một báo cáo gồm: vị trí của bạn, hướng bạn chĩa điện thoại, ảnh, video hoặc âm thanh bạn thêm vào, và một mã ngẫu nhiên được tạo khi bạn cài ứng dụng.';

  @override
  String get onboardingPrivacyUse =>
      'Báo cáo chỉ được cơ quan chính phủ Đài Loan dùng để xử lý sự việc liên quan đến thiết bị bay và trên biển.';

  @override
  String get onboardingPermissionsTitle => 'Quyền truy cập';

  @override
  String get onboardingPermissionsBody =>
      'Mỗi quyền giúp báo cáo của bạn hữu ích hơn. Bạn có thể từ chối bất kỳ quyền nào mà vẫn gửi được báo cáo.';

  @override
  String get onboardingStart => 'Bắt đầu';

  @override
  String get permLocationTitle => 'Vị trí';

  @override
  String get permLocationBody =>
      'Đánh dấu báo cáo trên bản đồ để cán bộ biết cần đến đâu kiểm tra.';

  @override
  String get permCameraTitle => 'Máy ảnh';

  @override
  String get permCameraBody =>
      'Giúp bạn ngắm về phía drone và chụp ảnh hoặc quay video.';

  @override
  String get permMicrophoneTitle => 'Micrô';

  @override
  String get permMicrophoneBody =>
      'Ghi lại tiếng cánh quạt, giúp nhận biết loại drone.';

  @override
  String get permNearbyTitle => 'Thiết bị lân cận (Bluetooth và Wi-Fi)';

  @override
  String get permNearbyBody =>
      'Thu tín hiệu nhận dạng từ xa (Remote ID) của drone: số sê-ri, vị trí và đôi khi cả vị trí của người điều khiển.';

  @override
  String get permNotificationsTitle => 'Thông báo';

  @override
  String get permNotificationsBody =>
      'Báo cho bạn khi hồ sơ có cập nhật. Thông báo không bao giờ chứa chi tiết hồ sơ.';

  @override
  String get permAllow => 'Cho phép';

  @override
  String get permGranted => 'Đã cho phép';

  @override
  String get permOpenSettings => 'Mở cài đặt';

  @override
  String get homeReportButton => 'Báo cáo';

  @override
  String get homeReportHint => 'Chưa đến một phút. Không cần đăng ký.';

  @override
  String get homeMyReports => 'Báo cáo của tôi';

  @override
  String get homeNoReports => 'Bạn chưa gửi báo cáo nào từ thiết bị này.';

  @override
  String get homeZonesMap => 'Bản đồ vùng cấm bay';

  @override
  String get homeSettings => 'Cài đặt';

  @override
  String get homeWebBanner =>
      'Khi drone đang bay, ứng dụng Android gửi báo cáo chính xác hơn: ứng dụng đo được hướng đến drone và thu được tín hiệu Remote ID của nó.';

  @override
  String get homeGetAndroidApp => 'Tải ứng dụng Android';

  @override
  String get homeEvidenceRequested => 'Cần bổ sung bằng chứng';

  @override
  String get homePendingSend => 'Đang chờ gửi';

  @override
  String get homeStatusOffline => 'Trạng thái gần nhất';

  @override
  String get caseNumberLabel => 'Mã hồ sơ';

  @override
  String get reportTitle => 'Báo cáo';

  @override
  String get stepAim => 'Ngắm';

  @override
  String get stepDetails => 'Chi tiết';

  @override
  String get stepEvidence => 'Bằng chứng';

  @override
  String get locationWaiting => 'Đang xác định vị trí của bạn…';

  @override
  String locationAccuracy(int meters) {
    return 'Vị trí ±$meters m';
  }

  @override
  String get locationUnavailable =>
      'Định vị đang tắt hoặc chưa được cho phép. Hãy bật định vị, hoặc chọn vị trí của bạn trên bản đồ.';

  @override
  String get locationPickOnMap => 'Chọn trên bản đồ';

  @override
  String get locationManual => 'Đã chọn vị trí trên bản đồ';

  @override
  String get mapPickTitle => 'Chạm vào nơi bạn đang đứng';

  @override
  String get mapPickConfirm => 'Dùng vị trí này';

  @override
  String get remoteIdTitle => 'Remote ID';

  @override
  String remoteIdReceives(String transports) {
    return 'Đang dò qua: $transports';
  }

  @override
  String remoteIdCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count drone đang phát Remote ID',
      zero: 'Chưa thấy drone nào phát Remote ID ở gần',
    );
    return '$_temp0';
  }

  @override
  String get remoteIdUnsupported =>
      'Điện thoại này không thu được tín hiệu Remote ID.';

  @override
  String get remoteIdPermission =>
      'Hãy cho phép \"Thiết bị lân cận\" để ứng dụng thu được Remote ID.';

  @override
  String get remoteIdUnknownSerial => 'Chưa nhận được số sê-ri';

  @override
  String remoteIdDistance(int meters) {
    return 'Cách $meters m';
  }

  @override
  String remoteIdHeight(int meters) {
    return 'Cao $meters m';
  }

  @override
  String get transportBt4 => 'Bluetooth';

  @override
  String get transportBt5 => 'Bluetooth tầm xa';

  @override
  String get transportWifiBeacon => 'Wi-Fi beacon';

  @override
  String get transportWifiNan => 'Wi-Fi Aware';

  @override
  String get aimInstruction =>
      'Hướng điện thoại vào thiết bị bay hoặc tàu thuyền rồi nhấn \"Khóa hướng\".';

  @override
  String get aimBearing => 'Hướng';

  @override
  String get aimElevation => 'Góc ngẩng';

  @override
  String get aimCalibrate =>
      'La bàn cần hiệu chỉnh: hãy di chuyển điện thoại theo hình số 8 vài lần.';

  @override
  String get aimNoCompass =>
      'Thiết bị này không có dữ liệu la bàn. Bạn có thể bỏ qua bước này.';

  @override
  String get aimNoCamera => 'Không dùng được máy ảnh';

  @override
  String get aimLock => 'Khóa hướng';

  @override
  String get aimTakePhoto => 'Chụp kèm một ảnh';

  @override
  String get aimSkip => 'Bỏ qua bước ngắm';

  @override
  String aimLocked(int bearing, int elevation) {
    return 'Đã khóa hướng: $bearing°, ngẩng $elevation°';
  }

  @override
  String get aimAgain => 'Ngắm lại';

  @override
  String get detailsTitle => 'Bạn đã thấy gì?';

  @override
  String get detailsOptional =>
      'Mọi mục ở đây đều không bắt buộc. Nếu đang vội, bạn có thể bỏ qua.';

  @override
  String get detailsHeight => 'Drone bay cao bao nhiêu?';

  @override
  String get detailsHeightHint => 'Một tòa nhà 10 tầng cao khoảng 30 m.';

  @override
  String get heightBelow30 => 'Dưới 30 m';

  @override
  String get height30to60 => '30–60 m';

  @override
  String get height60to120 => '60–120 m';

  @override
  String get heightAbove120 => 'Trên 120 m';

  @override
  String get detailsMovement => 'Drone có di chuyển không?';

  @override
  String get movementHovering => 'Đứng yên trên không';

  @override
  String get movementMoving => 'Đang di chuyển';

  @override
  String get detailsCount => 'Có bao nhiêu drone?';

  @override
  String get countOne => '1';

  @override
  String get countTwo => '2';

  @override
  String get countThreePlus => '3 trở lên';

  @override
  String get detailsDescription => 'Thông tin khác? (không bắt buộc)';

  @override
  String get detailsDescriptionHint =>
      'Ví dụ: bay trên sân trường, có đèn đỏ, tiếng vo vo rất to';

  @override
  String get evidenceTitle => 'Ảnh, video và âm thanh';

  @override
  String get evidenceSpeedNote =>
      'Gửi nhanh quan trọng hơn bằng chứng hoàn hảo. Bạn có thể gửi ngay; tệp sẽ được tải lên ở chế độ nền.';

  @override
  String get mediaPhoto => 'Ảnh';

  @override
  String get mediaVideo => 'Video';

  @override
  String get mediaAudio => 'Bản ghi âm';

  @override
  String get evidenceRecordSound => 'Ghi âm';

  @override
  String get evidenceStopRecording => 'Dừng ghi âm';

  @override
  String evidenceRecording(int seconds) {
    return 'Đang ghi tiếng cánh quạt… $seconds giây';
  }

  @override
  String get evidenceNone => 'Chưa thêm tệp nào.';

  @override
  String get evidenceRemove => 'Xóa tệp';

  @override
  String get evidenceAimPhoto => 'Ảnh chụp khi khóa hướng';

  @override
  String get evidenceCaptureFailed => 'Không lấy được tệp. Vui lòng thử lại.';

  @override
  String get sendNow => 'Gửi báo cáo ngay';

  @override
  String get sending => 'Đang gửi…';

  @override
  String get sendQueuedTitle => 'Đã lưu báo cáo';

  @override
  String get sendQueuedBody =>
      'Hiện không có kết nối mạng. Báo cáo đã được lưu trên điện thoại và sẽ tự động gửi khi có mạng trở lại.';

  @override
  String get sendRateLimited =>
      'Gần đây có quá nhiều báo cáo được gửi từ thiết bị hoặc mạng này. Vui lòng đợi vài phút rồi thử lại. Nếu có người gặp nguy hiểm, hãy gọi 110.';

  @override
  String sendRejected(String message) {
    return 'Không thể tiếp nhận báo cáo: $message';
  }

  @override
  String get sendFailedTitle => 'Chưa gửi được báo cáo';

  @override
  String get discardTitle => 'Hủy báo cáo này?';

  @override
  String get discardBody => 'Chưa có gì được gửi đi.';

  @override
  String get discard => 'Hủy';

  @override
  String get sentTitle => 'Đã gửi báo cáo';

  @override
  String get sentBody =>
      'Cảm ơn bạn. Báo cáo đã được chuyển đến cơ quan có trách nhiệm.';

  @override
  String sentUploading(int done, int total) {
    return 'Đang tải tệp lên: $done/$total';
  }

  @override
  String get sentUploadsDone => 'Đã tải lên tất cả tệp.';

  @override
  String get sentUploadsBackground =>
      'Việc tải lên vẫn tiếp tục ở chế độ nền, kể cả khi bạn đóng ứng dụng.';

  @override
  String get sentUploadsKeepOpen =>
      'Hãy giữ trang này mở cho đến khi tải tệp xong.';

  @override
  String get sentKeyNote =>
      'Chỉ điện thoại này giữ khóa riêng để theo dõi báo cáo. Nếu bạn gỡ ứng dụng hoặc xóa dữ liệu của ứng dụng, bạn sẽ không xem được cập nhật nữa.';

  @override
  String get sentKeyNoteWeb =>
      'Chỉ trình duyệt này giữ khóa riêng để theo dõi báo cáo. Nếu bạn xóa dữ liệu trình duyệt, bạn sẽ không xem được cập nhật nữa.';

  @override
  String get sentAndroidHint =>
      'Lần sau, ứng dụng Android có thể đo hướng đến drone và thu Remote ID, giúp báo cáo của bạn hữu ích hơn.';

  @override
  String get sentViewStatus => 'Xem tiến độ';

  @override
  String get sentBackHome => 'Về trang chủ';

  @override
  String caseTitle(String caseNumber) {
    return 'Hồ sơ $caseNumber';
  }

  @override
  String get caseProgress => 'Tiến độ';

  @override
  String get caseOutcome => 'Kết quả';

  @override
  String get caseEvidenceRequests => 'Yêu cầu bổ sung bằng chứng';

  @override
  String get caseEvidenceSafety =>
      'Chỉ gửi những gì bạn có thể ghi lại an toàn từ chỗ bạn đang đứng.';

  @override
  String get caseEvidenceAnswered => 'Đã trả lời — cảm ơn bạn.';

  @override
  String caseEvidenceSend(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gửi $count tệp',
    );
    return '$_temp0';
  }

  @override
  String get caseEvidenceSent => 'Cảm ơn bạn. Tệp đang được tải lên.';

  @override
  String get caseEvidenceClosed => 'Yêu cầu này đã đóng.';

  @override
  String get caseNotOnDevice => 'Báo cáo này không được lưu trên thiết bị này.';

  @override
  String caseUpdated(String time) {
    return 'Cập nhật $time';
  }

  @override
  String get zonesTitle => 'Vùng cấm bay';

  @override
  String get zonesLegend => 'Chú giải';

  @override
  String get zonesMyLocation => 'Vị trí của tôi';

  @override
  String get zonesNote =>
      'Chỉ hiển thị các vùng bay drone do Cục Hàng không Dân dụng (CAA) công bố. Một số khu vực hạn chế không hiển thị trên bản đồ công khai.';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsPrivacy => 'Quyền riêng tư và giới thiệu';

  @override
  String get settingsPrivacyBody =>
      'reporting.tw là dịch vụ của chính phủ Đài Loan để báo cáo thiết bị bay, xuồng không người lái và các phương tiện đáng ngờ khác trên không, trên biển hoặc ven bờ. Báo cáo là ẩn danh: chúng tôi không bao giờ hỏi tên, số điện thoại hay tài khoản của bạn. Một báo cáo gồm vị trí của bạn, hướng bạn hướng điện thoại, câu trả lời của bạn, ảnh, video hoặc âm thanh bạn thêm vào, tín hiệu Remote ID điện thoại nhận được và một mã ngẫu nhiên tạo khi cài ứng dụng. Ảnh có thể được mô hình AI phân tích tự động để hỗ trợ cán bộ đánh giá. Thông tin này chỉ được cơ quan chức năng Đài Loan dùng để xử lý các sự việc này.';

  @override
  String get settingsClearHistory => 'Xóa lịch sử báo cáo';

  @override
  String get settingsClearHistoryBody =>
      'Thao tác này xóa các báo cáo và khóa theo dõi riêng của chúng khỏi thiết bị. Bạn sẽ không xem được cập nhật hoặc trả lời yêu cầu cho các báo cáo này nữa. Các báo cáo đã gửi sẽ không bị rút lại.';

  @override
  String get settingsClear => 'Xóa';

  @override
  String get settingsHistoryCleared => 'Đã xóa lịch sử báo cáo.';

  @override
  String get settingsShowIntro => 'Xem lại phần giới thiệu';

  @override
  String settingsVersion(String version) {
    return 'Phiên bản $version';
  }
}
