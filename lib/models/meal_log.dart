import 'recipe.dart';

class MealLog {
  final String id;
  final String recipeId;
  final String recipeTitle;
  final String mealType; // breakfast, lunch, dinner, snack
  final String variant; // regular, healthy
  final String path; // cook, order, dine
  final NutritionInfo nutrition;
  final DateTime loggedAt;
  final String imageUrl;

  const MealLog({
    required this.id,
    required this.recipeId,
    required this.recipeTitle,
    required this.mealType,
    required this.variant,
    required this.path,
    required this.nutrition,
    required this.loggedAt,
    required this.imageUrl,
  });
}
