import 'package:flutter/foundation.dart';
import '../models/meal_log.dart';
import '../models/recipe.dart';
import '../models/suggestion.dart';
import '../data/mock_data.dart';

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

  /// The next meal of the day, by the clock.
  String get nextMeal {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'breakfast';
    if (hour < 16) return 'lunch';
    return 'dinner';
  }

  /// Today's meals of 500 kcal or more, earliest first.
  List<MealLog> get heavyToday =>
      todayLogs.where((l) => l.nutrition.calories >= 500).toList().reversed.toList();

  // Returns a nudge message if eating pattern warrants one
  String? get nudgeMessage {
    // Evening, no dinner logged yet, after a heavy day: suggest a light dinner.
    final dinnerLogged = todayLogs.any((l) => l.loggedAt.hour >= 17);
    final heavy = heavyToday;
    if (nextMeal == 'dinner' && !dinnerLogged && (heavy.length >= 2 || todayCalories >= 1100)) {
      if (heavy.length >= 2) {
        return "You've had ${heavy[0].recipeTitle} and ${heavy[1].recipeTitle} today. How about something light for dinner?";
      }
      return 'Big day so far. How about something light for dinner?';
    }
    if (todayCalories > 2200) {
      return "Big day so far. Something light for $nextMeal?";
    }
    if (_logs.length >= 3 && _logs.take(3).every((l) => l.nutrition.calories > 500)) {
      return "You've had a few rich meals today. Want a lighter option?";
    }
    return null;
  }

  /// Demo hook (`?demo=heavy-day`): starts today with a heavy breakfast and lunch logged,
  /// so the light-dinner nudge shows without logging them by hand first.
  void seedHeavyDay() {
    if (_logs.isNotEmpty) return;
    final now = DateTime.now();
    for (final m in MockData.heavyDayMeals) {
      final at = DateTime(now.year, now.month, now.day, m['hour'] as int, m['minute'] as int);
      if (at.isAfter(now)) continue;
      _logs.insert(0, MealLog(
        id: 'demo-${m['mealType']}',
        recipeId: 'demo-${m['mealType']}',
        recipeTitle: m['title'] as String,
        mealType: m['mealType'] as String,
        variant: 'regular',
        path: 'cook',
        nutrition: NutritionInfo(
          calories: m['calories'] as int,
          proteinG: (m['protein'] as num).toDouble(),
          carbsG: (m['carbs'] as num).toDouble(),
          fatG: (m['fat'] as num).toDouble(),
        ),
        loggedAt: at,
        imageUrl: m['imageUrl'] as String,
      ));
    }
    notifyListeners();
  }

  // Weekly summary mock data
  List<Map<String, dynamic>> get weekSummary {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final mockCals = [1800, 2200, 1600, 2400, 1900, 2100, todayCalories.clamp(0, 2800)];
    return List.generate(7, (i) => {'day': days[i], 'calories': mockCals[i]});
  }
}
