import 'package:flutter/material.dart';
import 'package:meo_sinhton/app/app_controller.dart';
import 'package:meo_sinhton/app/app_i18n.dart';
import 'package:meo_sinhton/app/app_strings.dart';
import 'package:meo_sinhton/models/survival_tip.dart';
import 'package:meo_sinhton/repositories/tip_repository.dart';
import 'package:meo_sinhton/screens/tip_category_screen.dart';

class CategoryOverviewPage extends StatefulWidget {
  const CategoryOverviewPage({
    super.key,
    required this.appController,
    required this.isEnglish,
  });

  final AppController appController;
  final bool isEnglish;

  @override
  State<CategoryOverviewPage> createState() => _CategoryOverviewPageState();
}

class _CategoryOverviewPageState extends State<CategoryOverviewPage> {
  late final Future<List<SurvivalTip>> _tipsFuture;

  IconData _categoryIcon(String category) {
    final key = category.toLowerCase();
    if (key.contains('khẩn cấp') || key.contains('emergency')) {
      return Icons.warning_amber_rounded;
    }
    if (key.contains('sinh tồn') || key.contains('survival')) {
      return Icons.hiking_rounded;
    }
    if (key.contains('sức khỏe') ||
        key.contains('y tế') ||
        key.contains('health')) {
      return Icons.health_and_safety_outlined;
    }
    if (key.contains('kỹ năng') || key.contains('practical')) {
      return Icons.handyman_outlined;
    }
    return Icons.folder_open_outlined;
  }

  @override
  void initState() {
    super.initState();
    _tipsFuture = TipRepository.loadTips();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SurvivalTip>>(
      future: _tipsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(AppStrings.categoryLoadError(widget.isEnglish)),
          );
        }

        final tips = snapshot.data ?? const <SurvivalTip>[];
        final counts = <String, int>{};
        for (final tip in tips) {
          counts[tip.category] = (counts[tip.category] ?? 0) + 1;
        }
        final categories = counts.keys.toList()..sort();

        if (categories.isEmpty) {
          return Center(child: Text(AppStrings.noCategories(widget.isEnglish)));
        }

        final scheme = Theme.of(context).colorScheme;

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: categories.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.grid_view_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.isEnglish
                            ? 'Choose a category to explore tips'
                            : 'Chọn danh mục để xem mẹo',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${categories.length}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final category = categories[index - 1];
            final tipCount = counts[category] ?? 0;

            return Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TipCategoryScreen(
                        category: category,
                        appController: widget.appController,
                        isEnglish: widget.isEnglish,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          _categoryIcon(category),
                          size: 20,
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppI18n.category(category, widget.isEnglish),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                AppStrings.categoryTipCount(
                                  widget.isEnglish,
                                  tipCount,
                                ),
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
