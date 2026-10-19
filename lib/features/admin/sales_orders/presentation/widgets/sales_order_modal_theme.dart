import 'package:flutter/material.dart';

/// Order dialogs keep readable neutral surfaces in both app appearance modes.
class SalesOrderModalTheme extends StatelessWidget {
  const SalesOrderModalTheme({Key? key, required this.child}) : super(key: key);
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
        data: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          fontFamily: 'Almarai',
          colorScheme: const ColorScheme.light(
              primary: Color(0xFF635CB1),
              onPrimary: Color(0xFF111827),
              surface: Color(0xFFF3F4F6),
              onSurface: Color(0xFF111827)),
          textTheme: Theme.of(context).textTheme.apply(
              bodyColor: const Color(0xFF111827),
              displayColor: const Color(0xFF111827)),
          chipTheme: const ChipThemeData(
              backgroundColor: Color(0xFFF3F4F6),
              selectedColor: Color(0xFFE5E7EB),
              secondarySelectedColor: Color(0xFFE5E7EB),
              labelStyle: TextStyle(color: Color(0xFF111827)),
              secondaryLabelStyle: TextStyle(color: Color(0xFF111827))),
        ),
        child: child,
      );
}
