import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: Colors.amber[700]!,
      secondary: Colors.orangeAccent,
    ),
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'SF Pro',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
          fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -1.2),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
      iconTheme: IconThemeData(
        color: Color(0xFF757575), // dark gray for light theme
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[200]!,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.orangeAccent),
      ),
      hintStyle: TextStyle(color: Colors.grey[600]),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.amber[100]!,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Colors.amber[700]!,
      secondary: Colors.orangeAccent,
    ),
    scaffoldBackgroundColor: Colors.black,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        letterSpacing: -1.2,
        color: Colors.white,
      ),
      headlineMedium: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white70),
      titleLarge: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.white60),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(
        color: Color(0xFFB0B0B0), // light grey for dark theme
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[800]!,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.orangeAccent),
      ),
      hintStyle: TextStyle(color: Colors.grey[400]),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.orange[800]!,
      labelStyle: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
    ),
  );

  // badge Colors (for both themes)
  static const Color badgeYellow = Color(0xFFFAEA82);
  static const Color badgeGreen = Color(0xFF85F981);
  static const Color badgeBlue = Color(0xFF82E1FB);
  static const Color badgePurple = Color(0xFFD385FD);
  static const Color badgeRed = Color(0xFFFE8486);
  static const Color badgeGrey = Color(0xFFE2E1DD);

  // Chart Line Color
  static const Color chartDashedLine = Color(0xFFBDBDBD); // from grey.shade400

  // Pie Chart Background (No Data)
  static const Color pieBackgroundDark = Color(0xFF464646);
  static const Color pieBackgroundLight = Color(0xFFF5F5F5);

  // Text Styles
  static const TextStyle chartAxisLabelStyle = TextStyle(fontSize: 10);
  static const TextStyle noDataTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.grey,
  );
  static const TextStyle pieNoDataTextLight = TextStyle(
    fontSize: 16,
    color: Colors.black54,
  );
  static const TextStyle pieNoDataTextDark = TextStyle(
    fontSize: 16,
    color: Colors.white70,
  );
  static const TextStyle pieSectionTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.black54,
    fontWeight: FontWeight.w600,
    shadows: [
      Shadow(
        offset: Offset(0, 0),
        blurRadius: 3,
        color: Colors.black38,
      ),
    ],
  );

  // ai metrics label chips
  static const Color productiveLight = Color(0xFFBBDEFB); // Colors.blue[100]
  static const Color productiveDark = Color(0xFF90CAF9); // Colors.blue[200]

  static const Color maintenanceLight = Color(0xFFEEEEEE); // Colors.grey[200]
  static const Color maintenanceDark = Color(0xFFE0E0E0); // Colors.grey[300]

  static const Color wellbeingLight = Color(0xFFC8E6C9); // Colors.green[100]
  static const Color wellbeingDark = Color(0xFFA5D6A7); // Colors.green[200]

  static const Color leisureLight = Color(0xFFE1BEE7); // Colors.purple[100]
  static const Color leisureDark = Color(0xFFCE93D8); // Colors.purple[200]

  static const Color socialLight = Color(0xFFF8BBD0); // Colors.pink[100]
  static const Color socialDark = Color(0xFFF48FB1); // Colors.pink[200]

  static const Color idleLight = Color(0xFFE0E0E0); // Colors.grey[300]
  static const Color idleDark = Color(0xFFBDBDBD); // Colors.grey[400]

  // Lighter background variants (for expanded tiles, etc.)
  static const Color productiveLightest = Color(0xFFE3F2FD); // Colors.blue[50]
  static const Color productiveDarkest =
      Color(0xFFB3E5FC); // Colors.blue[100] again

  static const Color maintenanceLightest =
      Color(0xFFF5F5F5); // Colors.grey[100]
  static const Color maintenanceDarkest = Color(0xFFEEEEEE); // Colors.grey[200]

  static const Color wellbeingLightest = Color(0xFFE8F5E9); // Colors.green[50]
  static const Color wellbeingDarkest = Color(0xFFC8E6C9); // Colors.green[100]

  static const Color leisureLightest = Color(0xFFF3E5F5); // Colors.purple[50]
  static const Color leisureDarkest = Color(0xFFE1BEE7); // Colors.purple[100]

  static const Color socialLightest = Color(0xFFFCE4EC); // Colors.pink[50]
  static const Color socialDarkest = Color(0xFFF8BBD0); // Colors.pink[100]

  static const Color idleLightest = Color(0xFFEEEEEE); // Colors.grey[200]
  static const Color idleDarkest = Color(0xFFE0E0E0); // Colors.grey[300]
}
