import 'package:flutter/material.dart';

class CyrusColors {
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF13131A);
  static const Color surfaceLight = Color(0xFF1C1C26);
  static const Color gold = Color(0xFFD4A843);
  static const Color goldLight = Color(0xFFF0C860);
  static const Color goldDark = Color(0xFF9A7A2E);
  static const Color white = Color(0xFFEEEEEE);
  static const Color grey = Color(0xFF888888);
  static const Color greyDark = Color(0xFF444444);
  static const Color green = Color(0xFF4CAF7D);
  static const Color yellow = Color(0xFFFFB830);
  static const Color red = Color(0xFFE53935);
  static const Color border = Color(0xFF2A2A38);
}

class CyrusTheme {
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: CyrusColors.background,
        colorScheme: const ColorScheme.dark(
          primary: CyrusColors.gold,
          secondary: CyrusColors.goldLight,
          surface: CyrusColors.surface,
          background: CyrusColors.background,
          onPrimary: Color(0xFF0A0A0F),
          onSurface: CyrusColors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: CyrusColors.gold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
          iconTheme: IconThemeData(color: CyrusColors.gold),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: CyrusColors.surface,
          selectedItemColor: CyrusColors.gold,
          unselectedItemColor: CyrusColors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: CyrusColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: CyrusColors.border, width: 1),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: CyrusColors.gold,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
          headlineMedium: TextStyle(
            color: CyrusColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(color: CyrusColors.white, fontSize: 16),
          bodyMedium: TextStyle(color: CyrusColors.grey, fontSize: 14),
          labelSmall: TextStyle(color: CyrusColors.grey, fontSize: 11),
        ),
        useMaterial3: true,
      );
}
