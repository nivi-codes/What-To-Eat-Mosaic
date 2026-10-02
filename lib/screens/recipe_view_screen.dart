import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../models/recipe.dart';
import '../models/suggestion.dart';
import '../providers/meal_log_provider.dart';
import '../providers/saved_provider.dart';
import '../providers/eat_flow_provider.dart';
import '../providers/preferences_provider.dart';

class RecipeViewScreen extends StatefulWidget {
  const RecipeViewScreen({
    super.key,
    required this.recipeId,
    this.fromCommunity = false,
    this.title,
  });

  final String recipeId;
  final bool fromCommunity;
  // Lets a recipe be regenerated when it's no longer cached (e.g. opened from Saved).
  final String? title;

  @override
  State<RecipeViewScreen> createState() => _RecipeViewScreenState();
}

class _RecipeViewScreenState extends State<RecipeViewScreen> {
  bool? _showHealthy;
  Future<Recipe?>? _pending;

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<EatFlowProvider>();
    Suggestion? suggestion;
    for (final s in flow.suggestions) {
      if (s.recipeId == widget.recipeId) suggestion = s;
    }

    final known = flow.getGeneratedRecipe(widget.recipeId) ?? MockData.getRecipe(widget.recipeId);
    if (known != null) return _buildRecipe(context, known, suggestion);

    final title = suggestion?.title ?? widget.title;
    if (title == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recipe')),
        body: const Center(child: Text('Recipe not found')),
      );
    }

    // Generated on the fly from the user's ingredients (usually already prefetched).
    _pending ??= flow.recipeFor(widget.recipeId, title, imageUrl: suggestion?.imageUrl);
    return FutureBuilder<Recipe?>(
      future: _pending,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _StatusScaffold(
            title: title,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text('Writing your recipe…', style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          );
        }
        final recipe = snap.data;
        if (recipe == null) {
          return _StatusScaffold(
            title: title,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Couldn't write this recipe right now.", style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => setState(() => _pending = null),
                  child: const Text('Try again'),
                ),
              ],
            ),
          );
        }
        return _buildRecipe(context, recipe, suggestion);
      },
    );
  }

  Widget _buildRecipe(BuildContext context, Recipe recipe, Suggestion? currentSuggestion) {
    if (_showHealthy == null) {
      final healthyPref = context.read<PreferencesProvider>().preferences.healthyPreference;
      _showHealthy = healthyPref == 'healthy_first' && recipe.hasHealthyVersion;
    }

    final nutrition = _showHealthy! && recipe.healthyNutrition != null
        ? recipe.healthyNutrition!
        : recipe.nutrition;
    final ingredients = _showHealthy! && recipe.healthyIngredients != null
        ? recipe.healthyIngredients!
        : recipe.ingredients;
    final steps = _showHealthy! && recipe.healthySteps != null
        ? recipe.healthySteps!
        : recipe.steps;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero image app bar
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.arrow_back, color: Colors.white, size: 18),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (currentSuggestion != null)
                Consumer<SavedProvider>(
                  builder: (_, saved, __) => IconButton(
                    icon: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: Icon(
                        saved.isSaved(widget.recipeId) ? Icons.bookmark : Icons.bookmark_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    onPressed: () => saved.toggle(currentSuggestion),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                recipe.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.primaryLight,
                  child: const Icon(Icons.restaurant, color: AppColors.primary, size: 60),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and meta
                  Text(recipe.title, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(recipe.description, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 14),

                  // Meta row
                  Row(
                    children: [
                      _MetaChip(icon: Icons.timer_outlined, label: '${recipe.totalTimeMinutes} min'),
                      const SizedBox(width: 8),
                      _MetaChip(icon: Icons.local_fire_department_outlined, label: '~${nutrition.calories} kcal'),
                      const SizedBox(width: 8),
                      _MetaChip(icon: Icons.restaurant_menu_outlined, label: recipe.cuisineType),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Health highlights
                  if (recipe.healthHighlights.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: recipe.healthHighlights.map((h) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.tagBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(h, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
                      )).toList(),
                    ),

                  // Regular / Healthy toggle
                  if (recipe.hasHealthyVersion) ...[
                    const SizedBox(height: 16),
                    _VersionToggle(
                      showHealthy: _showHealthy!,
                      regularCalories: recipe.nutrition.calories,
                      healthyCalories: recipe.healthyNutrition?.calories,
                      onToggle: (v) => setState(() => _showHealthy = v),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Divider(),

                  // Nutrition row
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _NutritionPill('Protein', '${nutrition.proteinG.toStringAsFixed(0)}g'),
                      const SizedBox(width: 8),
                      _NutritionPill('Carbs', '${nutrition.carbsG.toStringAsFixed(0)}g'),
                      const SizedBox(width: 8),
                      _NutritionPill('Fat', '${nutrition.fatG.toStringAsFixed(0)}g'),
                      const SizedBox(width: 8),
                      _NutritionPill('Fibre', '${nutrition.fiberG.toStringAsFixed(0)}g'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),

                  // Ingredients
                  const SizedBox(height: 16),
                  Text('Ingredients', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  ...ingredients.map((ing) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        Expanded(child: Text(ing, style: Theme.of(context).textTheme.bodyLarge)),
                      ],
                    ),
                  )),

                  const SizedBox(height: 20),
                  const Divider(),

                  // Steps
                  const SizedBox(height: 16),
                  Text('Method', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  ...steps.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${e.key + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(e.value, style: Theme.of(context).textTheme.bodyLarge),
                          ),
                        ),
                      ],
                    ),
                  )),

                  const SizedBox(height: 100), // space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: !widget.fromCommunity
          ? FloatingActionButton.extended(
              onPressed: () {
                if (currentSuggestion != null) {
                  context.read<MealLogProvider>().logMeal(
                    suggestion: currentSuggestion,
                    variant: _showHealthy! ? 'healthy' : 'regular',
                    recipe: recipe,
                  );
                }
                context.read<EatFlowProvider>().reset();
                context.go('/eat');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Meal logged!'),
                    backgroundColor: AppColors.primary,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('I\'m having this', style: TextStyle(color: Colors.white)),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _StatusScaffold extends StatelessWidget {
  const _StatusScaffold({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: Center(child: Padding(padding: const EdgeInsets.all(24), child: child)),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tagBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _NutritionPill extends StatelessWidget {
  const _NutritionPill(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.tagBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _VersionToggle extends StatelessWidget {
  const _VersionToggle({
    required this.showHealthy,
    required this.regularCalories,
    this.healthyCalories,
    required this.onToggle,
  });

  final bool showHealthy;
  final int regularCalories;
  final int? healthyCalories;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.tagBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _ToggleBtn('Regular', '~${regularCalories} kcal', !showHealthy, () => onToggle(false))),
          Expanded(child: _ToggleBtn('Healthy', healthyCalories != null ? '~$healthyCalories kcal' : '', showHealthy, () => onToggle(true))),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn(this.label, this.sublabel, this.active, this.onTap);
  final String label;
  final String sublabel;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)]
              : [],
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: active ? AppColors.primary : AppColors.textMuted)),
            if (sublabel.isNotEmpty)
              Text(sublabel, style: TextStyle(fontSize: 11, color: active ? AppColors.accent : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
