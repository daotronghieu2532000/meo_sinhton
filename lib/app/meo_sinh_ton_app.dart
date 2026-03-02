import 'package:flutter/material.dart';
import 'package:meo_sinhton/app/app_controller.dart';
import 'package:meo_sinhton/app/app_strings.dart';
import 'package:meo_sinhton/screens/launch_screen.dart';

class MeoSinhTonApp extends StatelessWidget {
  MeoSinhTonApp({
    super.key,
    required this.initialSplashIndex,
    AppController? appController,
  }) : appController = appController;

  final int initialSplashIndex;
  final AppController? appController;

  @override
  Widget build(BuildContext context) {
    final effectiveController = appController ?? AppController.fallback();
    final lightScheme = ColorScheme.fromSeed(seedColor: Colors.teal);
    final darkScheme = ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.dark,
    );

    ThemeData buildTheme(ColorScheme scheme) {
      return ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16, height: 1.45),
          bodyMedium: TextStyle(fontSize: 14, height: 1.45),
          labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: scheme.primary, width: 1.4),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: scheme.surface,
          selectedItemColor: scheme.primary,
          unselectedItemColor: scheme.onSurfaceVariant,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      );
    }

    return AnimatedBuilder(
      animation: effectiveController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppStrings.appName(),
          theme: buildTheme(lightScheme),
          darkTheme: buildTheme(darkScheme),
          themeMode: effectiveController.themeMode,
          home: LaunchScreen(
            initialSplashIndex: initialSplashIndex,
            appController: effectiveController,
          ),
        );
      },
    );
  }
}
