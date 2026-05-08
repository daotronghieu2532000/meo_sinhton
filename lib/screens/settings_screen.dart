import 'package:flutter/material.dart';
import 'package:meo_sinhton/app/app_controller.dart';
import 'package:meo_sinhton/app/app_strings.dart';
import 'package:meo_sinhton/app/admob_config.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:meo_sinhton/screens/saved_tips_page.dart';
import 'package:meo_sinhton/screens/my_posts_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'dart:async';

const _isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.appController});

  final AppController appController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoadingRewardedAd = false;
  RewardedAd? _rewardedAd;
  int _adLoadAttempts = 0;

  bool _isUsingTestId = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initATT());
  }

  Future<void> _initATT() async {
    if (_adsSupported) {
      try {
        final status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          await Future.delayed(const Duration(milliseconds: 1000));
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      } catch (e) {
        debugPrint('Error requesting ATT: $e');
      }
      _loadRewardedAd();
    }
  }

  void _loadRewardedAd({bool useTestId = false}) {
    final adUnitId = useTestId 
        ? 'ca-app-pub-3940256099942544/1712485313' // Google Test ID
        : AdmobConfig.rewardedAdUnitId;

    _isUsingTestId = useTestId;

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _rewardedAd = ad;
            _adLoadAttempts = 0;
          });
          debugPrint('Rewarded Ad Loaded: ${useTestId ? "TEST" : "PROD"}');
        },
        onAdFailedToLoad: (error) {
          debugPrint('Ad failed to load: $error');
          if (!mounted) return;
          setState(() {
            _rewardedAd = null;
            _adLoadAttempts++;
          });
          
          // Nếu mã thật lỗi, thử dùng mã test sau 2 lần thất bại
          if (_adLoadAttempts >= 2 && !useTestId) {
             _loadRewardedAd(useTestId: true);
          } else if (_adLoadAttempts < 5) {
            Future.delayed(const Duration(seconds: 5), () => _loadRewardedAd(useTestId: useTestId));
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  String _tr({required String vi, required String en, required String pl}) {
    switch (widget.appController.language) {
      case AppLanguage.english:
        return en;
      case AppLanguage.polish:
        return pl;
      case AppLanguage.vietnamese:
        return vi;
    }
  }

  Widget _tileIcon({
    required IconData icon,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 16, color: foreground),
    );
  }

  Widget _tileCard({required Widget child}) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: child,
    );
  }

  bool get _adsSupported {
    if (kIsWeb || _isFlutterTest) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<bool> _showRewardedAd() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_tr(
              vi: 'Không có kết nối Internet. Vui lòng kiểm tra lại mạng.',
              en: 'No internet connection. Please check your network.',
              pl: 'Brak połączenia z Internetem. Sprawdź swoją sieć.',
            )),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    // Nếu chưa có ad, ép tải lại ngay và chờ tối đa 10s
    if (_rewardedAd == null) {
      _loadRewardedAd(useTestId: _adLoadAttempts >= 2);
      int waitCount = 0;
      while (_rewardedAd == null && waitCount < 20 && mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        waitCount++;
      }
    }

    if (_rewardedAd == null || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_tr(
              vi: 'Đang chuẩn bị quảng cáo, vui lòng đợi trong giây lát...',
              en: 'Preparing ad, please wait a moment...',
              pl: 'Przygotowywanie reklamy, proszę czờać chwilę...',
            )),
          ),
        );
      }
      return false;
    }

    final completer = Completer<bool>();
    bool earnedReward = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        if (!completer.isCompleted) {
          completer.complete(earnedReward);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (_, __) {
        earnedReward = true;
      },
    );

    return completer.future;
  }

  Future<void> _handleRewardAction() async {
    final isEnglish = widget.appController.isEnglish;
    final isPolish = widget.appController.isPolish;

    if (!_adsSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPolish
                ? 'AdMob nie jest obslugiwany na tym urzadzeniu.'
                : AppStrings.adsNotSupported(isEnglish),
          ),
        ),
      );
      return;
    }

    if (widget.appController.areAdsTemporarilyDisabled) {
      return;
    }

    if (_isLoadingRewardedAd) {
      return;
    }

    setState(() => _isLoadingRewardedAd = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPolish
              ? 'Ladowanie reklamy z nagroda...'
              : AppStrings.loadingRewardAd(isEnglish),
        ),
      ),
    );

    final earned = await _showRewardedAd();

    if (!mounted) {
      return;
    }

    setState(() => _isLoadingRewardedAd = false);

    if (earned) {
      await widget.appController.grantAdFreeForOneHour();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPolish
                ? 'Reklamy sa wylaczone na 1 godzine.'
                : AppStrings.rewardGranted(isEnglish),
          ),
        ),
      );
    }
  }

  Future<void> _openContactEmail() async {
    final isEnglish = widget.appController.isEnglish;
    final isPolish = widget.appController.isPolish;
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'trongh138@gmail.com',
      queryParameters: {
        'subject': isPolish
            ? 'Opinie o aplikacji Meo Sinh Ton'
            : isEnglish
            ? 'Feedback for Meo Sinh Ton'
            : 'Góp ý cho ứng dụng Mẹo Sinh Tồn',
      },
    );

    try {
      final canOpen = await canLaunchUrl(emailUri);
      if (!canOpen) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEnglish
                  ? 'No email app found on this device.'
                  : isPolish
                  ? 'Na tym urzadzeniu nie znaleziono aplikacji e-mail.'
                  : 'Thiết bị này chưa có ứng dụng email.',
            ),
          ),
        );
        return;
      }

      final launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEnglish
                  ? 'Could not open email app on this device.'
                  : isPolish
                  ? 'Nie mozna otworzyc aplikacji e-mail na tym urzadzeniu.'
                  : 'Không mở được ứng dụng email trên thiết bị này.',
            ),
          ),
        );
      }
    } on PlatformException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEnglish
                ? 'Email feature is not ready yet. Please restart the app and try again.'
                : isPolish
                ? 'Funkcja e-mail nie jest jeszcze gotowa. Uruchom ponownie aplikacje i sprobuj ponownie.'
                : 'Tính năng email chưa sẵn sàng. Hãy khởi động lại app rồi thử lại.',
          ),
        ),
      );
    } on MissingPluginException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEnglish
                ? 'Email feature is not ready yet. Please restart the app and try again.'
                : isPolish
                ? 'Funkcja e-mail nie jest jeszcze gotowa. Uruchom ponownie aplikacje i sprobuj ponownie.'
                : 'Tính năng email chưa sẵn sàng. Hãy khởi động lại app rồi thử lại.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appController,
      builder: (context, _) {
        final isEnglish = widget.appController.isEnglish;
        final isPolish = widget.appController.isPolish;
        final adRemaining = widget.appController.adFreeRemaining;
        final scheme = Theme.of(context).colorScheme;
        final adSubtitle = widget.appController.areAdsTemporarilyDisabled
            ? isPolish
                  ? 'Reklamy wylaczone jeszcze przez ${adRemaining?.inHours ?? 0} godz. ${(adRemaining?.inMinutes.remainder(60)) ?? 0} min'
                  : AppStrings.adsDisabledRemaining(
                      isEnglish,
                      adRemaining ?? Duration.zero,
                    )
            : _tr(
                vi: 'Xem quảng cáo thưởng để tắt toàn bộ quảng cáo trong 1 giờ.',
                en: 'Watch a rewarded ad to disable all ads for 1 hour.',
                pl: 'Obejrzyj reklame z nagroda, aby wylaczyc wszystkie reklamy na 1 godzine.',
              );

        return Scaffold(
          appBar: AppBar(
            title: Text(_tr(vi: 'Cài đặt', en: 'Settings', pl: 'Ustawienia')),
          ),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  onTap: _openContactEmail,
                  leading: Icon(Icons.mail_outline, color: Colors.red.shade500),
                  title: Text(
                    _tr(
                      vi: 'Phản hồi & Liên hệ',
                      en: 'Feedback & Contact',
                      pl: 'Opinie i kontakt',
                    ),
                  ),
                  subtitle: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                      children: [
                        TextSpan(
                          text: isEnglish
                              ? 'Your feedback and app rating are very important to me. Please contact me at Gmail: '
                              : isPolish
                              ? 'Twoja opinia i ocena aplikacji sa dla mnie bardzo wazne. Skontaktuj sie ze mna przez Gmail: '
                              : 'Mọi ý kiến đóng góp và đánh giá app của bạn đều rất quan trọng với tôi. Hãy liên lạc qua Gmail: ',
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: _openContactEmail,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                'trongh138@gmail.com',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ),
                        ),
                        TextSpan(
                          text: isEnglish
                              ? '. Sincerely ❤️'
                              : isPolish
                              ? '. Z wyrazami szacunku ❤️'
                              : '. Trân trọng ❤️',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _tileCard(
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  leading: _tileIcon(
                    icon: Icons.translate_outlined,
                    background: scheme.primaryContainer,
                    foreground: scheme.onPrimaryContainer,
                  ),
                  title: Text(_tr(vi: 'Ngôn ngữ', en: 'Language', pl: 'Jezyk')),
                  subtitle: Text(
                    _tr(
                      vi: 'Chọn ngôn ngữ hiển thị',
                      en: 'Select display language',
                      pl: 'Wybierz jezyk wyswietlania',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: SegmentedButton<AppLanguage>(
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      ),
                    ),
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment<AppLanguage>(
                        value: AppLanguage.vietnamese,
                        label: Text('🇻🇳 VI'),
                      ),
                      ButtonSegment<AppLanguage>(
                        value: AppLanguage.english,
                        label: Text('🇺🇸 EN'),
                      ),
                      ButtonSegment<AppLanguage>(
                        value: AppLanguage.polish,
                        label: Text('🇵🇱 PL'),
                      ),
                    ],
                    selected: {widget.appController.language},
                    onSelectionChanged: (selection) {
                      final language = selection.first;
                      widget.appController.setLanguage(language);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _tileCard(
                child: SwitchListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  secondary: _tileIcon(
                    icon: widget.appController.themeMode == ThemeMode.dark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    background: widget.appController.themeMode == ThemeMode.dark
                        ? Colors.indigo.shade100
                        : Colors.orange.shade100,
                    foreground: widget.appController.themeMode == ThemeMode.dark
                        ? Colors.indigo.shade700
                        : Colors.orange.shade800,
                  ),
                  title: Text(
                    widget.appController.themeMode == ThemeMode.dark
                        ? _tr(
                            vi: 'Giao diện tối',
                            en: 'Dark Theme',
                            pl: 'Motyw ciemny',
                          )
                        : _tr(
                            vi: 'Giao diện sáng',
                            en: 'Light Theme',
                            pl: 'Motyw jasny',
                          ),
                  ),
                  subtitle: Text(
                    widget.appController.themeMode == ThemeMode.dark
                        ? _tr(
                            vi: 'Tối ưu cho môi trường thiếu sáng',
                            en: 'Optimized for low light',
                            pl: 'Zoptymalizowany do slabego oswietlenia',
                          )
                        : _tr(
                            vi: 'Giao diện sáng sủa, rõ ràng',
                            en: 'Clean and clear appearance',
                            pl: 'Jasny i przejrzysty wyglad',
                          ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  value: widget.appController.themeMode == ThemeMode.dark,
                  onChanged: (value) => widget.appController.setDarkMode(value),
                ),
              ),
              const SizedBox(height: 6),
              _tileCard(
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  leading: _tileIcon(
                    icon: Icons.ondemand_video_outlined,
                    background: scheme.tertiaryContainer,
                    foreground: scheme.onTertiaryContainer,
                  ),
                  title: Text(_tr(vi: 'Quảng cáo', en: 'Ads', pl: 'Reklamy')),
                  subtitle: Text(
                    adSubtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: widget.appController.areAdsTemporarilyDisabled
                      ? null
                      : ElevatedButton(
                          onPressed: _isLoadingRewardedAd
                              ? null
                              : _handleRewardAction,
                          child: Text(
                            _tr(
                              vi: 'Xem ngay',
                              en: 'Watch now',
                              pl: 'Obejrzyj teraz',
                            ),
                          ),
                        ),
                ),
              ),
              /* _tileCard(
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  leading: _tileIcon(
                    icon: Icons.notifications_outlined,
                    background: scheme.errorContainer,
                    foreground: scheme.onErrorContainer,
                  ),
                  title: Text(AppStrings.notifications(isEnglish)),
                  subtitle: Text(
                    AppStrings.notificationsDesc(isEnglish),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: 6), */
              const SizedBox(height: 6),
              _tileCard(
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SavedTipsPage(
                          appController: widget.appController,
                          isEnglish: isEnglish,
                        ),
                      ),
                    );
                  },
                  leading: _tileIcon(
                    icon: Icons.bookmark_outline,
                    background: Colors.orange.shade100,
                    foreground: Colors.orange.shade700,
                  ),
                  title: Text(_tr(vi: 'Đã lưu', en: 'Saved', pl: 'Zapisane')),
                  subtitle: Text(
                    _tr(
                      vi: 'Xem lại các mẹo sinh tồn bạn đã lưu',
                      en: 'View your bookmarked survival tips',
                      pl: 'Zobacz zapisane porady survivalowe',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                ),
              ),
              const SizedBox(height: 6),
              _tileCard(
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  onTap: () {
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
                  leading: _tileIcon(
                    icon: Icons.history_edu_outlined,
                    background: Colors.blue.shade100,
                    foreground: Colors.blue.shade700,
                  ),
                  title: Text(
                    _tr(
                      vi: 'Bài viết của bạn',
                      en: 'My Shared Posts',
                      pl: 'Twoje udostepnione posty',
                    ),
                  ),
                  subtitle: Text(
                    _tr(
                      vi: 'Theo dõi trạng thái các bài đóng góp của bạn',
                      en: 'Check status of your shared survival tips',
                      pl: 'Sprawdz status udostepnionych porad survivalowych',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  _tr(vi: 'SAO LƯU ĐỊNH DANH', en: 'IDENTITY BACKUP', pl: 'KOPIA ZAPASOWA'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 4),
              _tileCard(
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.appController.userId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_tr(vi: 'Đã sao chép mã định danh', en: 'ID copied to clipboard', pl: 'ID skopiowane'))),
                    );
                  },
                  leading: _tileIcon(
                    icon: Icons.copy_rounded,
                    background: Colors.indigo.shade100,
                    foreground: Colors.indigo.shade700,
                  ),
                  title: Text(_tr(vi: 'Mã định danh của bạn', en: 'Your Identity Code', pl: 'Twój kod tożsamości')),
                  subtitle: Text(
                    widget.appController.userId,
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.content_copy, size: 18, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 6),
              _tileCard(
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  onTap: () => _showImportIdDialog(context),
                  leading: _tileIcon(
                    icon: Icons.restore_rounded,
                    background: Colors.purple.shade100,
                    foreground: Colors.purple.shade700,
                  ),
                  title: Text(_tr(vi: 'Nhập mã định danh cũ', en: 'Import Existing ID', pl: 'Importuj istniejące ID')),
                  subtitle: Text(
                    _tr(
                      vi: 'Khôi phục bài đăng và lịch sử từ mã có sẵn',
                      en: 'Restore posts and history from a code',
                      pl: 'Przywróć posty i historię z kodu',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 6),
              _tileCard(
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(_tr(vi: 'Chính sách bảo mật', en: 'Privacy Policy', pl: 'Polityka prywatności')),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _tr(
                                  vi: 'Chúng tôi cam kết bảo vệ dữ liệu của bạn. Ứng dụng thu thập ID thiết bị và vị trí để cung cấp dịch vụ tốt nhất. Chúng tôi không chia sẻ thông tin này cho mục đích quảng cáo từ bên thứ ba bên ngoài hệ thống của mình.',
                                  en: 'We are committed to protecting your data. The app collects Device ID and Location to provide the best service. We do not share this information with third parties for external advertising purposes.',
                                  pl: 'Dbamy o Twoje dane. Aplikacja zbiera ID urządzenia i lokalizację. Nie udostępniamy tych informacji osobom trzecim.',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _tr(
                                  vi: 'Lưu ý: Thông tin trong ứng dụng chỉ mang tính chất tham khảo. Luôn liên hệ cơ quan chuyên môn trong tình huống khẩn cấp thực tế.',
                                  en: 'Disclaimer: The information in this app is for reference only. Always contact professionals in real emergencies.',
                                  pl: 'Zastrzeżenie: Informacje w tej aplikacji służą wyłącznie do celów informacyjnych. W sytuacjach awaryjnych zawsze kontaktuj się ze specjalistami.',
                                ),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(_tr(vi: 'Đóng', en: 'Close', pl: 'Zamknij')),
                          ),
                        ],
                      ),
                    );
                  },
                  leading: _tileIcon(
                    icon: Icons.privacy_tip_outlined,
                    background: Colors.teal.shade100,
                    foreground: Colors.teal.shade700,
                  ),
                  title: Text(_tr(vi: 'Chính sách bảo mật', en: 'Privacy Policy', pl: 'Polityka prywatności')),
                  subtitle: Text(
                    _tr(
                      vi: 'Xem cách chúng tôi bảo vệ quyền riêng tư của bạn',
                      en: 'Learn how we protect your privacy',
                      pl: 'Dowiedz się, jak chronimy Twoją prywatność',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                ),
              ),
              const SizedBox(height: 6),
              _tileCard(
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(_tr(vi: 'Xóa dữ liệu cá nhân?', en: 'Delete My Data?', pl: 'Usunąć moje dane?')),
                        content: Text(_tr(
                          vi: 'Hành động này sẽ xóa ID định danh, các bài viết đã lưu và lịch sử hoạt động của bạn trên thiết bị này. Bạn không thể hoàn tác.',
                          en: 'This will delete your identity ID, saved posts, and activity history on this device. This action cannot be undone.',
                          pl: 'To spowoduje usunięcie Twojego ID, zapisanych postów i historii aktywności na tym urządzeniu. Nie można tego cofnąć.',
                        )),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(_tr(vi: 'Hủy', en: 'Cancel', pl: 'Anuluj')),
                          ),
                          TextButton(
                            onPressed: () async {
                              await widget.appController.deleteAccount();
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(_tr(vi: 'Đã xóa toàn bộ dữ liệu', en: 'All data deleted', pl: 'Wszystkie dane usunięte'))),
                                );
                              }
                            },
                            child: Text(_tr(vi: 'Xóa sạch', en: 'Clear All', pl: 'Usuń wszystko'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                  leading: _tileIcon(
                    icon: Icons.delete_outline,
                    background: Colors.red.shade100,
                    foreground: Colors.red.shade700,
                  ),
                  title: Text(_tr(vi: 'Xóa dữ liệu & Định danh', en: 'Delete Data & Identity', pl: 'Usuń dane i tożsamość')),
                  subtitle: Text(
                    _tr(
                      vi: 'Gỡ bỏ toàn bộ dấu vết của bạn khỏi ứng dụng',
                      en: 'Remove all your traces from the app',
                      pl: 'Usuń wszystkie swoje ślady z aplikacji',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showImportIdDialog(BuildContext context) {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr(vi: 'Nhập mã định danh', en: 'Import ID', pl: 'Importuj ID')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_tr(
              vi: 'Dán mã định danh cũ của bạn vào đây để khôi phục dữ liệu.',
              en: 'Paste your old identity code here to restore data.',
              pl: 'Wklej swój stary kod tożsamości tutaj.',
            )),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'VD: 17144123456789',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_tr(vi: 'Hủy', en: 'Cancel', pl: 'Anuluj')),
          ),
          ElevatedButton(
            onPressed: () async {
              final newId = _controller.text.trim();
              if (newId.isNotEmpty && newId.length >= 10) {
                await widget.appController.restoreIdentity(newId);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_tr(vi: 'Đã khôi phục định danh thành công', en: 'Identity restored successfully', pl: 'Przywrócono tożsamość'))),
                );
              }
            },
            child: Text(_tr(vi: 'Khôi phục', en: 'Restore', pl: 'Przywróć')),
          ),
        ],
      ),
    );
  }
}

class ReferenceHeroBanner extends StatelessWidget {
  const ReferenceHeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.height = 148,
  });

  final String title;
  final String subtitle;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: height,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
