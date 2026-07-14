import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemePreDefinedTextSize {
  Small,
  Medium,
  Large,
}

enum ThemePreDefinedColors {
  white,
  Dark,
  Red,
  Blue,
  Green,
  Yellow,
  Orange,
}

class MyTheme with ChangeNotifier {
  late TextTheme text = TextTheme();
  MaterialColor? _selectedMainColor;
  MaterialColor? get selectedMainColorValue => _selectedMainColor;
  double? _selectedTextSize;
  double? get selectedTextSize => _selectedTextSize;

  final appPreDefinedTextSizes = <ThemePreDefinedTextSize, double>{
    ThemePreDefinedTextSize.Small: 7,
    ThemePreDefinedTextSize.Medium: 10,
    ThemePreDefinedTextSize.Large: 30,
  };

  final appPreDefinedColors = {
    ThemePreDefinedColors.white: MaterialColor(
      Colors.white.value,
      <int, Color>{
        50: Colors.white54,
        100: Colors.white60,
        200: Colors.white70,
        300: Colors.grey.shade300,
        400: Colors.grey.shade400,
        500: Colors.grey,
        600: Colors.grey.shade600,
        700: Colors.white,
        800: Colors.white,
        900: Colors.white,
      },
    ),
    ThemePreDefinedColors.Dark: MaterialColor(
      Colors.black.value,
      const <int, Color>{
        50: Colors.black,
        100: Colors.black,
        200: Colors.black,
        300: Colors.black,
        400: Colors.black,
        500: Colors.black,
        600: Colors.black,
        700: Colors.black,
        800: Colors.black,
        900: Colors.black,
      },
    ),
    ThemePreDefinedColors.Red: Colors.red,
    ThemePreDefinedColors.Blue: Colors.blue,
    ThemePreDefinedColors.Green: Colors.green,
    ThemePreDefinedColors.Yellow: Colors.yellow,
    ThemePreDefinedColors.Orange: Colors.deepOrange,
  };

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = value;
    await prefs.setBool('isDarkMode', value);
    notifyListeners();
  }

  void selectTextSize(ThemePreDefinedTextSize preDefinedTextSize) async {
    final prefs = await SharedPreferences.getInstance();
    _selectedTextSize = appPreDefinedTextSizes[preDefinedTextSize]!;
    prefs.setDouble('textSize', _selectedTextSize ?? 20);
    notifyListeners();
  }

  void selectedMainColor(ThemePreDefinedColors preDefinedColors) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(
        'color-value', appPreDefinedColors[preDefinedColors]!.value);
    prefs.setInt('color-shade50',
        appPreDefinedColors[preDefinedColors]!.shade50.value);
    prefs.setInt('color-shade100',
        appPreDefinedColors[preDefinedColors]!.shade100.value);
    prefs.setInt('color-shade200',
        appPreDefinedColors[preDefinedColors]!.shade200.value);
    prefs.setInt('color-shade300',
        appPreDefinedColors[preDefinedColors]!.shade300.value);
    prefs.setInt('color-shade400',
        appPreDefinedColors[preDefinedColors]!.shade400.value);
    prefs.setInt('color-shade500',
        appPreDefinedColors[preDefinedColors]!.shade500.value);
    prefs.setInt('color-shade600',
        appPreDefinedColors[preDefinedColors]!.shade600.value);
    prefs.setInt('color-shade700',
        appPreDefinedColors[preDefinedColors]!.shade700.value);
    prefs.setInt('color-shade800',
        appPreDefinedColors[preDefinedColors]!.shade800.value);
    prefs.setInt('color-shade900',
        appPreDefinedColors[preDefinedColors]!.shade900.value);
    _selectedMainColor = appPreDefinedColors[preDefinedColors]!;
    notifyListeners();
  }

  Future<void> setTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('color-value')) {
      int value = prefs.getInt('color-value')!;
      final swatch = <int, Color>{
        50: Color(prefs.getInt('color-shade50')!),
        100: Color(prefs.getInt('color-shade100')!),
        200: Color(prefs.getInt('color-shade200')!),
        300: Color(prefs.getInt('color-shade300')!),
        400: Color(prefs.getInt('color-shade400')!),
        500: Color(prefs.getInt('color-shade500')!),
        600: Color(prefs.getInt('color-shade600')!),
        700: Color(prefs.getInt('color-shade700')!),
        800: Color(prefs.getInt('color-shade800')!),
        900: Color(prefs.getInt('color-shade900')!),
      };
      _selectedMainColor = MaterialColor(value, swatch);
    } else {
      _selectedMainColor = Colors.deepPurple;
    }
    if (prefs.containsKey('textSize') &&
        prefs.getDouble('textSize') != null) {
      _selectedTextSize = prefs.getDouble('textSize');
    } else {
      _selectedTextSize = 20;
    }
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
  }

  ThemeData get getTheme {
    final double baseFontSize = _selectedTextSize ?? 16;
    if (_isDarkMode) {
      return _buildDarkTheme(baseFontSize);
    }
    return _buildLightTheme(baseFontSize);
  }

  ThemeData _buildDarkTheme(double baseFontSize) {
    final Color accent =
        _selectedMainColor?.shade500 ?? const Color(0xFF6C63FF);
    final Color accentLight =
        _selectedMainColor?.shade300 ?? const Color(0xFF9D97FF);
    final surface = const Color(0xFF1A1A2E);
    final surfaceElevated = const Color(0xFF222240);
    final bg = const Color(0xFF0F0F1A);
    final border = Colors.white.withOpacity(0.06);
    final borderFocus = accent.withOpacity(0.6);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: accent,
      scaffoldBackgroundColor: bg,
      dialogBackgroundColor: surface,
      dividerColor: border,
      colorScheme: ColorScheme.dark(
        primary: accent,
        onPrimary: Colors.white,
        secondary: surfaceElevated,
        onSecondary: Colors.white,
        tertiary: accent,
        onTertiary: Colors.white,
        surface: surface,
        onSurface: const Color(0xFFE8E8F0),
        background: bg,
        onBackground: const Color(0xFFE8E8F0),
        error: const Color(0xFFFF5252),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bg,
        foregroundColor: const Color(0xFFE8E8F0),
        centerTitle: true,
        iconTheme: IconThemeData(color: const Color(0xFFE8E8F0).withOpacity(0.8)),
        titleTextStyle: const TextStyle(
          fontFamily: 'Hanken Grotesk',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Color(0xFFE8E8F0),
          letterSpacing: -0.5,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: const Color(0xFFE8E8F0).withOpacity(0.35),
        labelStyle: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
        ),
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: accent, width: 3),
          insets: const EdgeInsets.only(bottom: 0),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: border, width: 1.0),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle:
            TextStyle(color: const Color(0xFFE8E8F0).withOpacity(0.3)),
        labelStyle:
            TextStyle(color: const Color(0xFFE8E8F0).withOpacity(0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: BorderSide(color: border, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: BorderSide(color: border, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: BorderSide(color: accent, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: const BorderSide(
              color: Color(0xFFFF5252), width: 1.0),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return const Color(0xFF666680);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent;
          }
          return const Color(0xFF333350);
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: accent.withOpacity(0.15),
        thumbColor: accent,
        overlayColor: accent.withOpacity(0.1),
        trackHeight: 4,
        thumbShape:
            const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE8E8F0),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceElevated,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.0),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: const TextStyle(
          fontFamily: 'Hanken Grotesk',
          color: Color(0xFFE8E8F0),
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Hanken Grotesk',
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: const Color(0xFFE8E8F0),
          letterSpacing: -1.0,
        ),
        headlineMedium: const TextStyle(
          fontFamily: 'Hanken Grotesk',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE8E8F0),
          letterSpacing: -0.5,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Hanken Grotesk',
          fontSize: baseFontSize + 2,
          fontWeight: FontWeight.normal,
          color: const Color(0xFFE8E8F0),
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Hanken Grotesk',
          fontSize: baseFontSize,
          fontWeight: FontWeight.normal,
          color: const Color(0xFFE8E8F0),
        ),
        labelLarge: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE8E8F0),
          letterSpacing: 0.05,
        ),
        labelSmall: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFFE8E8F0),
          letterSpacing: 0.02,
        ),
      ),
    );
  }

  ThemeData _buildLightTheme(double baseFontSize) {
    final Color accent =
        _selectedMainColor?.shade500 ?? const Color(0xFF5B4FD6);
    final surface = const Color(0xFFF8F9FC);
    final surfaceElevated = const Color(0xFFFFFFFF);
    final bg = const Color(0xFFFFFFFF);
    final border = const Color(0xFF111111).withOpacity(0.08);
    final textPrimary = const Color(0xFF1A1A2E);
    final textSecondary =
        const Color(0xFF1A1A2E).withOpacity(0.5);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: accent,
      scaffoldBackgroundColor: bg,
      dialogBackgroundColor: surfaceElevated,
      dividerColor: border,
      colorScheme: ColorScheme.light(
        primary: accent,
        onPrimary: Colors.white,
        secondary: surface,
        onSecondary: textPrimary,
        tertiary: accent,
        onTertiary: Colors.white,
        surface: surfaceElevated,
        onSurface: textPrimary,
        background: bg,
        onBackground: textPrimary,
        error: const Color(0xFFE53935),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bg,
        foregroundColor: textPrimary,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'Hanken Grotesk',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: textSecondary,
        labelStyle: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
        ),
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: accent, width: 3),
          insets: const EdgeInsets.only(bottom: 0),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceElevated,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: border, width: 1.0),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: TextStyle(color: textSecondary),
        labelStyle: TextStyle(
            color: const Color(0xFF1A1A2E).withOpacity(0.5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: BorderSide(color: border, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: BorderSide(color: border, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: BorderSide(color: accent, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: const BorderSide(
              color: Color(0xFFE53935), width: 1.0),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent;
          }
          return Colors.grey.shade300;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: accent.withOpacity(0.15),
        thumbColor: accent,
        overlayColor: accent.withOpacity(0.1),
        trackHeight: 4,
        thumbShape:
            const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceElevated,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.0),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(
          fontFamily: 'Hanken Grotesk',
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Hanken Grotesk',
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -1.0,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Hanken Grotesk',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Hanken Grotesk',
          fontSize: baseFontSize + 2,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Hanken Grotesk',
          fontSize: baseFontSize,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Geist',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.05,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Geist',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: 0.02,
        ),
      ),
    );
  }
}
