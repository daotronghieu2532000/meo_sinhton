import 'package:flutter/material.dart';
import 'package:meo_sinhton/app/app_controller.dart';
import 'package:meo_sinhton/app/app_strings.dart';
import 'package:meo_sinhton/models/survival_tip.dart';
import 'package:meo_sinhton/repositories/tip_repository.dart';
import 'package:meo_sinhton/screens/tip_detail_screen.dart';
import 'package:meo_sinhton/widgets/tip_preview_card.dart';

class SavedTipsPage extends StatelessWidget {
  const SavedTipsPage({
    super.key,
    required this.appController,
    required this.isEnglish,
  });

  final AppController appController;
  final bool isEnglish;

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.bookmark_border,
                size: 38,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.noSavedTips(isEnglish),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.savedPlaceholderDesc(isEnglish),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appController,
      builder: (context, _) => FutureBuilder<List<SurvivalTip>>(
        future: TipRepository.loadTips(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(AppStrings.offlineDataError(isEnglish)));
          }

          final allTips = snapshot.data ?? const <SurvivalTip>[];
          final savedTips = allTips
              .where((tip) => appController.isTipSaved(tip.id))
              .toList();

          if (savedTips.isEmpty) {
            return _emptyState(context);
          }

          return ListView.separated(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12,
            ),
            itemCount: savedTips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final tip = savedTips[index];
              return TipPreviewCard(
                tip: tip,
                isEnglish: isEnglish,
                isSaved: true,
                saveTooltip: AppStrings.saveTip(isEnglish),
                unsaveTooltip: AppStrings.unsaveTip(isEnglish),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TipDetailScreen(
                        tip: tip,
                        appController: appController,
                        isEnglish: isEnglish,
                      ),
                    ),
                  );
                },
                onToggleSaved: () async {
                  await appController.toggleTipSaved(tip.id);
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(milliseconds: 1200),
                      content: Text(AppStrings.tipUnsaved(isEnglish)),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
