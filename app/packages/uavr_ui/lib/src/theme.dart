import 'package:flutter/material.dart';

/// Brand + semantic colours. Severity colours are fixed across light/dark so dispatchers
/// read them the same way everywhere.
abstract final class UavrColors {
  static const brand = Color(0xFF1B4F9C);
  static const critical = Color(0xFFC62828);
  static const medium = Color(0xFFEF6C00);
  static const low = Color(0xFF2E7D32);
  static const redacted = Color(0xFF6D6D6D);
  static const zoneRed = Color(0xFFD32F2F);
  static const zoneYellow = Color(0xFFF9A825);
  static const zoneAirport = Color(0xFF7B1FA2);
  static const zoneMilitary = Color(0xFF37474F);
  static const zoneStrict = Color(0xFFAD1457);
  static const zoneInfra = Color(0xFF00838F);
  static const zoneResidential = Color(0xFF5D4037);
  static const zoneOther = Color(0xFF546E7A);

  static Color severity(int s) => switch (s) {
        3 => critical,
        2 => medium,
        _ => low,
      };

  static Color zone(String type) => switch (type) {
        'red' => zoneRed,
        'yellow' => zoneYellow,
        'airport' => zoneAirport,
        'military' => zoneMilitary,
        'outlying_islands_strict' => zoneStrict,
        'critical_infrastructure' => zoneInfra,
        'residential' => zoneResidential,
        _ => zoneOther,
      };
}

/// Font stack: Latin/Vietnamese first, then Traditional Chinese and Thai fallbacks.
const fontFallback = ['NotoSansTC', 'NotoSansThai'];

ThemeData uavrTheme({Brightness brightness = Brightness.light, bool dense = false}) {
  final scheme = ColorScheme.fromSeed(seedColor: UavrColors.brand, brightness: brightness);
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: 'NotoSans',
    fontFamilyFallback: fontFallback,
    visualDensity: dense ? VisualDensity.compact : VisualDensity.standard,
  );
  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: Size(64, dense ? 40 : 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: Size(64, dense ? 40 : 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      isDense: dense,
    ),
    chipTheme: base.chipTheme.copyWith(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
  );
}
