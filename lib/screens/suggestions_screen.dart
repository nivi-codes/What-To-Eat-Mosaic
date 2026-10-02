import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/eat_flow_provider.dart';
import '../providers/saved_provider.dart';
import '../providers/preferences_provider.dart';
import '../models/suggestion.dart';
import '../services/web_links.dart';
import '../widgets/doodles.dart';
import '../widgets/offset_card.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  final Map<String, bool> _showHealthy = {};
  bool _healthyInitialized = false;

  void _initHealthyDefaults(List<Suggestion> suggestions, String healthyPref) {
    if (_healthyInitialized) return;
    _healthyInitialized = true;
    if (healthyPref == 'healthy_first') {
      for (final s in suggestions) {
        if (s.hasHealthyVersion) {
          _showHealthy[s.id] = true;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<EatFlowProvider>();
    final saved = context.watch<SavedProvider>();
    final healthyPref = context.read<PreferencesProvider>().preferences.healthyPreference;

    if (flow.suggestions.isNotEmpty) {
      _initHealthyDefaults(flow.suggestions, healthyPref);
    }

    if (flow.suggestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Suggestions')),
        body: const Center(child: DoodleLoader(title: 'Finding your picks…')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            flow.reset();
            context.go('/eat');
          },
        ),
        title: const Text('Your picks'),
        actions: [
          TextButton(
            onPressed: () {
              flow.shuffleAll();
              setState(() => _showHealthy.clear());
            },
            child: const Text('Surprise me'),
          ),
        ],
      ),
      body: flow.currentStep == EatFlowStep.loading
          ? const Center(child: DoodleLoader(title: 'Finding fresh picks…'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  flow.method == 'dine'
                      ? 'Here are 3 places worth heading out to'
                      : 'Here are 3 great options for you',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ...flow.suggestions.asMap().entries.map((entry) {
                  final suggestion = entry.value;
                  final showH = _showHealthy[suggestion.id] ?? false;
                  return _SuggestionCard(
                    suggestion: suggestion,
                    showHealthy: showH,
                    isSaved: saved.isSaved(suggestion.recipeId),
                    onToggleHealthy: (v) => setState(() => _showHealthy[suggestion.id] = v),
                    onSave: () => saved.toggle(suggestion),
                    onNotFeeling: () {
                      flow.shuffleAll();
                      setState(() => _showHealthy.clear());
                    },
                    // Recipes only when cooking at home.
                    onTap: () => switch (suggestion.path) {
                      'dine' => context.push('/eat/menu/${suggestion.recipeId}'),
                      'order' => openInNewTab(swiggySearchUrl(suggestion.title)),
                      _ => context.push('/eat/recipe/${suggestion.recipeId}'),
                    },
                  );
                }),
                const SizedBox(height: 80),
              ],
            ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.showHealthy,
    required this.isSaved,
    required this.onToggleHealthy,
    required this.onSave,
    required this.onNotFeeling,
    required this.onTap,
  });

  final Suggestion suggestion;
  final bool showHealthy;
  final bool isSaved;
  final ValueChanged<bool> onToggleHealthy;
  final VoidCallback onSave;
  final VoidCallback onNotFeeling;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nutrition = showHealthy && suggestion.healthyNutrition != null
        ? suggestion.healthyNutrition!
        : suggestion.nutrition;
    final action = switch (suggestion.path) {
      'dine' => ('View menu', Icons.restaurant_menu),
      'order' => ('Order on Swiggy', Icons.delivery_dining_outlined),
      _ => ('View recipe', Icons.menu_book_outlined),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: OffsetCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.ink, width: 2.5))),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  suggestion.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.primaryLight,
                    child: const Icon(Icons.restaurant, color: AppColors.ink, size: 40),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(suggestion.title, style: Theme.of(context).textTheme.titleLarge),
                      ),
                      IconButton(
                        icon: Icon(isSaved ? Icons.favorite : Icons.favorite_border, color: AppColors.ink),
                        onPressed: onSave,
                        tooltip: isSaved ? 'Saved' : 'Save',
                        style: IconButton.styleFrom(
                          side: const BorderSide(color: AppColors.ink, width: 2),
                          backgroundColor: isSaved ? AppColors.blush : AppColors.surface,
                        ),
                      ),
                    ],
                  ),
                  Text(suggestion.subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      // No calories for restaurants — there's no single dish to count.
                      if (!suggestion.isRestaurant) OutlinePill('~${nutrition.calories} kcal', fill: AppColors.turmeric),
                      ...suggestion.healthHighlights.take(3).map((h) => OutlinePill(h)),
                    ],
                  ),
                  if (!suggestion.isRestaurant && suggestion.hasHealthyVersion) ...[
                    const SizedBox(height: 12),
                    _HealthyToggle(showHealthy: showHealthy, onToggle: onToggleHealthy),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onTap,
                          icon: Icon(action.$2, size: 18),
                          label: Text(action.$1),
                          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onNotFeeling,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Not feeling it'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
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

/// Regular / Healthy pill switch; the active side fills lime.
class _HealthyToggle extends StatelessWidget {
  const _HealthyToggle({required this.showHealthy, required this.onToggle});
  final bool showHealthy;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Row(
        children: [
          Expanded(child: _ToggleOption('Regular', !showHealthy, () => onToggle(false))),
          Expanded(child: _ToggleOption('Healthy', showHealthy, () => onToggle(true))),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption(this.label, this.active, this.onTap);
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.lime : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          border: active ? Border.all(color: AppColors.ink, width: 2) : null,
        ),
        child: Text(
          label,
          style: AppTheme.font(size: 14, weight: active ? FontWeight.w800 : FontWeight.w600, color: AppColors.ink),
        ),
      ),
    );
  }
}
