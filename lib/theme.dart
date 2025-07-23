// theme.dart, stores app theme and defined custom styles

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: Colors.amber[700]!,
      secondary: Colors.orangeAccent,
      surfaceContainer: const Color(0xFFF5F5F5),
      surfaceContainerHigh: const Color(0xFFEEEEEE),
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
      surfaceContainer: const Color(0xFF1C1C1C),
      surfaceContainerHigh: const Color(0xFF2E2E2E),
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

  // black and white
  static const Color baseBlack = Colors.black;
  static const Color baseWhite = Colors.white;

  // light theme text
  static const Color textTitleLight = Colors.black;
  static const Color textPrimaryLight = Colors.black87;
  static const Color textSecondaryLight = Colors.black54;
  static const Color textDisabledLight = Colors.black38;
  static const Color textHintLight = Color(0xFF757575); // app bar icon grey

  // dark theme text
  static const Color textTitleDark = Colors.white;
  static const Color textPrimaryDark = Colors.white70;
  static const Color textSecondaryDark = Colors.white60;
  static const Color textDisabledDark = Colors.white38;
  static const Color textHintDark = Colors.grey; // or Colors.grey[400]

  // icon colours
  static const Color iconDefaultLight = Color(0xFF757575); // dark grey
  static const Color iconDefaultDark = Color(0xFFBDBDBD); // light grey

  static const Color iconDisabledLight = Colors.black38;
  static const Color iconDisabledDark = Colors.white38;

  // red for deletion
  static const Color iconDeleteContent = Colors.redAccent;

  // light theme
  static const Color surfaceLowLight =
      Color(0xFFF5F5F5); // same as pieBackgroundLight
  static const Color surfaceHighLight = Color(0xFFEEEEEE); // matches existing
  static const Color inputFillLight = Color(0xFFEEEEEE); // grey[200]
  static const Color inputBorderLight = Color(0xFFEEEEEE); // grey[200]
  static const Color hintTextLight = Color(0xFF757575); // grey[600]

  // dark theme
  static const Color surfaceLowDark = Color(0xFF1C1C1C); // same as calendar bg
  static const Color surfaceHighDark = Color(0xFF2E2E2E); // higher layer
  static const Color inputFillDark = Color(0xFF424242); // grey[800]
  static const Color inputBorderDark = Color(0xFF424242); // grey[800]
  static const Color hintTextDark = Color(0xFFBDBDBD); // grey[400]

  // badge colors (for both themes)
  static const Color badgeYellow = Color(0xFFFAEA82);
  static const Color badgeGreen = Color(0xFF85F981);
  static const Color badgeBlue = Color(0xFF82E1FB);
  static const Color badgePurple = Color(0xFFD385FD);
  static const Color badgeRed = Color(0xFFFE8486);
  static const Color badgeGrey = Color(0xFFE2E1DD);

  // chart lines
  static const Color chartDashedLine = Color(0xFFBDBDBD); // from grey.shade400

  // pie chart background
  static const Color pieBackgroundDark = Color(0xFF464646);
  static const Color pieBackgroundLight = Color(0xFFF5F5F5);

  // pie and bar text styles
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

  // lighter background variants (for expanded tiles, etc.)
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

  // current month/ year dot
  static const currentDotColor = Colors.lightBlueAccent;

  static const Color greyDark = Color(0xFF616161); // grey[700]

  // table calendar styles
  // light theme
  static const Color weekHighlightLight = Color(0xFFFFE0B2); // orange[100]
  static const BoxDecoration calendarTodayDecorationLight = BoxDecoration(
    color: Colors.lightBlueAccent,
    shape: BoxShape.circle,
  );
  static const BoxDecoration calendarRangeHighlightLight = BoxDecoration(
    color: weekHighlightLight,
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );
  static const TextStyle calendarDayTextLight = TextStyle(
    fontSize: 12,
    color: Colors.black87,
  );
  static const TextStyle calendarWeekendTextLight = TextStyle(
    fontSize: 12,
    color: Colors.orange,
  );
  static const TextStyle calendarOutsideTextLight = TextStyle(
    fontSize: 12,
    color: Colors.black26,
  );
  static const HeaderStyle calendarHeaderLight = HeaderStyle(
    formatButtonVisible: false,
    titleCentered: true,
    titleTextStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.black54,
    ),
    leftChevronIcon:
        Icon(Icons.chevron_left, size: 20, color: Color(0xFF757575)),
    rightChevronIcon:
        Icon(Icons.chevron_right, size: 18, color: AppTheme.idleDarkest),
  );
  static final DaysOfWeekStyle calendarDaysOfWeekLight = DaysOfWeekStyle(
    dowTextFormatter: (date, locale) => DateFormat.E(locale).format(date)[0],
    weekdayStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Colors.black38,
    ),
    weekendStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Colors.orange,
    ),
  );
  static const BoxDecoration calendarSelectedDecorationLight = BoxDecoration(
    color: Colors.orange,
    shape: BoxShape.circle,
  );
  static const CalendarStyle calendarStyleLight = CalendarStyle(
    selectedDecoration: BoxDecoration(),
    todayDecoration: calendarTodayDecorationLight,
    rangeHighlightColor: weekHighlightLight,
    rangeHighlightScale: 1.0,
    defaultTextStyle: calendarDayTextLight,
    weekendTextStyle: calendarWeekendTextLight,
    outsideTextStyle: calendarOutsideTextLight,
  );

  // dark theme
  static const Color weekHighlightDark = Color(0xFFFFCC80); // orange[200]
  static const BoxDecoration calendarTodayDecorationDark = BoxDecoration(
    color: Colors.lightBlueAccent,
    shape: BoxShape.circle,
  );
  static const BoxDecoration calendarRangeHighlightDark = BoxDecoration(
    color: weekHighlightDark,
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );
  static const TextStyle calendarDayTextDark = TextStyle(
    fontSize: 12,
    color: Colors.white70,
  );
  static const TextStyle calendarWeekendTextDark = TextStyle(
    fontSize: 12,
    color: Colors.orange,
  );
  static const TextStyle calendarOutsideTextDark = TextStyle(
    fontSize: 12,
    color: Colors.white30,
  );
  static const HeaderStyle calendarHeaderDark = HeaderStyle(
    formatButtonVisible: false,
    titleCentered: true,
    titleTextStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white70,
    ),
    leftChevronIcon:
        Icon(Icons.chevron_left, size: 20, color: Color(0xFFB0B0B0)),
    rightChevronIcon:
        Icon(Icons.chevron_right, size: 18, color: Color(0xFF757575)),
  );
  static final DaysOfWeekStyle calendarDaysOfWeekDark = DaysOfWeekStyle(
    dowTextFormatter: (date, locale) => DateFormat.E(locale).format(date)[0],
    weekdayStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Colors.white54,
    ),
    weekendStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Colors.orange,
    ),
  );
  static const BoxDecoration calendarSelectedDecorationDark = BoxDecoration(
    color: Colors.orange,
    shape: BoxShape.circle,
  );
  static const CalendarStyle calendarStyleDark = CalendarStyle(
    selectedDecoration: BoxDecoration(),
    todayDecoration: calendarTodayDecorationDark,
    rangeHighlightColor: weekHighlightDark,
    rangeHighlightScale: 1.0,
    defaultTextStyle: calendarDayTextDark,
    weekendTextStyle: calendarWeekendTextDark,
    outsideTextStyle: calendarOutsideTextDark,
  );
}
