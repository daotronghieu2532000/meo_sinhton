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
    required this.isEnglish,
  });

  final SurvivalTip tip;
  final AppController appController;
  final bool isEnglish;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appController,
      builder: (context, _) {
        final isSaved = appController.isTipSaved(tip.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(tip.titleText(isEnglish)),
            actions: [
              IconButton(
                tooltip: isSaved
                    ? AppStrings.unsaveTip(isEnglish)
                    : AppStrings.saveTip(isEnglish),
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
                            ? AppStrings.tipUnsaved(isEnglish)
                            : AppStrings.tipSaved(isEnglish),
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
                tip.summaryText(isEnglish),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  InfoPill(
                    icon: Icons.folder_outlined,
                    label: tip.categoryText(isEnglish),
                  ),
                  InfoPill(
                    icon: Icons.sell_outlined,
                    label: tip.subCategoryText(isEnglish),
                  ),
                  InfoPill(
                    icon: Icons.speed_outlined,
                    label: tip.difficultyText(isEnglish),
                  ),
                  InfoPill(
                    icon: Icons.schedule_outlined,
                    label: AppStrings.minuteUnit(
                      isEnglish,
                      tip.estimatedMinutes,
                    ),
                  ),
                  if (tip.isEmergency)
                    InfoPill(
                      icon: Icons.warning_amber_rounded,
                      label: AppStrings.emergencyChip(isEnglish),
                      highlighted: true,
                    ),
                  ...tip
                      .tagsText(isEnglish)
                      .map(
                        (tag) => InfoPill(icon: Icons.tag_outlined, label: tag),
                      ),
                ],
              ),
              const SizedBox(height: 16),
              TipImagePlaceholder(
                imageAsset: tip.imageAsset,
                isEnglish: isEnglish,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.detailsHeader(isEnglish),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < tip.stepsText(isEnglish).length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: StepItem(
                    number: i + 1,
                    text: tip.stepsText(isEnglish)[i],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
