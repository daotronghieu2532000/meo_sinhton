import 'package:meo_sinhton/app/app_i18n.dart';
import 'package:meo_sinhton/app/app_controller.dart';

class AppStrings {
  static String appName() => 'MXH : Share Tips and Tricks';

  static String tabHome(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Trang chủ', en: 'Home');
  static String tabEmergency(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Khẩn cấp', en: 'Emergency');
  static String tabCommunity(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Góp ý', en: 'Community');
  static String tabCategories(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Danh mục', en: 'Categories');
  static String tabScenario(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Tình huống', en: 'Scenarios');
  static String tabMap(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Bản đồ', en: 'Map');
  static String tabTop10(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Top 10', en: 'Top 10');
  static String tabSaved(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Đã lưu', en: 'Saved');
  static String settings(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Cài đặt', en: 'Settings');

  static String feedHeadline(bool isEnglish, {required bool emergencyOnly}) {
    return emergencyOnly
        ? AppI18n.text(
            isEnglish: isEnglish,
            vi: 'Mẹo ưu tiên cho tình huống khẩn cấp',
            en: 'Priority tips for emergency situations',
          )
        : AppI18n.text(
            isEnglish: isEnglish,
            vi: 'Khám phá mẹo hữu ích mỗi ngày',
            en: 'Discover useful tips for daily life',
          );
  }

  static String searchHint(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Tìm mẹo theo từ khóa...',
    en: 'Search tips by keyword...',
  );

  static String offlineDataError(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Không đọc được dữ liệu offline. Vui lòng kiểm tra JSON.',
    en: 'Unable to load offline data. Please check JSON.',
  );

  static String noMatchingTips(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Không tìm thấy mẹo phù hợp.',
    en: 'No matching tips found.',
  );

  static String minuteUnit(
    AppLanguage language,
    int minutes, {
    bool compact = false,
  }) {
    switch (language) {
      case AppLanguage.english:
        return compact ? '$minutes min' : '~$minutes min';
      case AppLanguage.polish:
        // Đơn giản: số 1 là minuta, còn lại là min
        if (minutes == 1) {
          return compact ? '1 minuta' : '~1 minuta';
        }
        return compact ? '$minutes min' : '~$minutes min';
      case AppLanguage.vietnamese:
      default:
        return compact ? '$minutes phút' : '~$minutes phút';
    }
  }

  static String emergencyChip(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return 'Emergency';
      case AppLanguage.polish:
        return 'Awaryjne';
      case AppLanguage.vietnamese:
      default:
        return 'Khẩn cấp';
    }
  }

  static String categoryLoadError(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Không tải được danh mục.',
    en: 'Unable to load categories.',
  );

  static String noCategories(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Chưa có danh mục.',
    en: 'No categories yet.',
  );

  static String categoryTipCount(bool isEnglish, int count) =>
      isEnglish ? '$count tips' : '$count mẹo';

  static String noSavedTips(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Chưa có mẹo đã lưu',
    en: 'No saved tips yet',
  );

  static String saveTip(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Lưu mẹo', en: 'Save tip');

  static String unsaveTip(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Bỏ lưu mẹo', en: 'Unsave tip');

  static String tipSaved(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Đã lưu mẹo', en: 'Tip saved');

  static String tipUnsaved(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Đã bỏ lưu mẹo',
    en: 'Tip removed from saved',
  );

  static String savedPlaceholderDesc(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Lưu mẹo để xem lại nhanh ở đây.',
    en: 'Save tips to quickly review them here.',
  );

  static String language(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Ngôn ngữ', en: 'Language');

  static String languageDesc(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Chọn ngôn ngữ hiển thị',
    en: 'Select display language',
  );

  static String darkMode(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Chế độ tối', en: 'Dark mode');

  static String darkModeDesc(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Bật để hiển thị giao diện tối',
    en: 'Turn on for dark appearance',
  );

  static String notifications(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Thông báo', en: 'Notifications');

  static String notificationsDesc(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Sẽ cập nhật ở bản sau',
    en: 'Coming in a later version',
  );

  static String about(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Về ứng dụng', en: 'About app');

  static String aboutDesc(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'LifeSpark: Survival and Life Hacks • Bản thử nghiệm',
    en: 'LifeSpark: Survival and Life Hacks • Preview build',
  );

  static String ads(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Quảng cáo', en: 'Ads');

  static String watchRewardToDisableAds(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Xem quảng cáo thưởng để tắt toàn bộ quảng cáo trong 1 giờ.',
    en: 'Watch a rewarded ad to disable all ads for 1 hour.',
  );

  static String adsDisabledRemaining(bool isEnglish, Duration remaining) {
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    if (isEnglish) {
      return 'Ads are disabled for ${hours}h ${minutes}m';
    }
    return 'Đã tắt quảng cáo còn ${hours} giờ ${minutes} phút';
  }

  static String watchNow(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Xem ngay', en: 'Watch now');

  static String loadingRewardAd(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Đang tải quảng cáo thưởng...',
    en: 'Loading rewarded ad...',
  );

  static String rewardGranted(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Bạn đã tắt quảng cáo trong 1 giờ.',
    en: 'Ads are disabled for 1 hour.',
  );

  static String rewardNotCompleted(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Bạn cần xem hết quảng cáo để nhận thưởng.',
    en: 'Please finish the ad to receive the reward.',
  );

  static String adsNotSupported(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Thiết bị hiện tại không hỗ trợ quảng cáo AdMob.',
    en: 'AdMob is not supported on this device.',
  );

  static String rewardedLoadFailed(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Không tải được quảng cáo thưởng. Vui lòng thử lại.',
    en: 'Unable to load rewarded ad. Please try again.',
  );

  static String detailsHeader(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return 'Detailed steps';
      case AppLanguage.polish:
        return 'Szczegółowa instrukcja';
      case AppLanguage.vietnamese:
      default:
        return 'Hướng dẫn chi tiết';
    }
  }

  static String imagePlaceholder(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Ảnh minh họa sẽ cập nhật sau',
    en: 'Illustration image will be updated soon',
  );

  static String splashImageNotFound(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Không tìm thấy ảnh splash',
    en: 'Splash image not found',
  );

  static String scenarioHeadline(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Luyện phản xạ qua các tình huống thực tế',
    en: 'Practice quick decisions with real-life scenarios',
  );

  static String scenarioStart(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Bắt đầu', en: 'Start');

  static String scenarioContinue(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Tiếp tục', en: 'Continue');

  static String scenarioViewResult(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Xem kết quả', en: 'View result');

  static String scenarioPlayAgain(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Chơi lại', en: 'Play again');

  static String scenarioNoData(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Chưa có tình huống nào.',
    en: 'No scenarios available yet.',
  );

  static String scenarioLoadError(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Không tải được dữ liệu tình huống offline.',
    en: 'Unable to load offline scenario data.',
  );

  static String scenarioStepProgress(bool isEnglish, int current, int total) {
    if (isEnglish) {
      return 'Step $current/$total';
    }
    return 'Bước $current/$total';
  }

  static String scenarioCorrect(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Chính xác', en: 'Correct');

  static String scenarioIncorrect(bool isEnglish) =>
      AppI18n.text(isEnglish: isEnglish, vi: 'Chưa đúng', en: 'Not correct');

  static String scenarioScore(bool isEnglish, int score, int total) {
    if (isEnglish) {
      return 'Score: $score/$total';
    }
    return 'Điểm: $score/$total';
  }

  static String scenarioResultTitle(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Kết quả tình huống',
    en: 'Scenario result',
  );

  static String scenarioResultGreat(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Rất tốt! Bạn xử lý tình huống khá chính xác.',
    en: 'Great job! Your decisions are highly accurate.',
  );

  static String scenarioResultGood(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Ổn rồi! Tiếp tục luyện thêm để phản xạ tốt hơn.',
    en: 'Nice work! Keep practicing to improve your reaction.',
  );

  static String scenarioResultRetry(bool isEnglish) => AppI18n.text(
    isEnglish: isEnglish,
    vi: 'Thử lại nhé! Đọc kỹ giải thích để cải thiện nhanh.',
    en: 'Try again! Review explanations to improve quickly.',
  );
}
