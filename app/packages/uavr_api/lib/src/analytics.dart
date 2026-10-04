import 'json.dart';

class AnalyticsSummary {
  AnalyticsSummary(this.raw);
  final Json raw;
  int _i(String k) => toInt(raw[k]) ?? 0;
  int get incidents => _i('incidents');
  int get critical => _i('critical');
  int get medium => _i('medium');
  int get low => _i('low');
  int get authorized => _i('authorized');
  int get withRemoteId => _i('with_remote_id');
  int get sensorConfirmed => _i('sensor_confirmed');
  int get falseReports => _i('false_reports');
  int get observations => _i('observations');
  double? get ackP50 => toDouble(raw['ack_p50']);
  double? get ackP90 => toDouble(raw['ack_p90']);
}

class HotspotCell {
  HotspotCell(this.lat, this.lon, this.count, this.critical, this.unauthorized);
  final double lat, lon;
  final int count, critical, unauthorized;

  factory HotspotCell.fromJson(Json j) => HotspotCell(
    toDouble(j['lat'])!,
    toDouble(j['lon'])!,
    toInt(j['count']) ?? 0,
    toInt(j['critical']) ?? 0,
    toInt(j['unauthorized']) ?? 0,
  );
}

/// grid[dow 0..6 = Mon..Sun][hour 0..23], local Taipei time.
class TimeOfDay {
  TimeOfDay(this.grid);
  final List<List<int>> grid;
  int get max => grid.expand((r) => r).fold(0, (a, b) => a > b ? a : b);

  factory TimeOfDay.fromJson(Json j) =>
      TimeOfDay((j['grid'] as List).map((r) => (r as List).map((e) => toInt(e) ?? 0).toList()).toList());
}

/// Rows from /zones, /response, /source-quality and /repeat-offenders are shown in tables,
/// so they stay as maps with typed accessors where the UI needs them.
class StatRow {
  StatRow(this.raw);
  final Json raw;
  String s(String k) => '${raw[k] ?? ''}';
  int i(String k) => toInt(raw[k]) ?? 0;
  double? d(String k) => toDouble(raw[k]);
}
