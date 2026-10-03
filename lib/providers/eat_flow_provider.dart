import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/menu.dart';
import '../models/suggestion.dart';
import '../models/recipe.dart';
import '../models/user_preferences.dart';
import '../data/mock_data.dart';
import '../services/food_ai_service.dart';
import '../services/intent_service.dart';

enum EatFlowStep {
  idle,
  freeInput,        // voice/text free-form input
  selectMealType,
  selectFlavour,
  selectMethod,
  pathCookIngredients,
  pathCookTime,
  pathOrderCuisine,
  pathDineVibe,
  loading,
  done,
  error,
}

class EatFlowProvider extends ChangeNotifier {
  EatFlowStep _currentStep = EatFlowStep.idle;
  bool _isVoiceMode = true; // voice is default

  String? _mealType;
  List<String> _flavours = [];
  String? _method;
  List<String> _ingredients = [];
  String? _cookTime;
  String? _cuisinePreference;
  String? _dineVibe;
  List<Suggestion> _suggestions = [];
  String? _errorMessage;
  String _freeInputText = '';
  bool _understanding = false; // waiting on LLM intent extraction
  UserPreferences? _preferences;

  // Store LLM-generated recipes so RecipeViewScreen can access them
  final Map<String, Recipe> _generatedRecipes = {};

  // Getters
  EatFlowStep get currentStep => _currentStep;
  EatFlowStep get step => _currentStep;
  bool get isVoiceMode => _isVoiceMode;
  String? get mealType => _mealType;
  List<String> get flavours => _flavours;
  String? get method => _method;
  List<String> get ingredients => _ingredients;
  String? get cookTime => _cookTime;
  String? get cuisinePreference => _cuisinePreference;
  String? get dineVibe => _dineVibe;
  List<Suggestion> get suggestions => _suggestions;
  String? get errorMessage => _errorMessage;
  String get freeInputText => _freeInputText;
  Map<String, Recipe> get generatedRecipes => _generatedRecipes;
  bool get isUnderstanding => _understanding;
  UserPreferences? get preferences => _preferences;

  /// LLM recipe for a suggestion, built around the user's ingredients (shared/cached).
  Future<Recipe?> recipeFor(String recipeId, String title, {String? imageUrl}) => FoodAiService.recipe(
        id: recipeId,
        title: title,
        imageUrl: imageUrl,
        ingredients: _ingredients,
        mealType: _mealType,
        flavours: _flavours,
        cookTime: _cookTime,
        preferences: _preferences,
        card: _suggestions.where((s) => s.recipeId == recipeId).firstOrNull,
      );

  /// LLM "what to order here" menu for a restaurant suggestion (shared/cached).
  Future<List<MenuSection>?> menuFor(String id, String name, {String? cuisine}) => FoodAiService.menu(
        id: id,
        name: name,
        cuisine: cuisine,
        mealType: _mealType,
        flavours: _flavours,
        preferences: _preferences,
      );

  // Start generating details in the background so they're ready (or nearly) on tap.
  void _prefetchDetails() {
    for (final s in _suggestions) {
      if (s.path == 'cook' && MockData.getRecipe(s.recipeId) == null) {
        recipeFor(s.recipeId, s.title, imageUrl: s.imageUrl);
      } else if (s.isRestaurant) {
        menuFor(s.recipeId, s.title, cuisine: s.subtitle.split('·').first.trim());
      }
    }
  }

  /// Get a generated recipe by ID (from LLM API)
  Recipe? getGeneratedRecipe(String id) => _generatedRecipes[id];

  int get totalSteps {
    switch (_method) {
      case 'cook': return 5;
      case 'order': return 4;
      case 'dine': return 4;
      default: return 3;
    }
  }

