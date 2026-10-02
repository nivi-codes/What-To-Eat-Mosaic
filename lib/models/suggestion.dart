import 'recipe.dart';

class Suggestion {
  final String id;
  final String title;
  final String subtitle; // e.g. "30 min · Veg · North Indian"
  final String path; // cook, order, dine
  final String imageUrl;
  final NutritionInfo nutrition;
  final NutritionInfo? healthyNutrition;
  final bool hasHealthyVersion;
  final List<String> healthHighlights;
  final List<String> tags;
  final String recipeId; // reference to full recipe

  bool get isRestaurant => path == 'dine';

  const Suggestion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.path,
    required this.imageUrl,
    required this.nutrition,
    this.healthyNutrition,
    this.hasHealthyVersion = false,
    this.healthHighlights = const [],
    this.tags = const [],
    required this.recipeId,
  });

  factory Suggestion.fromJson(Map<String, dynamic> j) => Suggestion(
        id: j['id'] as String,
        title: j['title'] as String,
        subtitle: j['subtitle'] as String,
        path: j['path'] as String,
        imageUrl: j['imageUrl'] as String,
        // Dine-out (restaurant) suggestions carry no nutrition.
        nutrition: j['nutrition'] is Map<String, dynamic>
            ? NutritionInfo.fromJson(j['nutrition'] as Map<String, dynamic>)
            : const NutritionInfo(calories: 0, proteinG: 0, carbsG: 0, fatG: 0),
        healthyNutrition: j['healthyNutrition'] != null
            ? NutritionInfo.fromJson(j['healthyNutrition'] as Map<String, dynamic>)
            : null,
        hasHealthyVersion: j['hasHealthyVersion'] as bool? ?? false,
        healthHighlights: List<String>.from(j['healthHighlights'] as List? ?? []),
        tags: List<String>.from(j['tags'] as List? ?? []),
        recipeId: j['recipeId'] as String? ?? j['id'] as String,
      );
}
