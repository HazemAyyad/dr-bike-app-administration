import 'package:flutter/material.dart';

const smartHomeAccent = Color(0xFF087F6A);
const smartHomeAccentSoft = Color(0xFFDDF3EE);
const smartHomeInk = Color(0xFF17211F);
const smartHomeMuted = Color(0xFF66736F);
const smartHomeSurface = Color(0xFFF4F7F6);
const smartHomeBorder = Color(0xFFDCE5E2);

ThemeData smartHomeTheme(BuildContext context) {
  final base = Theme.of(context);
  final scheme = ColorScheme.fromSeed(
    seedColor: smartHomeAccent,
    brightness: Brightness.light,
  ).copyWith(
    primary: smartHomeAccent,
    onPrimary: smartHomeInk,
    primaryContainer: smartHomeAccentSoft,
    onPrimaryContainer: smartHomeInk,
    secondary: const Color(0xFF176B87),
    onSecondary: smartHomeInk,
    secondaryContainer: const Color(0xFFDDEFF5),
    onSecondaryContainer: smartHomeInk,
    surface: Colors.white,
    onSurface: smartHomeInk,
    outline: smartHomeBorder,
  );
  return base.copyWith(
    brightness: Brightness.light,
    scaffoldBackgroundColor: smartHomeSurface,
    colorScheme: scheme,
    textTheme: base.textTheme.apply(
      bodyColor: smartHomeInk,
      displayColor: smartHomeInk,
    ),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: smartHomeSurface,
      foregroundColor: smartHomeInk,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: base.cardTheme.copyWith(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: smartHomeBorder),
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: smartHomeAccentSoft,
        foregroundColor: smartHomeInk,
        disabledBackgroundColor: const Color(0xFFE5EAE8),
        disabledForegroundColor: smartHomeMuted,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: smartHomeAccentSoft,
        foregroundColor: smartHomeInk,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: smartHomeAccent),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? smartHomeAccent
            : smartHomeMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? smartHomeAccentSoft
            : const Color(0xFFDDE3E1),
      ),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: smartHomeMuted),
      hintStyle: const TextStyle(color: smartHomeMuted),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: smartHomeBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: smartHomeAccent, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
