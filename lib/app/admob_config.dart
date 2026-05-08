import 'package:flutter/foundation.dart';
import 'dart:io';

class AdmobConfig {
  // App AdMob Application ID
  static const String appId = 'ca-app-pub-6241798695005922~9337017310';

  // Production IDs
  static const String _prodBannerId = 'ca-app-pub-6241798695005922/1610885166';
  static const String _prodInterstitialId = 'ca-app-pub-6241798695005922/9297803493';
  static const String _prodRewardedId = 'ca-app-pub-6241798695005922/8786578311';

  // Test IDs (Standard Google Test IDs for iOS)
  static const String _testBannerId = 'ca-app-pub-3940256099942544/2934735716';
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/4411468910';
  static const String _testRewardedId = 'ca-app-pub-3940256099942544/1712485313';

  static String get bannerBottomAdUnitId {
    if (kDebugMode) return _testBannerId;
    return _prodBannerId;
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) return _testInterstitialId;
    return _prodInterstitialId;
  }

  static String get rewardedAdUnitId {
    if (kDebugMode) return _testRewardedId;
    return _prodRewardedId;
  }
}
