import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../app/app_strings.dart';
import '../models/scenario_item.dart';
import '../repositories/scenario_repository.dart';

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
            text: AppStrings.scenarioLoadError(widget.isEnglish),
          );
        }

        final scenarios = snapshot.data ?? const <ScenarioItem>[];
        if (scenarios.isEmpty) {
          return _MessageView(
            text: AppStrings.scenarioNoData(widget.isEnglish),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _ScenarioHeader(isEnglish: widget.isEnglish),
            const SizedBox(height: 12),
            ...scenarios.map(
              (scenario) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ScenarioCard(
                  scenario: scenario,
                  isEnglish: widget.isEnglish,
                  onStart: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ScenarioPlayScreen(
                          scenario: scenario,
                          isEnglish: widget.isEnglish,
                        ),
                      ),
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
}

class ScenarioPlayScreen extends StatefulWidget {
  const ScenarioPlayScreen({
    super.key,
    required this.scenario,
    required this.isEnglish,
  });

  final ScenarioItem scenario;
  final bool isEnglish;

  @override
  State<ScenarioPlayScreen> createState() => _ScenarioPlayScreenState();
}

class _ScenarioPlayScreenState extends State<ScenarioPlayScreen> {
  int _stepIndex = 0;
  int _score = 0;
  ScenarioOption? _selectedOption;

  ScenarioStep get _currentStep => widget.scenario.steps[_stepIndex];

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
      appBar: AppBar(title: Text(widget.scenario.titleText(widget.isEnglish))),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: isDone ? _buildResult(context) : _buildQuestion(context),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final step = _currentStep;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            AppStrings.scenarioStepProgress(
              widget.isEnglish,
              _stepIndex + 1,
              widget.scenario.steps.length,
            ),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          step.questionText(widget.isEnglish),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        ...step.options.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OptionTile(
              option: option,
              isEnglish: widget.isEnglish,
              selected: _selectedOption == option,
              locked: _selectedOption != null,
              onTap: () => _onSelect(option),
            ),
          ),
        ),
        const Spacer(),
        if (_selectedOption != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
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
                      ? AppStrings.scenarioCorrect(widget.isEnglish)
                      : AppStrings.scenarioIncorrect(widget.isEnglish),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(_selectedOption!.explanationText(widget.isEnglish)),
              ],
            ),
          ),
        FilledButton(
          onPressed: _selectedOption == null ? null : _goNext,
          child: Text(
            _stepIndex == widget.scenario.steps.length - 1
                ? AppStrings.scenarioViewResult(widget.isEnglish)
                : AppStrings.scenarioContinue(widget.isEnglish),
          ),
        ),
      ],
    );
  }

  Widget _buildResult(BuildContext context) {
    final total = widget.scenario.steps.length;
    final ratio = total == 0 ? 0 : _score / total;
    final summary = ratio >= 0.8
        ? AppStrings.scenarioResultGreat(widget.isEnglish)
        : ratio >= 0.5
        ? AppStrings.scenarioResultGood(widget.isEnglish)
        : AppStrings.scenarioResultRetry(widget.isEnglish);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.scenarioResultTitle(widget.isEnglish),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.scenarioScore(widget.isEnglish, _score, total),
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
          label: Text(AppStrings.scenarioPlayAgain(widget.isEnglish)),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.tabScenario(widget.isEnglish)),
        ),
      ],
    );
  }
}

class _ScenarioHeader extends StatelessWidget {
  const _ScenarioHeader({required this.isEnglish});

  final bool isEnglish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.route_rounded,
            size: 28,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppStrings.scenarioHeadline(isEnglish),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
    required this.isEnglish,
    required this.onStart,
  });

  final ScenarioItem scenario;
  final bool isEnglish;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scenario.titleText(isEnglish),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              scenario.descriptionText(isEnglish),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(text: scenario.difficultyText(isEnglish)),
                _Pill(
                  text: AppStrings.minuteUnit(
                    isEnglish,
                    scenario.estimatedMinutes,
                    compact: true,
                  ),
                ),
                _Pill(
                  text: AppStrings.categoryTipCount(
                    isEnglish,
                    scenario.steps.length,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(AppStrings.scenarioStart(isEnglish)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.isEnglish,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final ScenarioOption option;
  final bool isEnglish;
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
        : colorScheme.surfaceContainerLow;

    return Material(
      color: tileColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.labelText(isEnglish),
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