  int get currentStepIndex {
    switch (_currentStep) {
      case EatFlowStep.idle:
      case EatFlowStep.freeInput: return 0;
      case EatFlowStep.selectMealType: return 1;
      case EatFlowStep.selectFlavour: return 2;
      case EatFlowStep.selectMethod: return 3;
      case EatFlowStep.pathCookIngredients:
      case EatFlowStep.pathOrderCuisine:
      case EatFlowStep.pathDineVibe: return 4;
      case EatFlowStep.pathCookTime: return 5;
      case EatFlowStep.loading:
      case EatFlowStep.done:
      case EatFlowStep.error: return totalSteps;
    }
  }

  void startSession({required bool voiceMode, UserPreferences? preferences}) {
    _isVoiceMode = voiceMode;
    _preferences = preferences;
    _understanding = false;
    _currentStep = EatFlowStep.freeInput;
    _mealType = null;
    _flavours = [];
    _method = null;
    _ingredients = [];
    _cookTime = null;
    _cuisinePreference = null;
    _dineVibe = null;
    _suggestions = [];
    _errorMessage = null;
    _freeInputText = '';
    _generatedRecipes.clear();
    notifyListeners();
  }

  /// From the "something light?" nudge: straight to light, quick home-cooked picks.
  void startLightMeal({required String mealType, UserPreferences? preferences, List<String> heavyMeals = const []}) {
    startSession(voiceMode: false, preferences: preferences);
    _mealType = mealType;
    _flavours = ['light'];
    _method = 'cook';
    _cookTime = '20 minutes';
    _freeInputText = 'Something light and easy on the stomach for $mealType'
        '${heavyMeals.isEmpty ? '' : ', after ${heavyMeals.join(' and ')} earlier today'}';
    _fetchSuggestions();
  }

  void toggleInputMode() {
    _isVoiceMode = !_isVoiceMode;
    notifyListeners();
  }

  /// Understands free-form input with the LLM, applies what was detected,
  /// then advances to the first unanswered question.
  /// [live] is the screen's last live-preview result for the same words; it fills only
  /// the answers the precise pass happens to drop.
  Future<void> submitFreeInput(String text, {Map<String, dynamic> live = const {}}) async {
    if (_understanding) return;
    _freeInputText = text;
    _understanding = true;
    notifyListeners();

    final precise = await IntentService.extract('eat_flow', text, precise: true);
    final detected = precise != null ? {...live, ...precise} : analyzeTranscript(text);
    _understanding = false;
    if (_currentStep != EatFlowStep.freeInput) return; // session reset/closed meanwhile
    _applyDetected(detected);
    _advanceToNextUnanswered();
    notifyListeners();
  }

