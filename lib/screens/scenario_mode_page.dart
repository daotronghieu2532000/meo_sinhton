import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../models/scenario_item.dart';
import '../repositories/scenario_repository.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../app/admob_config.dart';
import 'package:flutter/foundation.dart';

String _scenarioText(
  AppLanguage language, {
  required String vi,
  required String en,
  required String pl,
}) {
  switch (language) {
    case AppLanguage.english:
      return en;
    case AppLanguage.polish:
      return pl;
    case AppLanguage.vietnamese:
      return vi;
  }
}

class ScenarioModePage extends StatefulWidget {
  const ScenarioModePage({
    super.key,
    required this.appController,
    required this.isEnglish,
  });

  final AppController appController;
  final bool isEnglish;

  @override
  State<ScenarioModePage> createState() => _ScenarioModePageState();
}

class _ScenarioModePageState extends State<ScenarioModePage> {
  late final Future<List<ScenarioItem>> _future;
  final ScenarioRepository _repository = ScenarioRepository();

  AppLanguage get _language => widget.appController.language;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadScenarios();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ScenarioItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _MessageView(
            text: _scenarioText(
              _language,
              vi: 'Không tải được dữ liệu tình huống offline.',
              en: 'Unable to load offline scenario data.',
              pl: 'Nie mozna zaladowac danych scenariuszy offline.',
            ),
          );
        }

        final scenarios = snapshot.data ?? const <ScenarioItem>[];
        if (scenarios.isEmpty) {
          return _MessageView(
            text: _scenarioText(
              _language,
              vi: 'Chưa có tình huống nào.',
              en: 'No scenarios available yet.',
              pl: 'Brak dostepnych scenariuszy.',
            ),
          );
        }

        return DecoratedBox(
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _ScenarioHeader(language: _language),
              const SizedBox(height: 14),
              ...scenarios.map(
                (scenario) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ScenarioCard(
                    scenario: scenario,
                    language: _language,
                    onStart: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ScenarioPlayScreen(
                            appController: widget.appController,
                            scenario: scenario,
                            language: _language,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ScenarioPlayScreen extends StatefulWidget {
  const ScenarioPlayScreen({
    super.key,
    required this.appController,
    required this.scenario,
    required this.language,
  });

  final AppController appController;
  final ScenarioItem scenario;
  final AppLanguage language;

  @override
  State<ScenarioPlayScreen> createState() => _ScenarioPlayScreenState();
}

class _ScenarioPlayScreenState extends State<ScenarioPlayScreen> {
  int _stepIndex = 0;
  int _score = 0;
  ScenarioOption? _selectedOption;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  void _loadInterstitialAd() {
    if (kIsWeb || widget.appController.areAdsTemporarilyDisabled) return;
    InterstitialAd.load(
      adUnitId: AdmobConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          _interstitialAd?.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  _isInterstitialAdReady = false;
                  _loadInterstitialAd();
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  ad.dispose();
                  _isInterstitialAdReady = false;
                  _loadInterstitialAd();
                },
              );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  ScenarioStep get _currentStep => widget.scenario.steps[_stepIndex];
  AppLanguage get _language => widget.language;

  void _onSelect(ScenarioOption option) {
    if (_selectedOption != null) {
      return;
    }
    setState(() {
      _selectedOption = option;
      if (option.isCorrect) {
        _score += 1;
      }
    });
  }

  void _goNext() {
    if (_selectedOption == null) {
      return;
    }

    if (_stepIndex >= widget.scenario.steps.length - 1) {
      setState(() {});
      return;
    }

    setState(() {
      _stepIndex += 1;
      _selectedOption = null;
    });
  }

  void _restart() {
    setState(() {
      _stepIndex = 0;
      _score = 0;
      _selectedOption = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDone =
        _stepIndex == widget.scenario.steps.length - 1 &&
        _selectedOption != null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.scenario.titleText(_language))),
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: isDone ? _buildResult(context) : _buildQuestion(context),
        ),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final step = _currentStep;
    final progress = (_stepIndex + 1) / widget.scenario.steps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _scenarioText(
                        widget.language,
                        vi: 'Bước ${_stepIndex + 1}/${widget.scenario.steps.length}',
                        en: 'Step ${_stepIndex + 1}/${widget.scenario.steps.length}',
                        pl: 'Krok ${_stepIndex + 1}/${widget.scenario.steps.length}',
                      ),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.secondaryContainer,
                      ],
                    ),
                  ),
                  child: Text(
                    step.questionText(_language),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(step.options.length, (index) {
                  final option = step.options[index];
                  final marker = String.fromCharCode(65 + index);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OptionTile(
                      marker: marker,
                      option: option,
                      language: widget.language,
                      selected: _selectedOption == option,
                      locked: _selectedOption != null,
                      onTap: () => _onSelect(option),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        if (_selectedOption != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 10, bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _selectedOption!.isCorrect
                  ? colorScheme.tertiaryContainer
                  : colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedOption!.isCorrect
                      ? _scenarioText(
                          widget.language,
                          vi: 'Chính xác',
                          en: 'Correct',
                          pl: 'Poprawnie',
                        )
                      : _scenarioText(
                          widget.language,
                          vi: 'Chưa đúng',
                          en: 'Not correct',
                          pl: 'Niepoprawnie',
                        ),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(_selectedOption!.explanationText(_language)),
              ],
            ),
          ),
        FilledButton(
          onPressed: _selectedOption == null ? null : _goNext,
          child: Text(
            _stepIndex == widget.scenario.steps.length - 1
                ? _scenarioText(
                    widget.language,
                    vi: 'Xem kết quả',
                    en: 'View result',
                    pl: 'Zobacz wynik',
                  )
                : _scenarioText(
                    widget.language,
                    vi: 'Tiếp tục',
                    en: 'Continue',
                    pl: 'Kontynuuj',
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult(BuildContext context) {
    final total = widget.scenario.steps.length;
    final ratio = total == 0 ? 0 : _score / total;
    final summary = ratio >= 0.8
        ? _scenarioText(
            widget.language,
            vi: 'Rất tốt! Bạn xử lý tình huống khá chính xác.',
            en: 'Great job! Your decisions are highly accurate.',
            pl: 'Dobra robota! Twoje decyzje sa bardzo trafne.',
          )
        : ratio >= 0.5
        ? _scenarioText(
            widget.language,
            vi: 'Ổn rồi! Tiếp tục luyện thêm để phản xạ tốt hơn.',
            en: 'Nice work! Keep practicing to improve your reaction.',
            pl: 'Dobra robota! Cwicz dalej, aby poprawic refleks.',
          )
        : _scenarioText(
            widget.language,
            vi: 'Thử lại nhé! Đọc kỹ giải thích để cải thiện nhanh.',
            en: 'Try again! Review explanations to improve quickly.',
            pl: 'Sprobuj ponownie! Przejrzyj wyjasnienia, aby szybciej sie poprawic.',
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.secondaryContainer,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _scenarioText(
                  widget.language,
                  vi: 'Kết quả tình huống',
                  en: 'Scenario result',
                  pl: 'Wynik scenariusza',
                ),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.language == AppLanguage.english
                    ? 'Score: $_score/$total'
                    : widget.language == AppLanguage.polish
                    ? 'Wynik: $_score/$total'
                    : 'Điểm: $_score/$total',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(summary),
            ],
          ),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: _restart,
          icon: const Icon(Icons.replay),
          label: Text(
            _scenarioText(
              widget.language,
              vi: 'Chơi lại',
              en: 'Play again',
              pl: 'Zagraj ponownie',
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            if (!widget.appController.areAdsTemporarilyDisabled &&
                _isInterstitialAdReady &&
                _interstitialAd != null) {
              _interstitialAd!.show();
            }
            Navigator.of(context).pop();
          },
          child: Text(
            _scenarioText(
              widget.language,
              vi: 'Tình huống',
              en: 'Scenarios',
              pl: 'Scenariusze',
            ),
          ),
        ),
      ],
    );
  }
}

class _ScenarioHeader extends StatelessWidget {
  const _ScenarioHeader({required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surface.withValues(alpha: 0.45),
            ),
            child: Icon(
              Icons.quiz_rounded,
              size: 24,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _scenarioText(
                    language,
                    vi: 'Luyện phản xạ qua các tình huống thực tế',
                    en: 'Practice quick decisions with real-life scenarios',
                    pl: 'Trenuj szybkie decyzje w realistycznych scenariuszach',
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _scenarioText(
                    language,
                    vi: 'Luyện phản xạ với tình huống thực tế và học từ từng lựa chọn.',
                    en: 'Practice realistic decisions and learn from each choice.',
                    pl: 'Cwicz realistyczne decyzje i ucz sie z kazdego wyboru.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.82,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.scenario,
    required this.language,
    required this.onStart,
  });

  final ScenarioItem scenario;
  final AppLanguage language;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageAsset = scenario.imageAsset?.trim();
    final hasImage = imageAsset != null && imageAsset.isNotEmpty;
    return Semantics(
      container: true,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: hasImage
                        ? Image.asset(
                            imageAsset,
                            fit: BoxFit.cover,
                            height: 160,
                            errorBuilder: (_, __, ___) {
                              return _ScenarioImageFallback(
                                colorScheme: colorScheme,
                              );
                            },
                          )
                        : _ScenarioImageFallback(colorScheme: colorScheme),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scenario.titleText(language),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        scenario.descriptionText(language),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonalIcon(
                          onPressed: onStart,
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: Text(
                            _scenarioText(
                              language,
                              vi: 'Bắt đầu',
                              en: 'Start',
                              pl: 'Start',
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _ScenarioImageFallback extends StatelessWidget {
  const _ScenarioImageFallback({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: 30,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14), const SizedBox(width: 4)],
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.marker,
    required this.option,
    required this.language,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final String marker;
  final ScenarioOption option;
  final AppLanguage language;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tileColor = selected
        ? (option.isCorrect
              ? colorScheme.tertiaryContainer
              : colorScheme.errorContainer)
        : colorScheme.surface;

    return Material(
      color: tileColor,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? (option.isCorrect ? colorScheme.tertiary : colorScheme.error)
                : colorScheme.outlineVariant,
          ),
        ),
        child: InkWell(
          onTap: locked ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? (option.isCorrect
                              ? colorScheme.tertiary
                              : colorScheme.error)
                        : colorScheme.primaryContainer,
                  ),
                  child: Text(
                    marker,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? colorScheme.onPrimary
                          : colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    option.labelText(language),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (selected)
                  Icon(
                    option.isCorrect ? Icons.check_circle : Icons.cancel,
                    color: option.isCorrect
                        ? colorScheme.tertiary
                        : colorScheme.error,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
