import 'package:flutter/material.dart';
import 'package:meo_sinhton/app/app_controller.dart';
import 'package:meo_sinhton/app/app_strings.dart';
import 'package:meo_sinhton/app/admob_config.dart';
import 'package:meo_sinhton/screens/category_overview_page.dart';
import 'package:meo_sinhton/screens/scenario_mode_page.dart';
import 'package:meo_sinhton/screens/saved_tips_page.dart';
import 'package:meo_sinhton/screens/settings_screen.dart';
import 'package:meo_sinhton/screens/tip_feed_view.dart';
import 'package:meo_sinhton/screens/emergency_map_screen_improved.dart';
import 'package:meo_sinhton/widgets/logo_placeholder.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

const _isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.appController});

  final AppController appController;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  BannerAd? _bannerAd;
  bool _isBannerReady = false;
  bool _isBannerLoading = false;
  bool _bannerLoadFailed = false;

  bool get _adsSupported {
    if (kIsWeb || _isFlutterTest) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  void _ensureBannerLoaded(double width) {
    if (!_adsSupported ||
        _isBannerLoading ||
        _bannerAd != null ||
        _bannerLoadFailed) {
      return;
    }
    final bannerWidth = width.isFinite && width > 0 ? width.toInt() : 320;

    _isBannerLoading = true;
    final ad = BannerAd(
      adUnitId: AdmobConfig.bannerBottomAdUnitId,
      request: const AdRequest(),
      size: AdSize(width: bannerWidth, height: 60),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isBannerReady = true;
            _isBannerLoading = false;
            _bannerLoadFailed = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) {
            return;
          }
          setState(() {
            _isBannerReady = false;
            _isBannerLoading = false;
            _bannerLoadFailed = true;
          });
        },
      ),
    );
    ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appController,
      builder: (context, _) {
        final isEnglish = widget.appController.isEnglish;
        final titles = [
          AppStrings.appName(),
          AppStrings.tabEmergency(isEnglish),
          AppStrings.tabScenario(isEnglish),
          AppStrings.tabMap(isEnglish),
          AppStrings.tabSaved(isEnglish),
        ];

        final pages = [
          TipFeedView(
            appController: widget.appController,
            isEnglish: isEnglish,
          ),
          TipFeedView(
            appController: widget.appController,
            emergencyOnly: true,
            isEnglish: isEnglish,
          ),
          ScenarioModePage(
            appController: widget.appController,
            isEnglish: isEnglish,
          ),
          EmergencyMapScreen(
            appController: widget.appController,
            isEnglish: isEnglish,
          ),
          SavedTipsPage(
            appController: widget.appController,
            isEnglish: isEnglish,
          ),
        ];
        final shouldShowAds =
            _adsSupported && !widget.appController.areAdsTemporarilyDisabled;
        if (shouldShowAds) {
          _ensureBannerLoaded(MediaQuery.of(context).size.width);
        }

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 8,
            leadingWidth: 76,
            leading: const Padding(
              padding: EdgeInsets.only(left: 12, top: 4, bottom: 4),
              child: LogoPlaceholder(),
            ),
            title: Text(titles[_currentIndex]),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: AppStrings.settings(isEnglish),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SettingsScreen(appController: widget.appController),
                    ),
                  );
                },
              ),
            ],
          ),
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surfaceContainerLowest,
                ],
              ),
            ),
            child: IndexedStack(index: _currentIndex, children: pages),
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (shouldShowAds && _isBannerReady && _bannerAd != null)
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: AdWidget(ad: _bannerAd!),
                ),
              BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (value) => setState(() => _currentIndex = value),
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home_outlined),
                    activeIcon: const Icon(Icons.home),
                    label: AppStrings.tabHome(isEnglish),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.warning_amber_outlined),
                    activeIcon: const Icon(Icons.warning_amber),
                    label: AppStrings.tabEmergency(isEnglish),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.quiz_outlined),
                    activeIcon: const Icon(Icons.quiz),
                    label: AppStrings.tabScenario(isEnglish),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.map_outlined),
                    activeIcon: const Icon(Icons.map),
                    label: AppStrings.tabMap(isEnglish),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.bookmark_border),
                    activeIcon: const Icon(Icons.bookmark),
                    label: AppStrings.tabSaved(isEnglish),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