  /// Offline fallback only (used when the LLM is unreachable) — keyword matching.
  static Map<String, dynamic> analyzeTranscript(String text) {
    final lower = text.toLowerCase();
    final result = <String, dynamic>{};

    // Meal type
    if (lower.contains('breakfast')) result['mealType'] = 'breakfast';
    else if (lower.contains('lunch')) result['mealType'] = 'lunch';
    else if (lower.contains('snack')) result['mealType'] = 'snack';
    else if (lower.contains('dinner')) result['mealType'] = 'dinner';

    // Flavours
    final flavours = <String>[];
    final flavourMap = {
      'spicy': 'Spicy', 'light': 'Light', 'comfort': 'Comforting',
      'sweet': 'Sweet', 'fresh': 'Fresh', 'rich': 'Rich',
      'tangy': 'Tangy', 'smoky': 'Smoky',
    };
    for (final e in flavourMap.entries) {
      if (lower.contains(e.key)) flavours.add(e.value);
    }
    if (flavours.isNotEmpty) result['flavours'] = flavours;

    // Method
    if (lower.contains('cook') || lower.contains('make') || lower.contains('prepare') || lower.contains('home')) {
      result['method'] = 'cook';
    } else if (lower.contains('order') || lower.contains('deliver') || lower.contains('swiggy') || lower.contains('zomato')) {
      result['method'] = 'order';
    } else if (lower.contains('dine') || lower.contains('eat out') || lower.contains('restaurant') || lower.contains('go out')) {
      result['method'] = 'dine';
    }

    // Ingredients
    final ingredients = <String>[];
    final ingKeywords = [
      'rice', 'atta', 'bread', 'poha', 'oats', 'noodles',
      'dal', 'paneer', 'eggs', 'chicken', 'tofu', 'curd',
      'onion', 'tomato', 'potato', 'spinach', 'capsicum', 'peas',
      'mushroom', 'corn', 'cheese', 'fish', 'mutton', 'prawns',
    ];
    for (final ing in ingKeywords) {
      if (lower.contains(ing)) {
        ingredients.add(ing[0].toUpperCase() + ing.substring(1));
      }
    }
    if (ingredients.isNotEmpty) result['ingredients'] = ingredients;

    // Cook time
    if (lower.contains('15 min') || lower.contains('quick') || lower.contains('fast')) {
      result['cookTime'] = '15 minutes';
    } else if (lower.contains('30 min') || lower.contains('half hour')) {
      result['cookTime'] = '30 minutes';
    } else if (lower.contains('45 min')) {
      result['cookTime'] = '45 minutes';
    } else if (lower.contains('any time') || lower.contains('no rush') || lower.contains('don\'t mind')) {
      result['cookTime'] = 'Any time';
    }

    // Cuisine
    if (lower.contains('north indian') || lower.contains('punjabi')) {
      result['cuisine'] = 'North Indian';
    } else if (lower.contains('south indian')) {
      result['cuisine'] = 'South Indian';
    } else if (lower.contains('chinese') || lower.contains('indo chinese')) {
      result['cuisine'] = 'Chinese';
    } else if (lower.contains('italian') || lower.contains('pasta') || lower.contains('pizza')) {
      result['cuisine'] = 'Italian';
    }

    // Vibe
    if (lower.contains('casual') || lower.contains('chill')) {
      result['vibe'] = 'casual';
    } else if (lower.contains('quick bite') || lower.contains('grab a bite')) {
      result['vibe'] = 'quick bite';
    } else if (lower.contains('special') || lower.contains('fancy') || lower.contains('date')) {
      result['vibe'] = 'something special';
    }

    return result;
  }

  /// Returns list of remaining question labels based on what's NOT yet answered.
  /// Used by voice UI to show dynamic nudge chips.
  static List<String> getRemainingQuestions(Map<String, dynamic> detected) {
    final questions = <String>[];
    if (!detected.containsKey('mealType')) questions.add('What meal?');
    if (!detected.containsKey('flavours')) questions.add('What flavour?');
    if (!detected.containsKey('method')) questions.add('Cook, order, or dine?');

    // Path-specific questions only if method is detected
    if (detected.containsKey('method')) {
      final method = detected['method'] as String;
      if (method == 'cook') {
        if (!detected.containsKey('ingredients')) questions.add('What ingredients?');
        if (!detected.containsKey('cookTime')) questions.add('How much time?');
      } else if (method == 'order') {
        if (!detected.containsKey('cuisine')) questions.add('Any cuisine?');
      } else if (method == 'dine') {
        if (!detected.containsKey('vibe')) questions.add('What vibe?');
      }
    }
    return questions;
  }

  void _applyDetected(Map<String, dynamic> detected) {
    if (detected.containsKey('mealType')) _mealType = detected['mealType'];
    if (detected.containsKey('flavours')) _flavours = List<String>.from(detected['flavours']);
    if (detected.containsKey('method')) _method = detected['method'];
    if (detected.containsKey('ingredients')) _ingredients = List<String>.from(detected['ingredients']);
    if (detected.containsKey('cookTime')) _cookTime = detected['cookTime'];
    if (detected.containsKey('cuisine')) _cuisinePreference = detected['cuisine'];
    if (detected.containsKey('vibe')) _dineVibe = detected['vibe'];
  }

