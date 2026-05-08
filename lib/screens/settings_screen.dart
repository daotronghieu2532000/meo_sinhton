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

  final String _appStoreUrl = 'https://apps.apple.com/vn/app/lifespark-survival-tools/id6763969565?l=vi';

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
        ? 'ca-app-pub-3940256099942544/1712485313' 
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
        },
        onAdFailedToLoad: (error) {
          if (!mounted) return;
          setState(() {
            _rewardedAd = null;
            _adLoadAttempts++;
          });
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
      case AppLanguage.english: return en;
      case AppLanguage.polish: return pl;
      case AppLanguage.vietnamese: return vi;
    }
  }

  bool get _adsSupported {
    if (kIsWeb || (const bool.fromEnvironment('FLUTTER_TEST'))) return false;
    return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<bool> _showRewardedAd() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_tr(
            vi: 'Không có kết nối Internet.',
            en: 'No internet connection.',
            pl: 'Brak połączenia z Internetem.',
          )), backgroundColor: Colors.red),
        );
      }
      return false;
    }

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
          SnackBar(content: Text(_tr(
            vi: 'Đang chuẩn bị quảng cáo, vui lòng đợi...',
            en: 'Preparing ad, please wait...',
            pl: 'Przygotowywanie reklamy...',
          ))),
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
        if (!completer.isCompleted) completer.complete(earnedReward);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    await _rewardedAd!.show(onUserEarnedReward: (_, __) => earnedReward = true);
    return completer.future;
  }

  Future<void> _handleRewardAction(Duration duration) async {
    if (!_adsSupported) return;
    if (widget.appController.areAdsTemporarilyDisabled) return;
    if (_isLoadingRewardedAd) return;

    setState(() => _isLoadingRewardedAd = true);
    final earned = await _showRewardedAd();
    if (!mounted) return;
    setState(() => _isLoadingRewardedAd = false);

    if (earned) {
      await widget.appController.grantAdFree(duration);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr(
          vi: 'Đã tắt quảng cáo trong ${duration.inMinutes} phút.',
          en: 'Ads disabled for ${duration.inMinutes} minutes.',
          pl: 'Reklamy wyłączone na ${duration.inMinutes} minut.',
        ))),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appController,
      builder: (context, _) {
        final isDark = widget.appController.themeMode == ThemeMode.dark;
        final scheme = Theme.of(context).colorScheme;
        final adRemaining = widget.appController.adFreeRemaining;
        
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.transparent,
            title: Text(
              _tr(vi: 'Cài đặt hệ thống', en: 'System Settings', pl: 'Ustawienia'),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildAdSection(adRemaining, isDark),
              const SizedBox(height: 16),
              _buildActionRow(),
              const SizedBox(height: 24),
              _buildSectionHeader(_tr(vi: 'CÁ NHÂN HÓA', en: 'PERSONALIZATION', pl: 'PERSONALIZACJA')),
              _buildSettingCard([
                _buildLanguageTile(scheme),
                _buildDivider(),
                _buildThemeTile(isDark),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(_tr(vi: 'TIỆN ÍCH & NỘI DUNG', en: 'UTILS & CONTENT', pl: 'TREŚĆ')),
              _buildSettingCard([
                _buildNavigationTile(
                  icon: Icons.bookmark_rounded,
                  color: Colors.orange,
                  title: _tr(vi: 'Mẹo đã lưu', en: 'Saved Tips', pl: 'Zapisane'),
                  subtitle: _tr(vi: 'Kho lưu trữ mẹo sinh tồn của bạn', en: 'Your survival library', pl: 'Twoja biblioteka'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SavedTipsPage(appController: widget.appController, isEnglish: widget.appController.isEnglish))),
                ),
                _buildDivider(),
                _buildNavigationTile(
                  icon: Icons.edit_document,
                  color: Colors.blue,
                  title: _tr(vi: 'Bài viết của tôi', en: 'My Posts', pl: 'Moje posty'),
                  subtitle: _tr(vi: 'Quản lý các bài đóng góp cộng đồng', en: 'Manage your contributions', pl: 'Zarządzaj postami'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MyPostsPage(appController: widget.appController, isEnglish: widget.appController.isEnglish))),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(_tr(vi: 'SAO LƯU & BẢO MẬT', en: 'BACKUP & SECURITY', pl: 'BEZPIECZEŃSTWO')),
              _buildSettingCard([
                _buildIdentityTile(isDark),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.restore_rounded,
                  color: Colors.purple,
                  title: _tr(vi: 'Khôi phục định danh', en: 'Restore Identity', pl: 'Przywróć ID'),
                  onTap: () => _showImportIdDialog(context),
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.privacy_tip_rounded,
                  color: Colors.teal,
                  title: _tr(vi: 'Chính sách bảo mật', en: 'Privacy Policy', pl: 'Polityka prywatności'),
                  onTap: () => _showPrivacyDialog(context),
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.delete_forever_rounded,
                  color: Colors.red,
                  title: _tr(vi: 'Xóa dữ liệu tài khoản', en: 'Delete Account Data', pl: 'Usuń dane'),
                  isDestructive: true,
                  onTap: () => _showDeleteDataDialog(context),
                ),
              ]),
              const SizedBox(height: 40),
              _buildFooter(isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdSection(Duration? adRemaining, bool isDark) {
    final isDisabled = widget.appController.areAdsTemporarilyDisabled;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF1A237E), const Color(0xFF311B92)] 
            : [const Color(0xFFE3F2FD), const Color(0xFFF3E5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDark ? 0.1 : 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDisabled ? Icons.verified_user_rounded : Icons.ads_click_rounded,
                  color: isDisabled ? Colors.green : Colors.blueAccent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDisabled ? _tr(vi: 'Đã tắt quảng cáo', en: 'Ads Disabled', pl: 'Reklamy wyłączone') : _tr(vi: 'Gói miễn phí', en: 'Free Plan', pl: 'Plan darmowy'),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isDisabled 
                        ? _tr(
                            vi: 'Còn lại: ${adRemaining?.inHours}h ${adRemaining?.inMinutes.remainder(60)}m',
                            en: 'Remaining: ${adRemaining?.inHours}h ${adRemaining?.inMinutes.remainder(60)}m',
                            pl: 'Pozostało: ${adRemaining?.inHours}h ${adRemaining?.inMinutes.remainder(60)}m',
                          )
                        : _tr(vi: 'Xem quảng cáo để ủng hộ tác giả', en: 'Watch ads to support us', pl: 'Wesprzyj nas'),
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildAdButton(
                  label: _tr(vi: 'Tắt 30 phút', en: 'Off 30m', pl: 'Wyłącz 30m'),
                  icon: Icons.timer_outlined,
                  onTap: () => _handleRewardAction(const Duration(minutes: 30)),
                  isDark: isDark,
                  primaryColor: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAdButton(
                  label: _tr(vi: 'Tắt 2 giờ', en: 'Off 2h', pl: 'Wyłącz 2h'),
                  icon: Icons.bolt_rounded,
                  onTap: () => _handleRewardAction(const Duration(hours: 2)),
                  isDark: isDark,
                  primaryColor: Colors.deepPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoadingRewardedAd ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryColor.withOpacity(0.3)),
            color: primaryColor.withOpacity(isDark ? 0.2 : 0.1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSmallActionButton(
            label: _tr(vi: 'Đánh giá App', en: 'Rate App', pl: 'Oceń'),
            icon: Icons.star_rounded,
            color: Colors.amber.shade700,
            onTap: () => _launchUrl(_appStoreUrl),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSmallActionButton(
            label: _tr(vi: 'Cập nhật', en: 'Check Updates', pl: 'Aktualizuj'),
            icon: Icons.system_update_rounded,
            color: Colors.blue.shade700,
            onTap: () => _launchUrl(_appStoreUrl),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildLanguageTile(ColorScheme scheme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: _tileIcon(Icons.translate_rounded, Colors.blue.shade50, Colors.blue.shade700),
      title: Text(_tr(vi: 'Ngôn ngữ', en: 'Language', pl: 'Język'), style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: SegmentedButton<AppLanguage>(
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: const [
          ButtonSegment(value: AppLanguage.vietnamese, label: Text('VI')),
          ButtonSegment(value: AppLanguage.english, label: Text('EN')),
          ButtonSegment(value: AppLanguage.polish, label: Text('PL')),
        ],
        selected: {widget.appController.language},
        onSelectionChanged: (selection) => widget.appController.setLanguage(selection.first),
        showSelectedIcon: false,
      ),
    );
  }

  Widget _buildThemeTile(bool isDark) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      secondary: _tileIcon(
        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
        isDark ? Colors.indigo.shade50 : Colors.orange.shade50,
        isDark ? Colors.indigo.shade700 : Colors.orange.shade800,
      ),
      title: Text(
        isDark ? _tr(vi: 'Giao diện tối', en: 'Dark Mode', pl: 'Ciemny') : _tr(vi: 'Giao diện sáng', en: 'Light Mode', pl: 'Jasny'),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      value: isDark,
      onChanged: (v) => widget.appController.setDarkMode(v),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: _tileIcon(icon, color.withOpacity(0.1), color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: _tileIcon(icon, color.withOpacity(0.1), color),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : null,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
    );
  }

  Widget _buildIdentityTile(bool isDark) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: _tileIcon(Icons.fingerprint_rounded, Colors.indigo.shade50, Colors.indigo.shade700),
      title: Text(_tr(vi: 'ID của bạn', en: 'Your ID', pl: 'Twój ID'), style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(widget.appController.userId, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold)),
      trailing: IconButton(
        icon: const Icon(Icons.copy_all_rounded, size: 20),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: widget.appController.userId));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_tr(vi: 'Đã sao chép', en: 'Copied', pl: 'Skopiowano'))));
        },
      ),
    );
  }

  Widget _tileIcon(IconData icon, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: fg, size: 20),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 64, endIndent: 20, thickness: 0.5);

  Widget _buildFooter(bool isDark) {
    return Column(
      children: [
        Text(
          'LifeSpark Survival Guide',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: isDark ? Colors.white30 : Colors.black12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'v${AppStrings.appVersion}',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
        ),
      ],
    );
  }

  void _showImportIdDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr(vi: 'Nhập mã định danh', en: 'Import ID', pl: 'Importuj ID')),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '1777...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_tr(vi: 'Hủy', en: 'Cancel', pl: 'Anuluj'))),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                widget.appController.restoreIdentity(controller.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_tr(vi: 'Đã khôi phục', en: 'Restored', pl: 'Przywrócono'))));
              }
            },
            child: Text(_tr(vi: 'Khôi phục', en: 'Restore', pl: 'Przywróć')),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr(vi: 'Chính sách bảo mật', en: 'Privacy Policy', pl: 'Polityka')),
        content: Text(_tr(
          vi: 'Chúng tôi cam kết bảo vệ dữ liệu của bạn...',
          en: 'We are committed to protecting your data...',
          pl: 'Dbamy o Twoje dane...',
        )),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_tr(vi: 'Đóng', en: 'Close', pl: 'Zamknij')))],
      ),
    );
  }

  void _showDeleteDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr(vi: 'Xóa toàn bộ dữ liệu?', en: 'Delete All Data?', pl: 'Usuń dane?')),
        content: Text(_tr(vi: 'Hành động này không thể hoàn tác.', en: 'This cannot be undone.', pl: 'Nie można cofnąć.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_tr(vi: 'Hủy', en: 'Cancel', pl: 'Anuluj'))),
          TextButton(
            onPressed: () {
              widget.appController.deleteAccount();
              Navigator.pop(ctx);
            },
            child: Text(_tr(vi: 'Xóa sạch', en: 'Delete', pl: 'Usuń'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
