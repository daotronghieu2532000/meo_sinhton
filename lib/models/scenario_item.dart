class ScenarioItem {
  const ScenarioItem({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.steps,
    this.titleEn,
    this.descriptionEn,
    this.difficultyEn,
  });

  final String id;
  final String title;
  final String description;
  final String difficulty;
  final int estimatedMinutes;
  final List<ScenarioStep> steps;
  final String? titleEn;
  final String? descriptionEn;
  final String? difficultyEn;

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
      titleEn: json['titleEn'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
      difficultyEn: json['difficultyEn'] as String?,
    );
  }

  String titleText(bool isEnglish) {
    final en = titleEn?.trim() ?? '';
    return isEnglish && en.isNotEmpty ? en : title;
  }

  String descriptionText(bool isEnglish) {
    final en = descriptionEn?.trim() ?? '';
    return isEnglish && en.isNotEmpty ? en : description;
  }

  String difficultyText(bool isEnglish) {
    final en = difficultyEn?.trim() ?? '';
    return isEnglish && en.isNotEmpty ? en : difficulty;
  }
}

class ScenarioStep {
  const ScenarioStep({
    required this.question,
    required this.options,
    this.questionEn,
  });

  final String question;
  final String? questionEn;
  final List<ScenarioOption> options;

  factory ScenarioStep.fromJson(Map<String, dynamic> json) {
    return ScenarioStep(
      question: json['question'] as String? ?? '',
      questionEn: json['questionEn'] as String?,
      options: (json['options'] as List<dynamic>? ?? const [])
          .map((item) => ScenarioOption.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  String questionText(bool isEnglish) {
    final en = questionEn?.trim() ?? '';
    return isEnglish && en.isNotEmpty ? en : question;
  }
}

class ScenarioOption {
  const ScenarioOption({
    required this.label,
    required this.isCorrect,
    required this.explanation,
    this.labelEn,
    this.explanationEn,
  });

  final String label;
  final String? labelEn;
  final bool isCorrect;
  final String explanation;
  final String? explanationEn;

  factory ScenarioOption.fromJson(Map<String, dynamic> json) {
    return ScenarioOption(
      label: json['label'] as String? ?? '',
      labelEn: json['labelEn'] as String?,
      isCorrect: json['isCorrect'] as bool? ?? false,
      explanation: json['explanation'] as String? ?? '',
      explanationEn: json['explanationEn'] as String?,
    );
  }

  String labelText(bool isEnglish) {
    final en = labelEn?.trim() ?? '';
    return isEnglish && en.isNotEmpty ? en : label;
  }

  String explanationText(bool isEnglish) {
    final en = explanationEn?.trim() ?? '';
    return isEnglish && en.isNotEmpty ? en : explanation;
  }
}
