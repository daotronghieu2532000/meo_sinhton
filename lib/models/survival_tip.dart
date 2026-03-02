import 'package:meo_sinhton/app/app_i18n.dart';

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
      imageAsset: json['imageAsset'] as String?,
    );
  }

  String titleText(bool isEnglish) {
    final en = titleEn?.trim() ?? '';
    return isEnglish && en.isNotEmpty ? en : title;
  }

  String summaryText(bool isEnglish) {
    final en = summaryEn?.trim() ?? '';
    return isEnglish && en.isNotEmpty ? en : summary;
  }

  String categoryText(bool isEnglish) {
    final en = categoryEn?.trim() ?? '';
    if (isEnglish && en.isNotEmpty) {
      return en;
    }
    return AppI18n.category(category, isEnglish);
  }

  String subCategoryText(bool isEnglish) {
    final en = subCategoryEn?.trim() ?? '';
    return isEnglish && en.isNotEmpty ? en : subCategory;
  }

  String difficultyText(bool isEnglish) {
    final en = difficultyEn?.trim() ?? '';
    if (isEnglish && en.isNotEmpty) {
      return en;
    }
    return AppI18n.difficulty(difficulty, isEnglish);
  }

  List<String> stepsText(bool isEnglish) {
    if (isEnglish && stepsEn != null && stepsEn!.isNotEmpty) {
      return stepsEn!;
    }
    return steps;
  }

  List<String> tagsText(bool isEnglish) {
    if (isEnglish && tagsEn != null && tagsEn!.isNotEmpty) {
      return tagsEn!;
    }
    return tags.map((tag) => AppI18n.tag(tag, isEnglish)).toList();
  }
}
