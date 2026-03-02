import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:meo_sinhton/app/app_controller.dart';
import 'package:meo_sinhton/app/meo_sinh_ton_app.dart';
import 'package:meo_sinhton/screens/launch_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await MobileAds.instance.initialize();
  } catch (_) {}

  final splashIndex = await LaunchSplashSelector.nextIndex();

  AppController appController;
  try {
    appController = await AppController.load();
  } catch (_) {
    appController = AppController.fallback();
  }

  runApp(
    MeoSinhTonApp(
      initialSplashIndex: splashIndex,
      appController: appController,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MeoSinhTonApp(
      initialSplashIndex: 0,
      appController: AppController.fallback(),
    );
  }
}
