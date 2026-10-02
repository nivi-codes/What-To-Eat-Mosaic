class NutritionInfo {
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;

  const NutritionInfo({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG = 0,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> j) => NutritionInfo(
        calories: (j['calories'] as num).toInt(),
        proteinG: (j['proteinG'] as num).toDouble(),
        carbsG: (j['carbsG'] as num).toDouble(),
        fatG: (j['fatG'] as num).toDouble(),
        fiberG: (j['fiberG'] as num? ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
        'fiberG': fiberG,
      };
}

class Recipe {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String mealType; // breakfast, lunch, dinner, snack
  final String path; // cook, order, dine
  final List<String> tags;
  final List<String> healthHighlights;
  final NutritionInfo nutrition;
  final NutritionInfo? healthyNutrition;
  final List<String> ingredients;
  final List<String>? healthyIngredients;
  final List<String> steps;
  final List<String>? healthySteps;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final String cuisineType;
  final bool hasHealthyVersion;

  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.mealType,
    required this.path,
    required this.tags,
    this.healthHighlights = const [],
    required this.nutrition,
    this.healthyNutrition,
    required this.ingredients,
    this.healthyIngredients,
    required this.steps,
    this.healthySteps,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.cuisineType,
    this.hasHealthyVersion = false,
  });

  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;

  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String,
        imageUrl: j['imageUrl'] as String,
        mealType: j['mealType'] as String,
        path: j['path'] as String,
        tags: List<String>.from(j['tags'] as List),
        healthHighlights: List<String>.from(j['healthHighlights'] as List? ?? []),
        nutrition: NutritionInfo.fromJson(j['nutrition'] as Map<String, dynamic>),
        healthyNutrition: j['healthyNutrition'] != null
            ? NutritionInfo.fromJson(j['healthyNutrition'] as Map<String, dynamic>)
            : null,
        ingredients: List<String>.from(j['ingredients'] as List),
        healthyIngredients: j['healthyIngredients'] != null
            ? List<String>.from(j['healthyIngredients'] as List)
            : null,
        steps: List<String>.from(j['steps'] as List),
        healthySteps: j['healthySteps'] != null
            ? List<String>.from(j['healthySteps'] as List)
            : null,
        prepTimeMinutes: (j['prepTimeMinutes'] as num).toInt(),
        cookTimeMinutes: (j['cookTimeMinutes'] as num).toInt(),
        cuisineType: j['cuisineType'] as String,
        hasHealthyVersion: j['hasHealthyVersion'] as bool? ?? false,
      );
}
