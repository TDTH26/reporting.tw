// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'uavr_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class UavrL10nId extends UavrL10n {
  UavrL10nId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'Lapor Wahana Mencurigakan';

  @override
  String get demoDisclaimer =>
      'Demo untuk “Taiwan Defense Tech Hackathon 2026”. Bukan layanan resmi pemerintah.';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Batal';

  @override
  String get retry => 'Coba lagi';

  @override
  String get close => 'Tutup';

  @override
  String get back => 'Kembali';

  @override
  String get next => 'Lanjut';

  @override
  String get done => 'Selesai';

  @override
  String get save => 'Simpan';

  @override
  String get send => 'Kirim';

  @override
  String get loading => 'Memuat…';

  @override
  String get errorGeneric => 'Terjadi kesalahan.';

  @override
  String get errorNetwork => 'Tidak dapat terhubung ke server.';

  @override
  String get offline => 'Anda sedang offline';

  @override
  String get severityCritical => 'Kritis';

  @override
  String get severityMedium => 'Sedang';

  @override
  String get severityLow => 'Rendah';

  @override
  String get statusReceived => 'Diterima';

  @override
  String get statusInReview => 'Sedang ditinjau';

  @override
  String get statusInProgress => 'Sedang ditangani';

  @override
  String get statusCompleted => 'Selesai';

  @override
  String get zoneAirport => 'Bandara';

  @override
  String get zoneRed => 'Zona larangan terbang (merah)';

  @override
  String get zoneYellow => 'Zona terbatas (kuning)';

  @override
  String get zoneMilitary => 'Area militer';

  @override
  String get zoneCriticalInfrastructure => 'Infrastruktur vital';

  @override
  String get zoneOutlyingStrict => 'Area terbatas pulau terluar';

  @override
  String get zoneResidential => 'Kawasan permukiman';

  @override
  String get zoneOpen => 'Area terbuka';

  @override
  String get zoneJurisdiction => 'Wilayah hukum';

  @override
  String get languageLabel => 'Bahasa';

  @override
  String get languageSelfName => 'Bahasa Indonesia';

  @override
  String get justNow => 'baru saja';

  @override
  String get emergency110 => 'Jika ada orang dalam bahaya, segera hubungi 110.';

  @override
  String minutesAgo(int count) {
    return '$count menit yang lalu';
  }

  @override
  String hoursAgo(int count) {
    return '$count jam yang lalu';
  }
}
