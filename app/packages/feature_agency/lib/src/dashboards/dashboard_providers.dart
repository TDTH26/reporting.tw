import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';

class DateRange {
  const DateRange(this.from, this.to, {this.days});
  final DateTime from, to;

  /// 7 / 30 / 90 for the presets, null for a custom range.
  final int? days;

  factory DateRange.lastDays(int d, {DateTime? now}) {
    final to = now ?? DateTime.now();
    return DateRange(to.subtract(Duration(days: d)), to, days: d);
  }

  @override
  bool operator ==(Object other) => other is DateRange && other.from == from && other.to == to;
  @override
  int get hashCode => Object.hash(from, to);
}

class RangeController extends Notifier<DateRange> {
  @override
  DateRange build() => DateRange.lastDays(30);
  void set(DateRange r) => state = r;
}

final dashboardRangeProvider = NotifierProvider<RangeController, DateRange>(RangeController.new);

class HotspotFilter {
  const HotspotFilter({this.severityMin = 1, this.hour, this.dow});
  final int severityMin;
  final int? hour, dow; // dow 1..7 = Mon..Sun

  @override
  bool operator ==(Object other) =>
      other is HotspotFilter && other.severityMin == severityMin && other.hour == hour && other.dow == dow;
  @override
  int get hashCode => Object.hash(severityMin, hour, dow);
}

class HotspotFilterController extends Notifier<HotspotFilter> {
  @override
  HotspotFilter build() => const HotspotFilter();
  void set(HotspotFilter f) => state = f;
}

final hotspotFilterProvider = NotifierProvider<HotspotFilterController, HotspotFilter>(HotspotFilterController.new);

class ResponseGroupController extends Notifier<String> {
  @override
  String build() => 'agency';
  void set(String g) => state = g;
}

final responseGroupProvider = NotifierProvider<ResponseGroupController, String>(ResponseGroupController.new);

UavrApi _api(Ref ref) => ref.watch(staffApiProvider);

final summaryProvider = FutureProvider.autoDispose<AnalyticsSummary>((ref) {
  final r = ref.watch(dashboardRangeProvider);
  return _api(ref).analyticsSummary(from: r.from, to: r.to);
}, retry: (_, _) => null);

final hotspotsProvider = FutureProvider.autoDispose<List<HotspotCell>>((ref) {
  final r = ref.watch(dashboardRangeProvider);
  final f = ref.watch(hotspotFilterProvider);
  return _api(ref).hotspots(from: r.from, to: r.to, severityMin: f.severityMin, hour: f.hour, dow: f.dow);
}, retry: (_, _) => null);

final timeOfDayProvider = FutureProvider.autoDispose<TimeOfDay>((ref) {
  final r = ref.watch(dashboardRangeProvider);
  return _api(ref).timeOfDay(from: r.from, to: r.to);
}, retry: (_, _) => null);

final zoneStatsProvider = FutureProvider.autoDispose<List<StatRow>>((ref) {
  final r = ref.watch(dashboardRangeProvider);
  return _api(ref).zoneStats(from: r.from, to: r.to);
}, retry: (_, _) => null);

final responseStatsProvider = FutureProvider.autoDispose<List<StatRow>>((ref) {
  final r = ref.watch(dashboardRangeProvider);
  return _api(ref).responseStats(from: r.from, to: r.to, group: ref.watch(responseGroupProvider));
}, retry: (_, _) => null);

final sourceQualityProvider = FutureProvider.autoDispose<List<StatRow>>((ref) {
  final r = ref.watch(dashboardRangeProvider);
  return _api(ref).sourceQuality(from: r.from, to: r.to);
}, retry: (_, _) => null);

final repeatOffendersProvider = FutureProvider.autoDispose<({List<StatRow> bySerial, List<StatRow> byOwner})>((ref) {
  final r = ref.watch(dashboardRangeProvider);
  return _api(ref).repeatOffenders(from: r.from, to: r.to);
}, retry: (_, _) => null);
