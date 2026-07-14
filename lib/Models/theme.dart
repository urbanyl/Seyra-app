import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemePreDefinedTextSize{
  Small,
  Medium,
  Large,
}

enum ThemePreDefinedColors{
  white,
  Dark,
  Red,
  Blue,
  Green,
  Yellow,
  Orange
}

class MyTheme with ChangeNotifier{

  late TextTheme text = TextTheme();
  MaterialColor? _selectedMainColor;
  MaterialColor? get selectedMainColorValue => _selectedMainColor;
  double? _selectedTextSize;
  double? get selectedTextSize => _selectedTextSize;

  final appPreDefinedTextSizes = <ThemePreDefinedTextSize,double>{
    ThemePreDefinedTextSize.Small : 7,
    ThemePreDefinedTextSize.Medium : 10,
    ThemePreDefinedTextSize.Large : 30, 
  };

  final appPreDefinedColors = {
    ThemePreDefinedColors.white : MaterialColor(
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
      }
    ),
    ThemePreDefinedColors.Dark : MaterialColor(
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
      }
    ),
    ThemePreDefinedColors.Red : Colors.red,
    ThemePreDefinedColors.Blue : Colors.blue,
    ThemePreDefinedColors.Green : Colors.green,
    ThemePreDefinedColors.Yellow : Colors.yellow,
    ThemePreDefinedColors.Orange : Colors.deepOrange
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
    prefs.setInt('color-value', appPreDefinedColors[preDefinedColors]!.value);
    prefs.setInt('color-shade50', appPreDefinedColors[preDefinedColors]!.shade50.value);
    prefs.setInt('color-shade100', appPreDefinedColors[preDefinedColors]!.shade100.value);
    prefs.setInt('color-shade200', appPreDefinedColors[preDefinedColors]!.shade200.value);
    prefs.setInt('color-shade300', appPreDefinedColors[preDefinedColors]!.shade300.value);
    prefs.setInt('color-shade400', appPreDefinedColors[preDefinedColors]!.shade400.value);
    prefs.setInt('color-shade500', appPreDefinedColors[preDefinedColors]!.shade500.value);
    prefs.setInt('color-shade600', appPreDefinedColors[preDefinedColors]!.shade600.value);
    prefs.setInt('color-shade700', appPreDefinedColors[preDefinedColors]!.shade700.value);
    prefs.setInt('color-shade800', appPreDefinedColors[preDefinedColors]!.shade800.value);
    prefs.setInt('color-shade900', appPreDefinedColors[preDefinedColors]!.shade900.value);
    _selectedMainColor = appPreDefinedColors[preDefinedColors]!;
    notifyListeners();
  }

  Future<void> setTheme() async {
    final prefs= await SharedPreferences.getInstance();
    if(prefs.containsKey('color-value')){
      int value = prefs.getInt('color-value')!;
      final swatch = <int,Color>{
        50 : Color(prefs.getInt('color-shade50')!),
        100 : Color(prefs.getInt('color-shade100')!),
        200 : Color(prefs.getInt('color-shade200')!),
        300 : Color(prefs.getInt('color-shade300')!),
        400 : Color(prefs.getInt('color-shade400')!),
        500 : Color(prefs.getInt('color-shade500')!),
        600 : Color(prefs.getInt('color-shade600')!),
        700 : Color(prefs.getInt('color-shade700')!),
        800 : Color(prefs.getInt('color-shade800')!),
        900 : Color(prefs.getInt('color-shade900')!),
      };
      _selectedMainColor = MaterialColor(value, swatch);
    }else{
      _selectedMainColor = Colors.deepPurple;
    }
    if(prefs.containsKey('textSize') && prefs.getDouble('textSize') != null){
      _selectedTextSize = prefs.getDouble('textSize');
    }else{
      _selectedTextSize = 20;
    }
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
  }

  ThemeData get getTheme {
    final double baseFontSize = _selectedTextSize ?? 16;
    if (_isDarkMode) {
      final Color accent = _selectedMainColor?.shade500 ?? const Color(0xFF3B66FF);
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFFFFFF),
        scaffoldBackgroundColor: const Color(0xFF0F0F11),
        dialogBackgroundColor: const Color(0xFF16161A),
        dividerColor: const Color(0xFFFFFFFF).withOpacity(0.08),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFFFFFFF),
          onPrimary: const Color(0xFF0F0F11),
          secondary: const Color(0xFF222226),
          onSecondary: const Color(0xFFFFFFFF),
          tertiary: accent,
          onTertiary: const Color(0xFFFFFFFF),
          surface: const Color(0xFF16161A),
          onSurface: const Color(0xFFFFFFFF),
          background: const Color(0xFF0F0F11),
          onBackground: const Color(0xFFFFFFFF),
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: const Color(0xFF0F0F11),
          foregroundColor: const Color(0xFFFFFFFF),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
          actionsIconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
          shape: Border(
            bottom: BorderSide(
              color: const Color(0xFFFFFFFF).withOpacity(0.08),
              width: 1,
            ),
          ),
          titleTextStyle: const TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFFFFFFFF),
            letterSpacing: -0.5,
          ),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: const Color(0xFFFFFFFF),
          unselectedLabelColor: const Color(0xFFFFFFFF).withOpacity(0.4),
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
            borderSide: BorderSide(color: accent, width: 4),
            insets: const EdgeInsets.only(bottom: 0),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF16161A),
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
            side: BorderSide(color: const Color(0xFFFFFFFF).withOpacity(0.08), width: 1.0),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFFFFFFFF),
          foregroundColor: const Color(0xFF0F0F11),
          elevation: 0,
          focusElevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
            side: BorderSide(color: accent, width: 2.0),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF16161A),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          hintStyle: TextStyle(color: const Color(0xFFFFFFFF).withOpacity(0.4)),
          labelStyle: TextStyle(color: const Color(0xFFFFFFFF).withOpacity(0.6)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24.0),
            borderSide: BorderSide(color: const Color(0xFFFFFFFF).withOpacity(0.08), width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24.0),
            borderSide: BorderSide(color: const Color(0xFFFFFFFF).withOpacity(0.08), width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24.0),
            borderSide: const BorderSide(color: Color(0xFFFFFFFF), width: 2.0),
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: const Color(0xFF16161A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
            side: BorderSide(color: const Color(0xFFFFFFFF).withOpacity(0.08), width: 1.0),
          ),
        ),
        textTheme: TextTheme(
          headlineLarge: const TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Color(0xFFFFFFFF),
            letterSpacing: -1.0,
          ),
          headlineMedium: const TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFFFFF),
            letterSpacing: -0.5,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: baseFontSize + 2,
            fontWeight: FontWeight.normal,
            color: const Color(0xFFFFFFFF),
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: baseFontSize,
            fontWeight: FontWeight.normal,
            color: const Color(0xFFFFFFFF),
          ),
          labelLarge: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFFFF),
            letterSpacing: 0.05,
          ),
          labelSmall: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFFFFFFFF),
            letterSpacing: 0.02,
          ),
        ),
      );
    }
    final Color accent = _selectedMainColor?.shade500 ?? const Color(0xFF2B54ED);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF111111),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      dialogBackgroundColor: const Color(0xFFFFFFFF),
      dividerColor: const Color(0xFF111111).withOpacity(0.1),
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF111111),
        onPrimary: const Color(0xFFFFFFFF),
        secondary: const Color(0xFFF2F2F2),
        onSecondary: const Color(0xFF111111),
        tertiary: accent,
        onTertiary: const Color(0xFF111111),
        surface: const Color(0xFFFFFFFF),
        onSurface: const Color(0xFF111111),
        background: const Color(0xFFFFFFFF),
        onBackground: const Color(0xFF111111),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFFFFFFF),
        foregroundColor: const Color(0xFF111111),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF111111)),
        actionsIconTheme: const IconThemeData(color: Color(0xFF111111)),
        shape: Border(
          bottom: BorderSide(
            color: const Color(0xFF111111).withOpacity(0.08),
            width: 1,
          ),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Hanken Grotesk',
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Color(0xFF111111),
          letterSpacing: -0.5,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: const Color(0xFF111111),
        unselectedLabelColor: const Color(0xFF111111).withOpacity(0.4),
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
          borderSide: BorderSide(color: accent, width: 4),
          insets: const EdgeInsets.only(bottom: 0),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
          side: BorderSide(color: const Color(0xFF111111).withOpacity(0.1), width: 1.0),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF111111),
        foregroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
          side: BorderSide(color: accent, width: 2.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: TextStyle(color: const Color(0xFF111111).withOpacity(0.4)),
        labelStyle: TextStyle(color: const Color(0xFF111111).withOpacity(0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.0),
          borderSide: BorderSide(color: const Color(0xFF111111).withOpacity(0.1), width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.0),
          borderSide: BorderSide(color: const Color(0xFF111111).withOpacity(0.1), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.0),
          borderSide: const BorderSide(color: Color(0xFF111111), width: 2.0),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
          side: BorderSide(color: const Color(0xFF111111).withOpacity(0.1), width: 1.0),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: const TextStyle(
          fontFamily: 'Hanken Grotesk',
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: Color(0xFF111111),
          letterSpacing: -1.0,
        ),
        headlineMedium: const TextStyle(
          fontFamily: 'Hanken Grotesk',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF111111),
          letterSpacing: -0.5,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Hanken Grotesk',
          fontSize: baseFontSize + 2,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF111111),
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Hanken Grotesk',
          fontSize: baseFontSize,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF111111),
        ),
        labelLarge: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF111111),
          letterSpacing: 0.05,
        ),
        labelSmall: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFF111111),
          letterSpacing: 0.02,
        ),
      ),
    );
  }


}