  void _advanceToNextUnanswered() {
    if (_mealType == null) {
      _currentStep = EatFlowStep.selectMealType;
      return;
    }
    if (_flavours.isEmpty) {
      _currentStep = EatFlowStep.selectFlavour;
      return;
    }
    if (_method == null) {
      _currentStep = EatFlowStep.selectMethod;
      return;
    }
    // Path-specific
    switch (_method) {
      case 'cook':
        if (_ingredients.isEmpty) {
          _currentStep = EatFlowStep.pathCookIngredients;
          return;
        }
        if (_cookTime == null) {
          _currentStep = EatFlowStep.pathCookTime;
          return;
        }
      case 'order':
        if (_cuisinePreference == null) {
          _currentStep = EatFlowStep.pathOrderCuisine;
          return;
        }
      case 'dine':
        if (_dineVibe == null) {
          _currentStep = EatFlowStep.pathDineVibe;
          return;
        }
    }
    // All answered
    _fetchSuggestions();
  }

  void setMealType(String value) {
    _mealType = value;
    _advanceToNextUnanswered();
    notifyListeners();
  }

  void setFlavours(List<String> value) {
    _flavours = value;
    _advanceToNextUnanswered();
    notifyListeners();
  }

  void setFlavour(String value) {
    _flavours = [value];
    _advanceToNextUnanswered();
    notifyListeners();
  }

  void setMethod(String value) {
    _method = value;
    _advanceToNextUnanswered();
    notifyListeners();
  }

  void setIngredients(List<String> value) {
    _ingredients = value;
    _advanceToNextUnanswered();
    notifyListeners();
  }

