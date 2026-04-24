import 'package:meo_sinhton/app/app_controller.dart';

class ScenarioItem {
  const ScenarioItem({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.steps,
    this.imageAsset,
    this.titleEn,
    this.titlePl,
    this.descriptionEn,
    this.descriptionPl,
    this.difficultyEn,
    this.difficultyPl,
  });

  final String id;
  final String title;
  final String description;
  final String difficulty;
  final int estimatedMinutes;
  final List<ScenarioStep> steps;
  final String? imageAsset;
  final String? titleEn;
  final String? titlePl;
  final String? descriptionEn;
  final String? descriptionPl;
  final String? difficultyEn;
  final String? difficultyPl;

  factory ScenarioItem.fromJson(Map<String, dynamic> json) {
    return ScenarioItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'Cơ bản',
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 3,
      steps: (json['steps'] as List<dynamic>? ?? const [])
          .map((item) => ScenarioStep.fromJson(item as Map<String, dynamic>))
          .toList(),
      imageAsset: json['imageAsset'] as String?,
      titleEn: json['titleEn'] as String?,
      titlePl: json['titlePl'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
      descriptionPl: json['descriptionPl'] as String?,
      difficultyEn: json['difficultyEn'] as String?,
      difficultyPl: json['difficultyPl'] as String?,
    );
  }

  String titleText(AppLanguage language) {
    if (language == AppLanguage.polish) {
      final pl = titlePl?.trim() ?? '';
      if (pl.isNotEmpty) {
        return pl;
      }
    }
    final en = titleEn?.trim() ?? '';
    return language != AppLanguage.vietnamese && en.isNotEmpty ? en : title;
  }

  String descriptionText(AppLanguage language) {
    if (language == AppLanguage.polish) {
      final pl = descriptionPl?.trim() ?? '';
      if (pl.isNotEmpty) {
        return pl;
      }
    }
    final en = descriptionEn?.trim() ?? '';
    return language != AppLanguage.vietnamese && en.isNotEmpty
        ? en
        : description;
  }

  String difficultyText(AppLanguage language) {
    if (language == AppLanguage.polish) {
      final pl = difficultyPl?.trim() ?? '';
      if (pl.isNotEmpty) {
        return pl;
      }
    }
    final en = difficultyEn?.trim() ?? '';
    return language != AppLanguage.vietnamese && en.isNotEmpty
        ? en
        : difficulty;
  }
}

class ScenarioStep {
  const ScenarioStep({
    required this.question,
    required this.options,
    this.questionEn,
    this.questionPl,
  });

  final String question;
  final String? questionEn;
  final String? questionPl;
  final List<ScenarioOption> options;

  factory ScenarioStep.fromJson(Map<String, dynamic> json) {
    return ScenarioStep(
      question: json['question'] as String? ?? '',
      questionEn: json['questionEn'] as String?,
      questionPl: json['questionPl'] as String?,
      options: (json['options'] as List<dynamic>? ?? const [])
          .map((item) => ScenarioOption.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  String questionText(AppLanguage language) {
    if (language == AppLanguage.polish) {
      final pl = questionPl?.trim() ?? '';
      if (pl.isNotEmpty) {
        return pl;
      }
    }
    final en = questionEn?.trim() ?? '';
    return language != AppLanguage.vietnamese && en.isNotEmpty ? en : question;
  }
}

class ScenarioOption {
  const ScenarioOption({
    required this.label,
    required this.isCorrect,
    required this.explanation,
    this.labelEn,
    this.labelPl,
    this.explanationEn,
    this.explanationPl,
  });

  final String label;
  final String? labelEn;
  final String? labelPl;
  final bool isCorrect;
  final String explanation;
  final String? explanationEn;
  final String? explanationPl;

  factory ScenarioOption.fromJson(Map<String, dynamic> json) {
    return ScenarioOption(
      label: json['label'] as String? ?? '',
      labelEn: json['labelEn'] as String?,
      labelPl: json['labelPl'] as String?,
      isCorrect: json['isCorrect'] as bool? ?? false,
      explanation: json['explanation'] as String? ?? '',
      explanationEn: json['explanationEn'] as String?,
      explanationPl: json['explanationPl'] as String?,
    );
  }

  String labelText(AppLanguage language) {
    if (language == AppLanguage.polish) {
      final pl = labelPl?.trim() ?? '';
      if (pl.isNotEmpty) {
        return pl;
      }
    }
    final en = labelEn?.trim() ?? '';
    return language != AppLanguage.vietnamese && en.isNotEmpty ? en : label;
  }

  String explanationText(AppLanguage language) {
    if (language == AppLanguage.polish) {
      final pl = explanationPl?.trim() ?? '';
      if (pl.isNotEmpty) {
        return pl;
      }
    }
    final en = explanationEn?.trim() ?? '';
    return language != AppLanguage.vietnamese && en.isNotEmpty
        ? en
        : explanation;
  }
}
