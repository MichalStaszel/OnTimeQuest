import 'package:material_ui/material_ui.dart';

import 'palette.dart';

ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    primary: Palette.mint,
    onPrimary: Palette.ink,
    secondary: Palette.amber,
    onSecondary: Palette.ink,
    error: Palette.tomato,
    surface: Palette.ink,
    onSurface: Palette.paper,
    surfaceContainerHighest: Palette.plum,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: Fonts.ui,
    scaffoldBackgroundColor: Palette.ink,
  );
  const square = RoundedRectangleBorder(borderRadius: BorderRadius.zero);
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: Palette.paper,
      displayColor: Palette.paper,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Palette.ink,
      foregroundColor: Palette.paper,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: Fonts.logo,
        fontSize: 14,
        color: Palette.paper,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Palette.plumDeep,
      indicatorColor: Palette.plum,
      indicatorShape: square,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontFamily: Fonts.ui, fontSize: 13),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Palette.plumDeep,
      shape: square,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Palette.plumDeep,
      shape: square,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Palette.ink,
      border: OutlineInputBorder(borderRadius: BorderRadius.zero),
      labelStyle: TextStyle(color: Palette.lavender),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Palette.lavender,
        shape: square,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Palette.plum,
      contentTextStyle: TextStyle(fontFamily: Fonts.ui, color: Palette.paper),
      shape: square,
    ),
    timePickerTheme: const TimePickerThemeData(
      backgroundColor: Palette.plumDeep,
      shape: square,
    ),
  );
}
