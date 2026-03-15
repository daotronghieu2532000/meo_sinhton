import 'package:flutter/material.dart';
import 'package:meo_sinhton/app/app_controller.dart';
import 'package:meo_sinhton/app/app_strings.dart';
import 'package:meo_sinhton/app/admob_config.dart';
import 'package:meo_sinhton/screens/scenario_mode_page.dart';
import 'package:meo_sinhton/screens/settings_screen.dart';
import 'package:meo_sinhton/screens/tip_feed_view.dart';
import 'package:meo_sinhton/screens/emergency_map_screen_improved.dart';
import 'package:meo_sinhton/screens/community_page.dart';
import 'package:meo_sinhton/screens/top_tips_page.dart';
import 'package:meo_sinhton/screens/my_posts_page.dart';
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

  final Set<int> _initializedPages = {0};
  final GlobalKey<TipFeedViewState> _tipFeedKey = GlobalKey<TipFeedViewState>();
  final GlobalKey<CommunityPageState> _communityKey = GlobalKey<CommunityPageState>();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appController,
      builder: (context, _) {
        final isEnglish = widget.appController.isEnglish;
        final titles = [
          AppStrings.appName(),
          AppStrings.tabCommunity(isEnglish),
          AppStrings.tabTop10(isEnglish),
          AppStrings.tabScenario(isEnglish),
          AppStrings.tabMap(isEnglish),
        ];

        final pages = [
          // Index 0: Home
          TipFeedView(
            key: _tipFeedKey,
            appController: widget.appController,
            isEnglish: isEnglish,
          ),
          
          // Index 1: Community (Lazy)
          _initializedPages.contains(1) 
            ? CommunityPage(
                key: _communityKey,
                appController: widget.appController, 
                isEnglish: isEnglish,
              )
            : const Center(child: CircularProgressIndicator()),
            
          // Index 2: Top 10 (Lazy)
          _initializedPages.contains(2) 
            ? TopTipsPage(appController: widget.appController, isEnglish: isEnglish)
            : const Center(child: CircularProgressIndicator()),
            
          // Index 3: Scenario (Lazy)
          _initializedPages.contains(3) 
            ? ScenarioModePage(appController: widget.appController, isEnglish: isEnglish)
            : const Center(child: CircularProgressIndicator()),
            
          // Index 4: Map (Lazy - quan trọng nhất để tránh hỏi quyền ngay khi mở app)
          _initializedPages.contains(4) 
            ? EmergencyMapScreen(appController: widget.appController, isEnglish: isEnglish)
            : const Center(child: CircularProgressIndicator()),
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
              if (_currentIndex == 0 || _currentIndex == 1) // Show on Home and Community tabs
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: isEnglish ? 'Toggle Search' : 'Bật/Tắt tìm kiếm',
                  onPressed: () {
                    if (_currentIndex == 0) {
                      _tipFeedKey.currentState?.toggleSearch();
                    } else if (_currentIndex == 1) {
                      _communityKey.currentState?.toggleSearch();
                    }
                  },
                ),
              IconButton(
                icon: Icon(
                  Icons.history_edu_rounded,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip: isEnglish ? 'My Shared Posts' : 'Bài viết của bạn',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyPostsPage(
                        appController: widget.appController,
                        isEnglish: isEnglish,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  size: 28,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
                onTap: (value) {
                  setState(() {
                    _currentIndex = value;
                    _initializedPages.add(value);
                  });
                },
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home_outlined),
                    activeIcon: const Icon(Icons.home),
                    label: AppStrings.tabHome(isEnglish),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.forum_outlined),
                    activeIcon: const Icon(Icons.forum),
                    label: AppStrings.tabCommunity(isEnglish),
                  ),
                  BottomNavigationBarItem(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.amber, width: 2),
                          ),
                          child: const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                        ),
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Text('10', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    label: AppStrings.tabTop10(isEnglish),
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
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
