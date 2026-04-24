import 'package:flutter/material.dart';
import 'package:meo_sinhton/app/app_controller.dart';
import 'package:meo_sinhton/app/app_strings.dart';
import 'package:meo_sinhton/models/survival_tip.dart';
import 'package:meo_sinhton/widgets/info_pill.dart';
import 'package:meo_sinhton/widgets/step_item.dart';
import 'package:meo_sinhton/widgets/tip_image_placeholder.dart';

class TipDetailScreen extends StatelessWidget {
  const TipDetailScreen({
    super.key,
    required this.tip,
    required this.appController,
    required this.language,
  });

  final SurvivalTip tip;
  final AppController appController;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appController,
      builder: (context, _) {
        final isSaved = appController.isTipSaved(tip.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(tip.titleText(language)),
            actions: [
              IconButton(
                tooltip: isSaved
                    ? AppStrings.unsaveTip(language == AppLanguage.english)
                    : AppStrings.saveTip(language == AppLanguage.english),
                onPressed: () async {
                  final wasSaved = appController.isTipSaved(tip.id);
                  await appController.toggleTipSaved(tip.id);
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(milliseconds: 1200),
                      content: Text(
                        wasSaved
                            ? AppStrings.tipUnsaved(
                                language == AppLanguage.english,
                              )
                            : AppStrings.tipSaved(
                                language == AppLanguage.english,
                              ),
                      ),
                    ),
                  );
                },
                icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                tip.summaryText(language),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  InfoPill(
                    icon: Icons.folder_outlined,
                    label: tip.categoryText(language),
                  ),
                  InfoPill(
                    icon: Icons.sell_outlined,
                    label: tip.subCategoryText(language),
                  ),
                  InfoPill(
                    icon: Icons.speed_outlined,
                    label: tip.difficultyText(language),
                  ),
                  InfoPill(
                    icon: Icons.schedule_outlined,
                    label: AppStrings.minuteUnit(
                      language,
                      tip.estimatedMinutes,
                    ),
                  ),
                  if (tip.isEmergency)
                    InfoPill(
                      icon: Icons.warning_amber_rounded,
                      label: AppStrings.emergencyChip(language),
                      highlighted: true,
                    ),
                  ...tip
                      .tagsText(language)
                      .map(
                        (tag) => InfoPill(icon: Icons.tag_outlined, label: tag),
                      ),
                ],
              ),
              const SizedBox(height: 16),
              TipImagePlaceholder(
                imageAsset: tip.imageAsset,
                language: language,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.detailsHeader(language),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < tip.stepsText(language).length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: StepItem(
                    number: i + 1,
                    text: tip.stepsText(language)[i],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
