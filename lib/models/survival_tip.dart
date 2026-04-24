import 'package:meo_sinhton/app/app_i18n.dart';
import 'package:meo_sinhton/app/app_controller.dart';

class SurvivalTip {
  const SurvivalTip({
    required this.id,
    required this.title,
    required this.category,
    required this.subCategory,
    required this.difficulty,
    required this.tags,
    required this.summary,
    required this.steps,
    required this.estimatedMinutes,
    required this.isEmergency,
    this.titleEn,
    this.categoryEn,
    this.subCategoryEn,
    this.difficultyEn,
    this.summaryEn,
    this.stepsEn,
    this.tagsEn,
    this.titlePl,
    this.categoryPl,
    this.subCategoryPl,
    this.difficultyPl,
    this.summaryPl,
    this.stepsPl,
    this.tagsPl,
    this.imageAsset,
  });

  final String id;
  final String title;
  final String category;
  final String subCategory;
  final String difficulty;
  final List<String> tags;
  final String summary;
  final List<String> steps;
  final int estimatedMinutes;
  final bool isEmergency;
  final String? titleEn;
  final String? categoryEn;
  final String? subCategoryEn;
  final String? difficultyEn;
  final String? summaryEn;
  final List<String>? stepsEn;
  final List<String>? tagsEn;
  final String? titlePl;
  final String? categoryPl;
  final String? subCategoryPl;
  final String? difficultyPl;
  final String? summaryPl;
  final List<String>? stepsPl;
  final List<String>? tagsPl;
  final String? imageAsset;

  factory SurvivalTip.fromJson(Map<String, dynamic> json) {
    return SurvivalTip(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'Khác',
      subCategory: json['subCategory'] as String? ?? 'Chung',
      difficulty: json['difficulty'] as String? ?? 'Cơ bản',
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((tag) => tag.toString())
          .toList(),
      summary: json['summary'] as String? ?? '',
      steps: (json['steps'] as List<dynamic>? ?? const [])
          .map((step) => step.toString())
          .toList(),
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 5,
      isEmergency: json['isEmergency'] as bool? ?? false,
      titleEn: json['titleEn'] as String?,
      categoryEn: json['categoryEn'] as String?,
      subCategoryEn: json['subCategoryEn'] as String?,
      difficultyEn: json['difficultyEn'] as String?,
      summaryEn: json['summaryEn'] as String?,
      stepsEn: (json['stepsEn'] as List<dynamic>?)
          ?.map((step) => step.toString())
          .toList(),
      tagsEn: (json['tagsEn'] as List<dynamic>?)
          ?.map((tag) => tag.toString())
          .toList(),
      titlePl: json['titlePl'] as String?,
      categoryPl: json['categoryPl'] as String?,
      subCategoryPl: json['subCategoryPl'] as String?,
      difficultyPl: json['difficultyPl'] as String?,
      summaryPl: json['summaryPl'] as String?,
      stepsPl: (json['stepsPl'] as List<dynamic>?)
          ?.map((step) => step.toString())
          .toList(),
      tagsPl: (json['tagsPl'] as List<dynamic>?)
          ?.map((tag) => tag.toString())
          .toList(),
      imageAsset: json['imageAsset'] as String?,
    );
  }

  String titleText(AppLanguage language) {
    final en = titleEn?.trim() ?? '';
    final pl = titlePl?.trim() ?? '';
    switch (language) {
      case AppLanguage.english:
        return en.isNotEmpty ? en : title;
      case AppLanguage.polish:
        return pl.isNotEmpty ? pl : (en.isNotEmpty ? en : title);
      case AppLanguage.vietnamese:
      default:
        return title;
    }
  }

  String summaryText(AppLanguage language) {
    final en = summaryEn?.trim() ?? '';
    final pl = summaryPl?.trim() ?? '';
    switch (language) {
      case AppLanguage.english:
        return en.isNotEmpty ? en : summary;
      case AppLanguage.polish:
        return pl.isNotEmpty ? pl : (en.isNotEmpty ? en : summary);
      case AppLanguage.vietnamese:
      default:
        return summary;
    }
  }

  String categoryText(AppLanguage language) {
    final en = categoryEn?.trim() ?? '';
    final pl = categoryPl?.trim() ?? '';
    switch (language) {
      case AppLanguage.english:
        return en.isNotEmpty ? en : AppI18n.category(category, true);
      case AppLanguage.polish:
        return pl.isNotEmpty
            ? pl
            : (en.isNotEmpty ? en : AppI18n.category(category, false));
      case AppLanguage.vietnamese:
      default:
        return AppI18n.category(category, false);
    }
  }

  String subCategoryText(AppLanguage language) {
    final en = subCategoryEn?.trim() ?? '';
    final pl = subCategoryPl?.trim() ?? '';
    switch (language) {
      case AppLanguage.english:
        return en.isNotEmpty ? en : subCategory;
      case AppLanguage.polish:
        return pl.isNotEmpty ? pl : (en.isNotEmpty ? en : subCategory);
      case AppLanguage.vietnamese:
      default:
        return subCategory;
    }
  }

  String difficultyText(AppLanguage language) {
    final en = difficultyEn?.trim() ?? '';
    final pl = difficultyPl?.trim() ?? '';
    switch (language) {
      case AppLanguage.english:
        return en.isNotEmpty ? en : AppI18n.difficulty(difficulty, true);
      case AppLanguage.polish:
        return pl.isNotEmpty
            ? pl
            : (en.isNotEmpty ? en : AppI18n.difficulty(difficulty, false));
      case AppLanguage.vietnamese:
      default:
        return AppI18n.difficulty(difficulty, false);
    }
  }

  List<String> stepsText(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        if (stepsEn != null && stepsEn!.isNotEmpty) return stepsEn!;
        return steps;
      case AppLanguage.polish:
        if (stepsPl != null && stepsPl!.isNotEmpty) return stepsPl!;
        if (stepsEn != null && stepsEn!.isNotEmpty) return stepsEn!;
        return steps;
      case AppLanguage.vietnamese:
      default:
        return steps;
    }
  }

  List<String> tagsText(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        if (tagsEn != null && tagsEn!.isNotEmpty) return tagsEn!;
        return tags.map((tag) => AppI18n.tag(tag, true)).toList();
      case AppLanguage.polish:
        if (tagsPl != null && tagsPl!.isNotEmpty) return tagsPl!;
        if (tagsEn != null && tagsEn!.isNotEmpty) return tagsEn!;
        return tags
            .map((tag) => AppI18n.tag(tag, false, isPolish: true))
            .toList();
      case AppLanguage.vietnamese:
      default:
        return tags.map((tag) => AppI18n.tag(tag, false)).toList();
    }
  }
}
