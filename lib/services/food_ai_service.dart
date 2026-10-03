import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/menu.dart';
import '../models/recipe.dart';
import '../models/suggestion.dart';
import '../models/user_preferences.dart';

/// On-the-fly LLM generation of recipes (/api/recipe) and restaurant menus (/api/menu).
/// In-flight futures are shared, so a background prefetch and a user tap reuse one call.
class FoodAiService {
  static final Map<String, Future<Recipe?>> _recipes = {};
  static final Map<String, Future<List<MenuSection>?>> _menus = {};

  static Map<String, dynamic> _prefsJson(UserPreferences? p) => p == null
      ? {}
      : {'dietaryType': p.dietaryType, 'avoidances': p.avoidances};

  // What the suggestion card already showed ("15 min · Veg · Indo-Chinese", kcal),
  // so the generated recipe matches it.
  static Map<String, dynamic>? _cardJson(Suggestion? s) {
    if (s == null) return null;
    final parts = s.subtitle.split('·').map((p) => p.trim()).toList();
    return {
      'minutes': int.tryParse(parts.first.split(' ').first),
      'cuisine': parts.length >= 3 ? parts.last : null,
      'calories': s.nutrition.calories,
      if (s.hasHealthyVersion && s.healthyNutrition != null) 'healthyCalories': s.healthyNutrition!.calories,
    };
  }

  static Future<Recipe?> recipe({
    required String id,
    required String title,
    String? imageUrl,
    List<String> ingredients = const [],
    String? mealType,
    List<String> flavours = const [],
    String? cookTime,
    UserPreferences? preferences,
    Suggestion? card,
  }) {
    return _recipes[id] ??= _post('/api/recipe', {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'ingredients': ingredients,
      'mealType': mealType,
      'flavours': flavours,
      'cookTime': cookTime,
      'preferences': _prefsJson(preferences),
      'card': _cardJson(card),
    }, (j) => Recipe.fromJson(j)).then((r) {
      if (r == null) _recipes.remove(id); // allow retry
      return r;
    });
  }

  static Future<List<MenuSection>?> menu({
    required String id,
    required String name,
    String? cuisine,
    String? mealType,
    List<String> flavours = const [],
    UserPreferences? preferences,
  }) {
    return _menus[id] ??= _post('/api/menu', {
      'name': name,
      'cuisine': cuisine,
      'mealType': mealType,
      'flavours': flavours,
      'preferences': _prefsJson(preferences),
    }, (j) => (j['sections'] as List)
        .map((s) => MenuSection.fromJson(s as Map<String, dynamic>))
        .toList()).then((m) {
      if (m == null) _menus.remove(id);
      return m;
    });
  }

  static Future<T?> _post<T>(String path, Map<String, dynamic> body, T Function(Map<String, dynamic>) parse) async {
    try {
      final res = await http
          .post(Uri.parse(path), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 45));
      if (res.statusCode != 200) {
        debugPrint('$path failed: ${res.statusCode}');
        return null;
      }
      return parse(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('$path error: $e');
      return null;
    }
  }
}