  /// Understands a spoken/typed ingredient list ("some leftover rice, two eggs
  /// and half a cabbage") with the LLM; falls back to splitting on commas/"and".
  Future<void> setIngredientsFromText(String text) async {
    if (_understanding) return;
    _understanding = true;
    notifyListeners();

    final detected = await IntentService.extract('ingredients', text, precise: true);
    _understanding = false;
    if (_currentStep != EatFlowStep.pathCookIngredients) return;
    final fromLlm = detected?['ingredients'] is List ? List<String>.from(detected!['ingredients']) : <String>[];
    _ingredients = fromLlm.isNotEmpty
        ? fromLlm
        : text
            .split(RegExp(r'[,\n]+|\band\b'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
    _advanceToNextUnanswered();
    notifyListeners();
  }

  void setCookTime(String value) {
    _cookTime = value;
    _advanceToNextUnanswered();
    notifyListeners();
  }

  void setCuisinePreference(String value) {
    _cuisinePreference = value;
    _advanceToNextUnanswered();
    notifyListeners();
  }

  void setCuisine(String value) => setCuisinePreference(value);

  void setDineVibe(String value) {
    _dineVibe = value;
    _advanceToNextUnanswered();
    notifyListeners();
  }

  void setVibe(String value) => setDineVibe(value);

  Future<void> _fetchSuggestions() async {
    _currentStep = EatFlowStep.loading;
    notifyListeners();

    // Try API first
    try {
      final apiSuggestions = await _fetchFromApi();
      if (apiSuggestions != null && apiSuggestions.isNotEmpty) {
        _suggestions = apiSuggestions;
        _currentStep = EatFlowStep.done;
        _prefetchDetails();
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('API call failed, using mock data: $e');
    }

    // Offline fallback
    await Future.delayed(const Duration(milliseconds: 1500));
    _applyOfflineSuggestions();
    notifyListeners();
  }

  void _applyOfflineSuggestions() {
    final pool = _dietFiltered(MockData.getAllSuggestions(method: _method ?? 'cook'))..shuffle();
    if (pool.isEmpty) {
      _errorMessage = "Couldn't load suggestions. Check your connection and try again.";
      _currentStep = EatFlowStep.error;
      return;
    }
    _suggestions = pool.take(3).toList();
    _currentStep = EatFlowStep.done;
  }

  // Diet rules (vegan -> vegan; vegetarian -> veg/vegan; eggetarian -> egg/veg/vegan;
  // non-veg -> anything). Offline mock data only carries veg/egg/non-veg tags.
  List<Suggestion> _dietFiltered(List<Suggestion> items) {
    if (_method == 'dine') return List.of(items);
    final diet = (_preferences?.dietaryType ?? '').toLowerCase();
    bool allowed(Suggestion s) {
      final tags = s.tags.map((t) => t.toLowerCase()).toSet();
      if (diet.contains('vegan')) return tags.contains('vegan');
      if (diet.contains('egg')) return !tags.contains('non-veg');
      if (diet.contains('non')) return true;
      if (diet.contains('veg')) return !tags.contains('non-veg') && !tags.contains('eggetarian');
      return true;
    }
    return items.where(allowed).toList();
  }

  Future<List<Suggestion>?> _fetchFromApi() async {
    try {
      final uri = Uri.parse('/api/suggestions');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mealType': _mealType,
          'flavour': _flavours.isNotEmpty ? _flavours.join(', ') : null,
          'method': _method ?? 'cook',
          'ingredients': _ingredients,
          'cookTime': _cookTime,
          'cuisinePreference': _cuisinePreference,
          'dineVibe': _dineVibe,
          'freeInput': _freeInputText,
          if (_preferences != null)
            'preferences': {
              'dietaryType': _preferences!.dietaryType,
              'avoidances': _preferences!.avoidances,
            },
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.length >= 3) {
          final suggestions = <Suggestion>[];
          for (final item in data) {
            final j = item as Map<String, dynamic>;
            suggestions.add(Suggestion.fromJson(j));

            // If the API returned embedded recipe data, store it
            if (j.containsKey('recipe') && j['recipe'] != null) {
              final recipe = Recipe.fromJson(j['recipe'] as Map<String, dynamic>);
              _generatedRecipes[recipe.id] = recipe;
            }
          }
          return suggestions;
        }
      }
    } catch (e) {
      debugPrint('API fetch error: $e');
    }
    return null;
  }

  Future<void> refreshSuggestions() async {
    _currentStep = EatFlowStep.loading;
    notifyListeners();

    // Try API with slight variation
    try {
      final apiSuggestions = await _fetchFromApi();
      if (apiSuggestions != null && apiSuggestions.isNotEmpty) {
        _suggestions = apiSuggestions;
        _currentStep = EatFlowStep.done;
        _prefetchDetails();
        notifyListeners();
        return;
      }
    } catch (_) {}

    // Offline fallback
    await Future.delayed(const Duration(milliseconds: 800));
    _applyOfflineSuggestions();
    notifyListeners();
  }

  void shuffleAll() => refreshSuggestions();

  void replaceSuggestion(int index) {
    if (_suggestions.isNotEmpty) {
      _suggestions = List.from(_suggestions);
      final allSuggestions = _dietFiltered(MockData.getAllSuggestions(method: _method ?? 'cook'));
      if (allSuggestions.isEmpty) return;
      // Pick one that's not already shown
      for (final s in allSuggestions) {
        if (!_suggestions.any((existing) => existing.id == s.id)) {
          _suggestions[index] = s;
          notifyListeners();
          return;
        }
      }
      _suggestions[index] = allSuggestions[index % allSuggestions.length];
      notifyListeners();
    }
  }

  void goBack() {
    switch (_currentStep) {
      case EatFlowStep.selectMealType: _currentStep = EatFlowStep.freeInput;
      case EatFlowStep.selectFlavour: _currentStep = EatFlowStep.selectMealType;
      case EatFlowStep.selectMethod: _currentStep = EatFlowStep.selectFlavour;
      case EatFlowStep.pathCookIngredients:
      case EatFlowStep.pathOrderCuisine:
      case EatFlowStep.pathDineVibe: _currentStep = EatFlowStep.selectMethod;
      case EatFlowStep.pathCookTime: _currentStep = EatFlowStep.pathCookIngredients;
      default: break;
    }
    notifyListeners();
  }

  void reset() {
    _currentStep = EatFlowStep.idle;
    _understanding = false;
    _mealType = null;
    _flavours = [];
    _method = null;
    _ingredients = [];
    _cookTime = null;
    _cuisinePreference = null;
    _dineVibe = null;
    _suggestions = [];
    _errorMessage = null;
    _freeInputText = '';
    _generatedRecipes.clear();
    notifyListeners();
  }
}
