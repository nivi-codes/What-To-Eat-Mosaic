import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/eat_flow_provider.dart';
import '../providers/saved_provider.dart';
import '../providers/preferences_provider.dart';
import '../models/suggestion.dart';
import '../services/web_links.dart';

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
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  suggestion.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.primaryLight,
                    child: const Icon(Icons.restaurant, color: AppColors.primary, size: 40),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(suggestion.title, style: Theme.of(context).textTheme.titleMedium),
                      ),
                      IconButton(
                        icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_outline,
                          color: isSaved ? AppColors.primary : AppColors.textMuted,
                        ),
                        onPressed: onSave,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  Text(suggestion.subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 10),

                  // Health highlights
                  if (suggestion.healthHighlights.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      children: suggestion.healthHighlights.take(3).map((h) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.tagBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(h, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
                      )).toList(),
                    ),
                  const SizedBox(height: 10),

                  // Calorie + toggle row — not for restaurants (no single dish to count)
                  if (!suggestion.isRestaurant) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0E6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '~${nutrition.calories} kcal',
                            style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Spacer(),
                        if (suggestion.hasHealthyVersion)
                          _HealthyToggle(
                            showHealthy: showHealthy,
                            onToggle: onToggleHealthy,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: onNotFeeling,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Not feeling it'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: onTap,
                          icon: Icon(
                            switch (suggestion.path) {
                              'dine' => Icons.restaurant_menu,
                              'order' => Icons.delivery_dining_outlined,
                              _ => Icons.menu_book_outlined,
                            },
                            size: 16,
                          ),
                          label: Text(switch (suggestion.path) {
                            'dine' => 'View menu',
                            'order' => 'Order on Swiggy',
                            _ => 'View recipe',
                          }),
                          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
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

class _HealthyToggle extends StatelessWidget {
  const _HealthyToggle({required this.showHealthy, required this.onToggle});
  final bool showHealthy;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.tagBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption('Regular', !showHealthy, () => onToggle(false)),
          _ToggleOption('Healthy', showHealthy, () => onToggle(true)),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
