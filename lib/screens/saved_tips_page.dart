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
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_outline_rounded,
                size: 64,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.noSavedTips(isEnglish),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.savedPlaceholderDesc(isEnglish),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.home),
              label: Text(isEnglish ? 'Explore Tips' : 'Khám phá mẹo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tabSaved(isEnglish)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: false,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainerLowest,
            ],
          ),
        ),
        child: AnimatedBuilder(
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
                padding: const EdgeInsets.all(16),
                itemCount: savedTips.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
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
        ),
      ),
    );
  }
}
