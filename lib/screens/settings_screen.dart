import 'package:flutter/material.dart';
import 'package:meo_sinhton/app/app_controller.dart';
import 'package:meo_sinhton/app/app_strings.dart';
import 'package:meo_sinhton/app/admob_config.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
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
    final completer = Completer<bool>();
    bool earnedReward = false;

    await RewardedAd.load(
      adUnitId: AdmobConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) {
                completer.complete(earnedReward);
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!completer.isCompleted) {
                completer.complete(false);
              }
            },
          );

          ad.show(
            onUserEarnedReward: (_, __) {
              earnedReward = true;
            },
          );
        },
        onAdFailedToLoad: (_) {
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      ),
    );

    return completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () => false,
    );
  }

  Future<void> _handleRewardAction() async {
    final isEnglish = widget.appController.isEnglish;

    if (!_adsSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.adsNotSupported(isEnglish))),
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
      SnackBar(content: Text(AppStrings.loadingRewardAd(isEnglish))),
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
        SnackBar(content: Text(AppStrings.rewardGranted(isEnglish))),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.rewardNotCompleted(isEnglish))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appController,
      builder: (context, _) {
        final isEnglish = widget.appController.isEnglish;
        final adRemaining = widget.appController.adFreeRemaining;
        final scheme = Theme.of(context).colorScheme;
        final adSubtitle = widget.appController.areAdsTemporarilyDisabled
            ? AppStrings.adsDisabledRemaining(
                isEnglish,
                adRemaining ?? Duration.zero,
              )
            : AppStrings.watchRewardToDisableAds(isEnglish);

        return Scaffold(
          appBar: AppBar(title: Text(AppStrings.settings(isEnglish))),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
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
                  title: Text(AppStrings.language(isEnglish)),
                  subtitle: Text(
                    AppStrings.languageDesc(isEnglish),
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
                        label: Text('VI'),
                      ),
                      ButtonSegment<AppLanguage>(
                        value: AppLanguage.english,
                        label: Text('EN'),
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
                    icon: Icons.dark_mode_outlined,
                    background: scheme.secondaryContainer,
                    foreground: scheme.onSecondaryContainer,
                  ),
                  title: Text(AppStrings.darkMode(isEnglish)),
                  subtitle: Text(
                    AppStrings.darkModeDesc(isEnglish),
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
                  title: Text(AppStrings.ads(isEnglish)),
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
                          child: Text(AppStrings.watchNow(isEnglish)),
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
                    icon: Icons.info_outline,
                    background: scheme.surfaceContainerHighest,
                    foreground: scheme.onSurfaceVariant,
                  ),
                  title: Text(AppStrings.about(isEnglish)),
                  subtitle: Text(
                    AppStrings.aboutDesc(isEnglish),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
