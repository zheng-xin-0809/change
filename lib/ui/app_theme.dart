import 'package:flutter/material.dart';

import '../domain/accent_color.dart';

double contrastRatio(Color first, Color second) {
  final a = first.computeLuminance();
  final b = second.computeLuminance();
  return ((a > b ? a : b) + 0.05) / ((a > b ? b : a) + 0.05);
}

/// Black or white guarantees at least 4.5:1 on every opaque RGB color.
Color textOnAccent(Color accent) =>
    contrastRatio(Colors.black, accent) >= contrastRatio(Colors.white, accent)
    ? Colors.black
    : Colors.white;

/// Keep the selected RGB exact on filled controls; darken colored foregrounds
/// only when they would be hard to read on the light canvas.
Color readableAccent(Color accent, Color background) {
  if (contrastRatio(accent, background) >= 4.5) return accent;
  for (var step = 1; step <= 20; step++) {
    final candidate = Color.lerp(accent, Colors.black, step / 20)!;
    if (contrastRatio(candidate, background) >= 4.5) return candidate;
  }
  return Colors.black;
}

ThemeData buildAppTheme(AccentColor selected) {
  final accent = Color(selected.argb);
  const canvas = Color(0xFFF4F5F7);
  final scheme = ColorScheme.fromSeed(
    seedColor: accent,
    surface: canvas,
  ).copyWith(primary: accent, onPrimary: textOnAccent(accent));
  final ink = readableAccent(accent, canvas);
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final text = base.textTheme.copyWith(
    headlineLarge: base.textTheme.headlineLarge?.copyWith(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: 0,
    ),
    headlineSmall: base.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0,
    ),
    titleLarge: base.textTheme.titleLarge?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0,
    ),
    titleMedium: base.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.55),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.5),
  );
  return base.copyWith(
    textTheme: text,
    scaffoldBackgroundColor: canvas,
    appBarTheme: AppBarTheme(
      backgroundColor: canvas,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(
        text.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: canvas,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: ink, width: 2),
      ),
      floatingLabelStyle: TextStyle(color: ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size(48, 48),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: ink,
      thumbColor: ink,
      valueIndicatorColor: ink,
      valueIndicatorTextStyle: TextStyle(color: textOnAccent(ink)),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: ink,
      selectionHandleColor: ink,
    ),
    datePickerTheme: DatePickerThemeData(
      dayForegroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? scheme.onPrimary : null,
      ),
      todayForegroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? scheme.onPrimary : ink,
      ),
      todayBorder: BorderSide(color: ink),
    ),
  );
}
