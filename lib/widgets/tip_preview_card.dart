import 'package:flutter/material.dart';
import 'package:meo_sinhton/app/app_strings.dart';
import 'package:meo_sinhton/models/survival_tip.dart';
import 'package:meo_sinhton/widgets/info_pill.dart';

class TipPreviewCard extends StatelessWidget {
  const TipPreviewCard({
    super.key,
    required this.tip,
    required this.isEnglish,
    required this.isSaved,
    required this.onTap,
    required this.onToggleSaved,
    required this.saveTooltip,
    required this.unsaveTooltip,
  });

  final SurvivalTip tip;
  final bool isEnglish;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onToggleSaved;
  final String saveTooltip;
  final String unsaveTooltip;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tip.imageAsset != null && tip.imageAsset!.trim().isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  tip.imageAsset!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 32,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          tip.titleText(isEnglish),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tip.summaryText(isEnglish),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
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
                              icon: Icons.schedule_outlined,
                              label: AppStrings.minuteUnit(
                                isEnglish,
                                tip.estimatedMinutes,
                                compact: true,
                              ),
                            ),
                            if (tip.isEmergency)
                              InfoPill(
                                icon: Icons.warning_amber_rounded,
                                label: AppStrings.emergencyChip(isEnglish),
                                highlighted: true,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: isSaved ? unsaveTooltip : saveTooltip,
                        onPressed: onToggleSaved,
                        icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
