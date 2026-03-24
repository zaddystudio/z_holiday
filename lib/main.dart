import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

// We use a global ValueNotifier so any screen can toggle the theme instantly!
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() {
  runApp(const HolidayApp());
}

class HolidayApp extends StatelessWidget {
  const HolidayApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'World Holidays',
          debugShowCheckedModeBanner: false,
          // --- LIGHT THEME SETTINGS ---
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.green.shade800,
              foregroundColor: Colors.white,
            ),
          ),
          // --- DARK THEME SETTINGS ---
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey.shade900,
              foregroundColor: Colors.white,
            ),
            scaffoldBackgroundColor: Colors.black,
            // FIXED: Changed CardTheme to CardThemeData to match the latest Flutter update!
            cardTheme: CardThemeData(color: Colors.grey.shade900),
          ),
          themeMode: currentMode, // Listens to our toggle button!
          home: const HomeScreen(),
        );
      },
    );
  }
}
