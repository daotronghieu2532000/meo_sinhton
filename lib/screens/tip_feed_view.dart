import 'package:flutter/material.dart';
import 'package:meo_sinhton/app/app_controller.dart';
import 'package:meo_sinhton/app/app_i18n.dart';
import 'package:meo_sinhton/app/app_strings.dart';
import 'package:meo_sinhton/models/survival_tip.dart';
import 'package:meo_sinhton/repositories/tip_repository.dart';
import 'package:meo_sinhton/screens/tip_detail_screen.dart';
import 'package:meo_sinhton/widgets/tip_preview_card.dart';

class TipFeedView extends StatefulWidget {
  const TipFeedView({
    super.key,
    this.emergencyOnly = false,
    this.lockedCategory,
    this.showCategoryChips = true,
    required this.appController,
    required this.isEnglish,
  });

  final bool emergencyOnly;
  final String? lockedCategory;
  final bool showCategoryChips;
  final AppController appController;
  final bool isEnglish;

  @override
  State<TipFeedView> createState() => _TipFeedViewState();
}

class _TipFeedViewState extends State<TipFeedView> {
  late final Future<List<SurvivalTip>> _tipsFuture;
  String _query = '';
  String _selectedCategory = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _tipsFuture = TipRepository.loadTips();
  }

  List<String> _categoriesFrom(List<SurvivalTip> tips) {
    final set = <String>{'Tất cả', ...tips.map((tip) => tip.category)};
    return set.toList();
  }

  List<SurvivalTip> _filterTips(List<SurvivalTip> tips) {
    return tips.where((tip) {
      if (widget.emergencyOnly && !tip.isEmergency) {
        return false;
      }

      if (widget.lockedCategory != null &&
          tip.category != widget.lockedCategory) {
        return false;
      }

      final matchCategory =
          _selectedCategory == 'Tất cả' || tip.category == _selectedCategory;
      final lowerQuery = _query.toLowerCase().trim();
      final matchQuery =
          lowerQuery.isEmpty ||
          tip.title.toLowerCase().contains(lowerQuery) ||
          tip.titleText(widget.isEnglish).toLowerCase().contains(lowerQuery) ||
          tip.summary.toLowerCase().contains(lowerQuery) ||
          tip
              .summaryText(widget.isEnglish)
              .toLowerCase()
              .contains(lowerQuery) ||
          tip.subCategory.toLowerCase().contains(lowerQuery) ||
          tip
              .subCategoryText(widget.isEnglish)
              .toLowerCase()
              .contains(lowerQuery) ||
          tip.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
          tip
              .tagsText(widget.isEnglish)
              .any((tag) => tag.toLowerCase().contains(lowerQuery));
      return matchCategory && matchQuery;
    }).toList();
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
            child: Text(AppStrings.offlineDataError(widget.isEnglish)),
          );
        }

        final tips = snapshot.data ?? const <SurvivalTip>[];
        final categories = _categoriesFrom(tips);

        if (widget.lockedCategory != null) {
          _selectedCategory = widget.lockedCategory!;
        } else if (!categories.contains(_selectedCategory)) {
          _selectedCategory = 'Tất cả';
        }

        final filteredTips = _filterTips(tips);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.feedHeadline(
                  widget.isEnglish,
                  emergencyOnly: widget.emergencyOnly,
                ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: TextField(
                  textAlignVertical: TextAlignVertical.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: AppStrings.searchHint(widget.isEnglish),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 34,
                      minHeight: 34,
                    ),
                    suffixIcon: widget.emergencyOnly
                        ? const Icon(Icons.warning_amber_rounded, size: 18)
                        : const Icon(Icons.tips_and_updates_outlined, size: 18),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 34,
                      minHeight: 34,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              const SizedBox(height: 10),
              if (widget.showCategoryChips && widget.lockedCategory == null)
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        label: Text(
                          AppI18n.category(category, widget.isEnglish),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        selected: _selectedCategory == category,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = category),
                      );
                    },
                  ),
                ),
              if (widget.showCategoryChips && widget.lockedCategory == null)
                const SizedBox(height: 6),
              const SizedBox(height: 8),
              Expanded(
                child: filteredTips.isEmpty
                    ? Center(
                        child: Text(
                          AppStrings.noMatchingTips(widget.isEnglish),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(top: 6, bottom: 12),
                        itemCount: filteredTips.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final tip = filteredTips[index];
                          final isSaved = widget.appController.isTipSaved(
                            tip.id,
                          );
                          return TipPreviewCard(
                            tip: tip,
                            isEnglish: widget.isEnglish,
                            isSaved: isSaved,
                            saveTooltip: AppStrings.saveTip(widget.isEnglish),
                            unsaveTooltip: AppStrings.unsaveTip(
                              widget.isEnglish,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TipDetailScreen(
                                    tip: tip,
                                    appController: widget.appController,
                                    isEnglish: widget.isEnglish,
                                  ),
                                ),
                              );
                            },
                            onToggleSaved: () async {
                              final wasSaved = widget.appController.isTipSaved(
                                tip.id,
                              );
                              await widget.appController.toggleTipSaved(tip.id);
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  duration: const Duration(milliseconds: 1200),
                                  content: Text(
                                    wasSaved
                                        ? AppStrings.tipUnsaved(
                                            widget.isEnglish,
                                          )
                                        : AppStrings.tipSaved(widget.isEnglish),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
