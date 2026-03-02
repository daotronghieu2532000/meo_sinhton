import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meo_sinhton/app/app_controller.dart';
import 'package:meo_sinhton/app/app_strings.dart';
import 'package:meo_sinhton/app/constants.dart';
import 'package:meo_sinhton/screens/app_shell.dart';

class LaunchSplashSelector {
  static const String _prefsKey = 'launch_splash_index';

  static Future<int> nextIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_prefsKey) ?? 0;
    final next = (current + 1) % splashAssets.length;
    await prefs.setInt(_prefsKey, next);
    return current;
  }
}

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({
    super.key,
    required this.initialSplashIndex,
    required this.appController,
    this.duration = const Duration(milliseconds: 1800),
  });

  final int initialSplashIndex;
  final AppController appController;
  final Duration duration;

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.duration, () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AppShell(appController: widget.appController),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final splashPath =
        splashAssets[widget.initialSplashIndex % splashAssets.length];

    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          splashPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(
                AppStrings.splashImageNotFound(widget.appController.isEnglish),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          },
        ),
      ),
    );
  }
}
