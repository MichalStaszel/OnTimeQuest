import 'package:material_ui/material_ui.dart';

import 'palette.dart';

ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    primary: Palette.gold,
    onPrimary: Palette.onAccent,
    secondary: Palette.teal,
    onSecondary: Palette.onAccent,
    error: Palette.rose,
    surface: Palette.app,
    onSurface: Palette.text,
    surfaceContainerHighest: Palette.card2,
    outline: Palette.line,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: Fonts.text,
    scaffoldBackgroundColor: Palette.app,
    splashFactory: InkSparkle.splashFactory,
  );
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: Palette.text,
      displayColor: Palette.text,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Palette.app,
      foregroundColor: Palette.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: ts(size: 18, weight: 600),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Palette.tabs,
      indicatorColor: Palette.gold.withValues(alpha: 0.14),
      height: 66,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => ts(
          size: 11.5,
          weight: 500,
          color: s.contains(WidgetState.selected)
              ? Palette.gold
              : Palette.faint,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? Palette.gold
              : Palette.faint,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(backgroundColor: Palette.card, shape: rounded),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF121B2D),
      showDragHandle: true,
      dragHandleColor: Color(0xFF33415F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Palette.card,
      labelStyle: ts(size: 13, color: Palette.muted),
      hintStyle: ts(size: 14, color: Palette.faint),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Palette.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Palette.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Palette.gold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Palette.gold,
        textStyle: ts(size: 14, weight: 500),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.selected) ? Palette.onAccent : Palette.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Palette.teal : Palette.card2,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Palette.card2,
      contentTextStyle: ts(size: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: Palette.card,
      shape: rounded,
    ),
    dividerColor: Palette.line,
  );
}
