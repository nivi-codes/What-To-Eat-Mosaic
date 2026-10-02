import 'package:flutter/foundation.dart';
import '../models/meal_log.dart';
import '../models/recipe.dart';
import '../models/suggestion.dart';

class MealLogProvider extends ChangeNotifier {
  final List<MealLog> _logs = [];

  List<MealLog> get logs => List.unmodifiable(_logs);

  List<MealLog> get todayLogs {
    final now = DateTime.now();
    return _logs
        .where((l) =>
            l.loggedAt.year == now.year &&
            l.loggedAt.month == now.month &&
            l.loggedAt.day == now.day)
        .toList();
  }

  int get todayCalories =>
      todayLogs.fold(0, (sum, l) => sum + l.nutrition.calories);

  double get todayProtein =>
      todayLogs.fold(0.0, (sum, l) => sum + l.nutrition.proteinG);

  void logMeal({
    required Suggestion suggestion,
    required String variant,
    Recipe? recipe,
  }) {
    final nutrition = variant == 'healthy' && suggestion.healthyNutrition != null
        ? suggestion.healthyNutrition!
        : suggestion.nutrition;

    final log = MealLog(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      recipeId: suggestion.recipeId,
      recipeTitle: suggestion.title,
      mealType: 'meal',
      variant: variant,
      path: suggestion.path,
      nutrition: nutrition,
      loggedAt: DateTime.now(),
      imageUrl: suggestion.imageUrl,
    );
    _logs.insert(0, log);
    notifyListeners();
  }

  void removeLog(String id) {
    _logs.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  // Returns a nudge message if eating pattern warrants one
  String? get nudgeMessage {
    if (todayCalories > 2200) {
      return "Big day so far. Something light for dinner?";
    }
    if (_logs.length >= 3 && _logs.take(3).every((l) => l.nutrition.calories > 500)) {
      return "You've had a few rich meals today. Want a lighter option?";
    }
    return null;
  }

  // Weekly summary mock data
  List<Map<String, dynamic>> get weekSummary {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final mockCals = [1800, 2200, 1600, 2400, 1900, 2100, todayCalories.clamp(0, 2800)];
    return List.generate(7, (i) => {'day': days[i], 'calories': mockCals[i]});
  }
}
