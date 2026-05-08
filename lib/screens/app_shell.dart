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
import 'package:meo_sinhton/screens/survival_toolbox_screen.dart';
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

  String _tr(AppLanguage language, String vi, String en, String pl) {
    switch (language) {
      case AppLanguage.english:
        return en;
      case AppLanguage.polish:
        return pl;
      case AppLanguage.vietnamese:
        return vi;
    }
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPrivacyPolicy();
    });
  }

  void _checkPrivacyPolicy() {
    if (!widget.appController.privacyPolicyAccepted) {
      _showPrivacyPolicyDialog();
    }
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          _tr(
            widget.appController.language,
            'Chính sách & Điều khoản',
            'Privacy & Terms',
            'Prywatność i Warunki',
          ),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tr(
                  widget.appController.language,
                  'Chào mừng bạn đến với LifeSpark. Để tiếp tục, vui lòng xác nhận rằng bạn đồng ý với các điều khoản sau:',
                  'Welcome to LifeSpark. To continue, please confirm that you agree to the following terms:',
                  'Witaj trong LifeSpark. Aby kontynuować, potwierdź, że zgadzasz się na następujące warunki:',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _policyItem(
                '1. ',
                _tr(
                  widget.appController.language,
                  'Dữ liệu cá nhân: Chúng tôi thu thập ID thiết bị và vị trí (nếu được phép) để cung cấp tính năng bản đồ và quảng cáo. Dữ liệu này KHÔNG được bán cho bên thứ ba vì mục đích thương mại ngoài luồng.',
                  'Personal Data: We collect Device ID and Location (if permitted) to provide map features and ads. This data is NOT sold to third parties for external commercial purposes.',
                  'Dane osobowe: Zbieramy ID urządzenia i lokalizację (jeśli dozwolone), aby zapewnić funkcje map i reklam. Te dane NIE są bán cho bên thứ ba.',
                ),
              ),
              _policyItem(
                '2. ',
                _tr(
                  widget.appController.language,
                  'Nội dung người dùng: Bạn chịu trách nhiệm về nội dung mình đăng tải. Nghiêm cấm ngôn từ thù ghét, bạo lực hoặc vi phạm pháp luật.',
                  'User Content: You are responsible for the content you post. Hate speech, violence, or illegal content is strictly prohibited.',
                  'Treść użytkownika: Jesteś odpowiedzialny za publikowane treści. Mowa nienawiści, przemoc lub treści nielegalne są surowo zabronione.',
                ),
              ),
              _policyItem(
                '3. ',
                _tr(
                  widget.appController.language,
                  'Quyền xóa dữ liệu: Bạn có quyền xóa tài khoản và toàn bộ dữ liệu liên quan bất cứ lúc nào trong phần Cài đặt.',
                  'Data Deletion: You have the right to delete your account and all associated data at any time in Settings.',
                  'Usuwanie danych: Masz prawo do usunięcia swojego konta i wszystkich powiązanych danych w dowolnym momencie w Ustawieniach.',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.appController.acceptPrivacyPolicy();
              Navigator.pop(context);
            },
            child: Text(
              _tr(
                widget.appController.language,
                'Đồng ý và Tiếp tục',
                'Agree & Continue',
                'Zgadzam się',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _policyItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(number, style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  final Set<int> _initializedPages = {0};
  final GlobalKey<TipFeedViewState> _tipFeedKey = GlobalKey<TipFeedViewState>();
  final GlobalKey<CommunityPageState> _communityKey =
      GlobalKey<CommunityPageState>();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appController,
      builder: (context, _) {
        final language = widget.appController.language;
        final isEnglish = language == AppLanguage.english;
        final titles = [
          _tr(language, 'Công cụ sinh tồn', 'Survival Tools', 'Narzędzia'),
          _tr(language, 'Bản đồ cứu hộ', 'Rescue Map', 'Mapa'),
          _tr(language, 'Kiến thức sinh tồn', 'Survival Skills', 'Wiedza'),
          _tr(language, 'Tình huống giả lập', 'Scenarios', 'Scenariusze'),
          _tr(language, 'Cộng đồng', 'Community', 'Społeczność'),
        ];

        final pages = [
          // Index 0: Survival Toolbox (Native Functionality)
          SurvivalToolboxScreen(
            appController: widget.appController,
          ),

          // Index 1: Map (Native Functionality)
          _initializedPages.contains(1)
              ? EmergencyMapScreen(
                  appController: widget.appController,
                  isEnglish: isEnglish,
                )
              : const Center(child: CircularProgressIndicator()),

          // Index 2: Home (Tips Feed)
          _initializedPages.contains(2)
              ? TipFeedView(
                  key: _tipFeedKey,
                  appController: widget.appController,
                  isEnglish: isEnglish,
                )
              : const Center(child: CircularProgressIndicator()),

          // Index 3: Scenario (Lazy)
          _initializedPages.contains(3)
              ? ScenarioModePage(
                  appController: widget.appController,
                  isEnglish: isEnglish,
                )
              : const Center(child: CircularProgressIndicator()),

          // Index 4: Community (Lazy)
          _initializedPages.contains(4)
              ? CommunityPage(
                  key: _communityKey,
                  appController: widget.appController,
                  isEnglish: isEnglish,
                )
              : const Center(child: CircularProgressIndicator()),
        ];
        final shouldShowAds =
            _adsSupported && !widget.appController.areAdsTemporarilyDisabled;
        if (shouldShowAds) {
          _ensureBannerLoaded(MediaQuery.of(context).size.width);
        }

        return Scaffold(
          drawer: Drawer(
            child: Column(
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primaryContainer,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const LogoPlaceholder(),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.appName(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.emoji_events, color: Colors.amber),
                  title: Text(_tr(language, 'Top 10 Góp ý', 'Top 10 Community', 'Top 10 Społeczność')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TopTipsPage(
                          appController: widget.appController,
                          isEnglish: isEnglish,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history_edu_rounded),
                  title: Text(_tr(language, 'Bài viết của bạn', 'My Shared Posts', 'Twoje posty')),
                  onTap: () {
                    Navigator.pop(context);
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
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(_tr(language, 'Cài đặt', 'Settings', 'Ustawienia')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(appController: widget.appController),
                      ),
                    );
                  },
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Version 1.0.0 (8)',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          appBar: AppBar(
            titleSpacing: 0,
            title: Text(titles[_currentIndex]),
            actions: [
              if (_currentIndex == 0) // Show Top 10 shortcut only on Home
                IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.emoji_events_outlined,
                        size: 26,
                        color: Colors.amber,
                      ),
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '10',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  tooltip: _tr(language, 'Top 10 nổi bật', 'Top 10 Featured', 'Top 10 Wyróżnione'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TopTipsPage(
                          appController: widget.appController,
                          isEnglish: isEnglish,
                        ),
                      ),
                    );
                  },
                ),
              if (_currentIndex == 2) // Show search only on Tips tab (now index 2)
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: isEnglish ? 'Toggle Search' : 'Bật/Tắt tìm kiếm',
                  onPressed: () {
                    _tipFeedKey.currentState?.toggleSearch();
                  },
                ),
              if (_currentIndex == 4) // Show search on Community tab (now index 4)
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: isEnglish ? 'Toggle Search' : 'Bật/Tắt tìm kiếm',
                  onPressed: () {
                    _communityKey.currentState?.toggleSearch();
                  },
                ),
              IconButton(
                icon: Icon(
                  Icons.history_edu_rounded,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip: _tr(
                  language,
                  'Bài viết của bạn',
                  'My Shared Posts',
                  'Twoje posty',
                ),
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
              // Removed SurvivalToolbox icon from here as it's now in the BottomNavigationBar
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  size: 28,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                tooltip: _tr(language, 'Cài đặt', 'Settings', 'Ustawienia'),
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
                    icon: const Icon(Icons.handyman_outlined),
                    activeIcon: const Icon(Icons.handyman),
                    label: _tr(language, 'Công cụ', 'Tools', 'Narzędzia'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.map_outlined),
                    activeIcon: const Icon(Icons.map),
                    label: _tr(language, 'Bản đồ', 'Map', 'Mapa'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.menu_book_outlined),
                    activeIcon: const Icon(Icons.menu_book),
                    label: _tr(language, 'Kiến thức', 'Knowledge', 'Wiedza'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.quiz_outlined),
                    activeIcon: const Icon(Icons.quiz),
                    label: _tr(
                      language,
                      'Tình huống',
                      'Scenarios',
                      'Scenariusze',
                    ),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.forum_outlined),
                    activeIcon: const Icon(Icons.forum),
                    label: _tr(language, 'Cộng đồng', 'Community', 'Społeczność'),
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
