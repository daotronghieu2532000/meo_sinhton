import 'package:flutter/material.dart';
import 'package:meo_sinhton/app/app_controller.dart';
import 'package:meo_sinhton/models/survival_tip.dart';
import 'package:meo_sinhton/repositories/tip_repository.dart';
import 'package:meo_sinhton/screens/tip_detail_screen.dart';
import 'package:meo_sinhton/widgets/tip_preview_card.dart';

String _tr(AppLanguage language, String vi, String en, String pl) {
  switch (language) {
    case AppLanguage.english:
      return en;
    case AppLanguage.polish:
      return pl;
    case AppLanguage.vietnamese:
      return vi;
  }
}

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
  State<TipFeedView> createState() => TipFeedViewState();
}

class TipFeedViewState extends State<TipFeedView> {
  late final Future<List<SurvivalTip>> _tipsFuture;
  String _query = '';
  String _selectedCategory = 'Tất cả';
  bool _isSearchExpanded = false;

  void toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
    });
  }

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
          tip
              .titleText(widget.appController.language)
              .toLowerCase()
              .contains(lowerQuery) ||
          tip.summary.toLowerCase().contains(lowerQuery) ||
          tip
              .summaryText(widget.appController.language)
              .toLowerCase()
              .contains(lowerQuery) ||
          tip.subCategory.toLowerCase().contains(lowerQuery) ||
          tip
              .subCategoryText(widget.appController.language)
              .toLowerCase()
              .contains(lowerQuery) ||
          tip.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
          tip
              .tagsText(widget.appController.language)
              .any((tag) => tag.toLowerCase().contains(lowerQuery));
      return matchCategory && matchQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.appController.language;
    final useEnglishContent = language != AppLanguage.vietnamese;
    return FutureBuilder<List<SurvivalTip>>(
      future: _tipsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              _tr(
                language,
                'Không đọc được dữ liệu offline. Vui lòng kiểm tra JSON.',
                'Unable to load offline data. Please check JSON.',
                'Nie można wczytać danych offline. Sprawdź JSON.',
              ),
            ),
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

        return Column(
          children: [
            // Search & Filter Header (Fixed at top)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Visibility(
                visible: _isSearchExpanded,
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: 42,
                          child: TextField(
                            textAlignVertical: TextAlignVertical.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: _tr(
                                language,
                                'Tìm mẹo theo từ khóa...',
                                'Search tips by keyword...',
                                'Szukaj porad według słowa kluczowego...',
                              ),
                              prefixIcon: const Icon(Icons.search, size: 18),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 34,
                                minHeight: 34,
                              ),
                              suffixIcon: widget.emergencyOnly
                                  ? const Icon(
                                      Icons.warning_amber_rounded,
                                      size: 18,
                                    )
                                  : const Icon(
                                      Icons.tips_and_updates_outlined,
                                      size: 18,
                                    ),
                              suffixIconConstraints: const BoxConstraints(
                                minWidth: 34,
                                minHeight: 34,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                            ),
                            onChanged: (value) =>
                                setState(() => _query = value),
                          ),
                        ),
                      ),
                      if (widget.showCategoryChips &&
                          widget.lockedCategory == null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 34,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, cIndex) {
                              final category = categories[cIndex];
                              return ChoiceChip(
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                showCheckmark: false,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                label: Text(
                                  _categoryLabel(category, language),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                                selected: _selectedCategory == category,
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                                selectedColor: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                                onSelected: (_) => setState(
                                  () => _selectedCategory = category,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // List of Tips
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 500));
                  setState(() {});
                },
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: filteredTips.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final tip = filteredTips[index];
                    final isSaved = widget.appController.isTipSaved(tip.id);

                    return TipPreviewCard(
                      tip: tip,
                      language: widget.appController.language,
                      isSaved: isSaved,
                      saveTooltip: _tr(
                        language,
                        'Lưu mẹo',
                        'Save tip',
                        'Zapisz poradę',
                      ),
                      unsaveTooltip: _tr(
                        language,
                        'Bỏ lưu mẹo',
                        'Unsave tip',
                        'Usuń zapis',
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TipDetailScreen(
                              tip: tip,
                              appController: widget.appController,
                              language: widget.appController.language,
                            ),
                          ),
                        );
                      },
                      onToggleSaved: () async {
                        await widget.appController.toggleTipSaved(tip.id);
                        setState(() {}); // Update local indicator
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _categoryLabel(String category, AppLanguage language) {
    switch (category) {
      case 'Tất cả':
        return _tr(language, 'Tất cả', 'All', 'Wszystkie');
      case 'Sơ cứu':
        return _tr(language, 'Sơ cứu', 'First aid', 'Pierwsza pomoc');
      case 'Kinh nghiệm':
        return _tr(language, 'Kinh nghiệm', 'Experience', 'Doświadczenie');
      case 'Mẹo':
        return _tr(language, 'Mẹo', 'Tips', 'Porady');
      case 'Phản hồi':
        return _tr(language, 'Phản hồi', 'Feedback', 'Opinie');
      default:
        return category;
    }
  }
}
