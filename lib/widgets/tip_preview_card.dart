import 'package:flutter/material.dart';
import 'package:meo_sinhton/app/app_strings.dart';
import 'package:meo_sinhton/models/survival_tip.dart';
import 'package:share_plus/share_plus.dart';

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
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Facebook-style Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    radius: 20,
                    child: Icon(
                      tip.isEmergency ? Icons.warning_amber_rounded : Icons.tips_and_updates_outlined, 
                      color: tip.isEmergency ? Colors.red : Theme.of(context).colorScheme.primary, 
                      size: 24
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip.categoryText(isEnglish),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        // Metadata Row with ellipsis protection
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: Row(
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5),
                                child: Text(
                                  '${tip.subCategoryText(isEnglish)} • ${AppStrings.minuteUnit(isEnglish, tip.estimatedMinutes, compact: true)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              if (tip.isEmergency) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '• ${AppStrings.emergencyChip(isEnglish)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                              const SizedBox(width: 4),
                              Icon(Icons.public, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // Title and Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tip.titleText(isEnglish),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip.summaryText(isEnglish),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Image
            if (tip.imageAsset != null && tip.imageAsset!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Image.asset(
                tip.imageAsset!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    height: 200,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 32,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ],

            // Action Buttons (Combined Like & Save)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    context,
                    icon: isSaved ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                    label: isEnglish ? 'Like' : 'Thích',
                    color: isSaved ? Colors.blue : Theme.of(context).colorScheme.onSurfaceVariant,
                    onTap: onToggleSaved, // Now Like button handles saving
                  ),
                  _buildActionButton(
                    context,
                    icon: Icons.share_outlined,
                    label: isEnglish ? 'Share' : 'Chia sẻ',
                    onTap: () {
                      final content = """
${tip.titleText(isEnglish)}

${tip.summaryText(isEnglish)}

${isEnglish ? 'More details in the Mẹo Sinh Tồn app!' : 'Xem chi tiết trong ứng dụng Mẹo Sinh Tồn!'}
""";
                      Share.share(content);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {
    required IconData icon, 
    required String label, 
    Color? color,
    required VoidCallback onTap
  }) {
    final finalColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: finalColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: finalColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
