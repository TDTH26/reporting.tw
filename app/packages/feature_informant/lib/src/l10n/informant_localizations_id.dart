// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'informant_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class InformantL10nId extends InformantL10n {
  InformantL10nId([String locale = 'id']) : super(locale);

  @override
  String get skip => 'Lewati';

  @override
  String get notSure => 'Tidak yakin';

  @override
  String get onboardingLanguageTitle => 'Pilih bahasa';

  @override
  String get onboardingLanguageBody =>
      'Anda dapat mengubahnya kapan saja di Pengaturan.';

  @override
  String get onboardingWhatTitle =>
      'Laporkan drone, kapal tanpa awak, dan wahana mencurigakan';

  @override
  String get onboardingWhatBody =>
      'Melihat drone di dekat bandara atau area militer, kapal tanpa awak di lepas pantai, atau wahana mendarat di pantai? Laporkan dalam waktu kurang dari semenit. Laporan langsung diteruskan ke instansi yang berwenang: polisi, penerbangan sipil, penjaga pantai, atau pertahanan.';

  @override
  String get onboardingSafetyTitle => 'Keselamatan Anda yang utama';

  @override
  String get onboardingSafetyApproach =>
      'Jangan pernah mendekati atau mengikuti operator drone.';

  @override
  String get onboardingSafetyDistance =>
      'Jaga jarak dari drone dan perhatikan lalu lintas di sekitar Anda.';

  @override
  String get onboardingSafetyDanger =>
      'Jika ada orang dalam bahaya, segera hubungi 110.';

  @override
  String get onboardingPrivacyTitle => 'Tetap anonim';

  @override
  String get onboardingPrivacyNoAccount =>
      'Kami tidak pernah meminta nama, nomor telepon, atau akun Anda.';

  @override
  String get onboardingPrivacyCollected =>
      'Laporan berisi lokasi Anda, arah ponsel yang Anda tunjuk, foto, video, atau suara yang Anda tambahkan, serta ID acak yang dibuat saat Anda memasang aplikasi.';

  @override
  String get onboardingPrivacyUse =>
      'Laporan hanya digunakan oleh otoritas pemerintah Taiwan untuk menangani insiden drone dan maritim.';

  @override
  String get onboardingPermissionsTitle => 'Izin';

  @override
  String get onboardingPermissionsBody =>
      'Setiap izin membuat laporan Anda lebih bermanfaat. Anda boleh menolak izin mana pun dan tetap dapat mengirim laporan.';

  @override
  String get onboardingStart => 'Mulai';

  @override
  String get permLocationTitle => 'Lokasi';

  @override
  String get permLocationBody =>
      'Menandai laporan Anda di peta agar petugas tahu ke mana harus memeriksa.';

  @override
  String get permCameraTitle => 'Kamera';

  @override
  String get permCameraBody =>
      'Memungkinkan Anda membidik drone serta mengambil foto atau video.';

  @override
  String get permMicrophoneTitle => 'Mikrofon';

  @override
  String get permMicrophoneBody =>
      'Merekam suara baling-baling, yang membantu mengenali jenis drone.';

  @override
  String get permNearbyTitle => 'Perangkat di sekitar (Bluetooth dan Wi-Fi)';

  @override
  String get permNearbyBody =>
      'Menangkap siaran Remote ID drone: nomor seri, posisi, dan kadang posisi operatornya.';

  @override
  String get permNotificationsTitle => 'Notifikasi';

  @override
  String get permNotificationsBody =>
      'Memberi tahu Anda saat kasus Anda diperbarui. Notifikasi tidak pernah memuat rincian kasus.';

  @override
  String get permAllow => 'Izinkan';

  @override
  String get permGranted => 'Diizinkan';

  @override
  String get permOpenSettings => 'Buka pengaturan';

  @override
  String get homeReportButton => 'Laporkan';

  @override
  String get homeReportHint => 'Kurang dari satu menit. Tanpa pendaftaran.';

  @override
  String get homeMyReports => 'Laporan saya';

  @override
  String get homeNoReports => 'Anda belum mengirim laporan dari perangkat ini.';

  @override
  String get homeZonesMap => 'Peta zona larangan terbang';

  @override
  String get homeSettings => 'Pengaturan';

  @override
  String get homeWebBanner =>
      'Untuk drone yang sedang terbang, aplikasi Android mengirim laporan yang lebih akurat: aplikasi mengukur arah ke drone dan menangkap siaran Remote ID-nya.';

  @override
  String get homeGetAndroidApp => 'Unduh aplikasi Android';

  @override
  String get homeEvidenceRequested => 'Bukti diminta';

  @override
  String get homePendingSend => 'Menunggu dikirim';

  @override
  String get homeStatusOffline => 'Status terakhir yang diketahui';

  @override
  String get caseNumberLabel => 'Nomor kasus';

  @override
  String get reportTitle => 'Laporkan';

  @override
  String get stepAim => 'Bidik';

  @override
  String get stepDetails => 'Rincian';

  @override
  String get stepEvidence => 'Bukti';

  @override
  String get locationWaiting => 'Mencari lokasi Anda…';

  @override
  String locationAccuracy(int meters) {
    return 'Lokasi ±$meters m';
  }

  @override
  String get locationUnavailable =>
      'Lokasi mati atau tidak diizinkan. Aktifkan lokasi, atau tentukan posisi Anda di peta.';

  @override
  String get locationPickOnMap => 'Tentukan di peta';

  @override
  String get locationManual => 'Lokasi ditentukan di peta';

  @override
  String get mapPickTitle => 'Ketuk tempat Anda berada';

  @override
  String get mapPickConfirm => 'Gunakan lokasi ini';

  @override
  String get remoteIdTitle => 'Remote ID';

  @override
  String remoteIdReceives(String transports) {
    return 'Memindai melalui: $transports';
  }

  @override
  String remoteIdCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count drone menyiarkan Remote ID',
      zero: 'Belum ada drone yang menyiarkan Remote ID di sekitar',
    );
    return '$_temp0';
  }

  @override
  String get remoteIdUnsupported =>
      'Ponsel ini tidak dapat menerima siaran Remote ID.';

  @override
  String get remoteIdPermission =>
      'Izinkan \"Perangkat di sekitar\" agar aplikasi dapat menangkap Remote ID.';

  @override
  String get remoteIdUnknownSerial => 'Nomor seri belum diterima';

  @override
  String remoteIdDistance(int meters) {
    return 'Berjarak $meters m';
  }

  @override
  String remoteIdHeight(int meters) {
    return 'Ketinggian $meters m';
  }

  @override
  String get transportBt4 => 'Bluetooth';

  @override
  String get transportBt5 => 'Bluetooth jarak jauh';

  @override
  String get transportWifiBeacon => 'Wi-Fi beacon';

  @override
  String get transportWifiNan => 'Wi-Fi Aware';

  @override
  String get aimInstruction =>
      'Arahkan ponsel ke drone atau kapal, lalu ketuk \"Kunci arah\".';

  @override
  String get aimBearing => 'Arah';

  @override
  String get aimElevation => 'Sudut ke atas';

  @override
  String get aimCalibrate =>
      'Kompas perlu dikalibrasi: gerakkan ponsel membentuk angka 8 beberapa kali.';

  @override
  String get aimNoCompass =>
      'Tidak ada data kompas di perangkat ini. Anda dapat melewati langkah ini.';

  @override
  String get aimNoCamera => 'Kamera tidak tersedia';

  @override
  String get aimLock => 'Kunci arah';

  @override
  String get aimTakePhoto => 'Sekaligus ambil foto';

  @override
  String get aimSkip => 'Lewati membidik';

  @override
  String aimLocked(int bearing, int elevation) {
    return 'Arah terkunci: $bearing°, $elevation° ke atas';
  }

  @override
  String get aimAgain => 'Bidik ulang';

  @override
  String get detailsTitle => 'Apa yang Anda lihat?';

  @override
  String get detailsOptional =>
      'Semua isian di sini tidak wajib. Lewati saja jika Anda terburu-buru.';

  @override
  String get detailsHeight => 'Seberapa tinggi?';

  @override
  String get detailsHeightHint => 'Gedung 10 lantai tingginya sekitar 30 m.';

  @override
  String get heightBelow30 => 'Di bawah 30 m';

  @override
  String get height30to60 => '30–60 m';

  @override
  String get height60to120 => '60–120 m';

  @override
  String get heightAbove120 => 'Di atas 120 m';

  @override
  String get detailsMovement => 'Apakah drone bergerak?';

  @override
  String get movementHovering => 'Diam melayang';

  @override
  String get movementMoving => 'Bergerak';

  @override
  String get detailsCount => 'Berapa banyak drone?';

  @override
  String get countOne => '1';

  @override
  String get countTwo => '2';

  @override
  String get countThreePlus => '3 atau lebih';

  @override
  String get detailsDescription => 'Ada hal lain? (tidak wajib)';

  @override
  String get detailsDescriptionHint =>
      'Contoh: terbang di atas halaman sekolah, lampu merah, suara dengung keras';

  @override
  String get evidenceTitle => 'Foto, video, dan suara';

  @override
  String get evidenceSpeedNote =>
      'Mengirim dengan cepat lebih penting daripada bukti yang sempurna. Anda bisa mengirim sekarang; file akan diunggah di latar belakang.';

  @override
  String get mediaPhoto => 'Foto';

  @override
  String get mediaVideo => 'Video';

  @override
  String get mediaAudio => 'Rekaman suara';

  @override
  String get evidenceRecordSound => 'Rekam suara';

  @override
  String get evidenceStopRecording => 'Berhenti merekam';

  @override
  String evidenceRecording(int seconds) {
    return 'Merekam suara baling-baling… $seconds dtk';
  }

  @override
  String get evidenceNone => 'Belum ada file yang ditambahkan.';

  @override
  String get evidenceRemove => 'Hapus file';

  @override
  String get evidenceAimPhoto => 'Foto yang diambil saat mengunci arah';

  @override
  String get evidenceCaptureFailed =>
      'Gagal mengambil file. Silakan coba lagi.';

  @override
  String get sendNow => 'Kirim laporan sekarang';

  @override
  String get sending => 'Mengirim…';

  @override
  String get sendQueuedTitle => 'Laporan disimpan';

  @override
  String get sendQueuedBody =>
      'Saat ini tidak ada koneksi. Laporan Anda disimpan di ponsel ini dan akan dikirim otomatis begitu Anda kembali online.';

  @override
  String get sendRateLimited =>
      'Terlalu banyak laporan dikirim dari perangkat atau jaringan ini baru-baru ini. Harap tunggu beberapa menit lalu coba lagi. Jika ada orang dalam bahaya, hubungi 110.';

  @override
  String sendRejected(String message) {
    return 'Laporan tidak dapat diterima: $message';
  }

  @override
  String get sendFailedTitle => 'Laporan belum terkirim';

  @override
  String get discardTitle => 'Buang laporan ini?';

  @override
  String get discardBody => 'Belum ada yang dikirim.';

  @override
  String get discard => 'Buang';

  @override
  String get sentTitle => 'Laporan terkirim';

  @override
  String get sentBody =>
      'Terima kasih. Laporan Anda telah diteruskan ke instansi yang bertanggung jawab.';

  @override
  String sentUploading(int done, int total) {
    return 'Mengunggah file: $done dari $total';
  }

  @override
  String get sentUploadsDone => 'Semua file telah diunggah.';

  @override
  String get sentUploadsBackground =>
      'Unggahan tetap berjalan di latar belakang, meskipun aplikasi ditutup.';

  @override
  String get sentUploadsKeepOpen =>
      'Biarkan halaman ini terbuka sampai file selesai diunggah.';

  @override
  String get sentKeyNote =>
      'Hanya ponsel ini yang menyimpan kunci pribadi untuk memantau laporan ini. Jika Anda menghapus aplikasi atau datanya, Anda tidak akan bisa melihat pembaruan lagi.';

  @override
  String get sentKeyNoteWeb =>
      'Hanya browser ini yang menyimpan kunci pribadi untuk memantau laporan ini. Jika Anda menghapus data browser, Anda tidak akan bisa melihat pembaruan lagi.';

  @override
  String get sentAndroidHint =>
      'Lain kali, aplikasi Android dapat mengukur arah ke drone dan menangkap Remote ID-nya, sehingga laporan Anda lebih bermanfaat.';

  @override
  String get sentViewStatus => 'Lihat status';

  @override
  String get sentBackHome => 'Kembali ke beranda';

  @override
  String caseTitle(String caseNumber) {
    return 'Kasus $caseNumber';
  }

  @override
  String get caseProgress => 'Perkembangan';

  @override
  String get caseOutcome => 'Hasil';

  @override
  String get caseEvidenceRequests => 'Permintaan bukti tambahan';

  @override
  String get caseEvidenceSafety =>
      'Kirim hanya yang bisa Anda rekam dengan aman dari tempat Anda berada.';

  @override
  String get caseEvidenceAnswered => 'Sudah dijawab — terima kasih.';

  @override
  String caseEvidenceSend(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kirim $count file',
    );
    return '$_temp0';
  }

  @override
  String get caseEvidenceSent => 'Terima kasih. File Anda sedang diunggah.';

  @override
  String get caseEvidenceClosed => 'Permintaan ini sudah ditutup.';

  @override
  String get caseNotOnDevice => 'Laporan ini tidak tersimpan di perangkat ini.';

  @override
  String caseUpdated(String time) {
    return 'Diperbarui $time';
  }

  @override
  String get zonesTitle => 'Zona larangan terbang';

  @override
  String get zonesLegend => 'Keterangan';

  @override
  String get zonesMyLocation => 'Lokasi saya';

  @override
  String get zonesNote =>
      'Hanya menampilkan zona drone yang diumumkan oleh Otoritas Penerbangan Sipil (CAA). Beberapa area terbatas tidak ditampilkan di peta publik.';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get settingsPrivacy => 'Privasi dan tentang';

  @override
  String get settingsPrivacyBody =>
      'reporting.tw adalah layanan pemerintah Taiwan untuk melaporkan drone, kapal tanpa awak, dan wahana mencurigakan lainnya di udara, di laut, atau di pantai. Laporan bersifat anonim: kami tidak pernah meminta nama, nomor telepon, atau akun Anda. Laporan berisi lokasi Anda, arah ponsel Anda, jawaban Anda atas pertanyaan, foto, video, atau suara yang Anda tambahkan, siaran Remote ID yang diterima ponsel, dan ID acak yang dibuat saat aplikasi dipasang. Foto dapat dianalisis otomatis oleh model AI untuk membantu petugas menilai laporan. Informasi ini hanya digunakan oleh otoritas Taiwan untuk menangani insiden tersebut.';

  @override
  String get settingsClearHistory => 'Hapus riwayat laporan';

  @override
  String get settingsClearHistoryBody =>
      'Tindakan ini menghapus laporan Anda beserta kunci pemantauan pribadinya dari perangkat ini. Anda tidak akan bisa lagi melihat pembaruan atau menjawab permintaan untuk laporan-laporan ini. Laporan yang sudah dikirim tidak ditarik kembali.';

  @override
  String get settingsClear => 'Hapus';

  @override
  String get settingsHistoryCleared => 'Riwayat laporan telah dihapus.';

  @override
  String get settingsShowIntro => 'Tampilkan lagi pengenalan';

  @override
  String settingsVersion(String version) {
    return 'Versi $version';
  }
}
