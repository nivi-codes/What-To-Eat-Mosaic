import 'package:flutter/foundation.dart';
import '../models/saved_item.dart';
import '../models/suggestion.dart';

class SavedProvider extends ChangeNotifier {
  final List<SavedItem> _items = [];

  List<SavedItem> get items => List.unmodifiable(_items);

  List<SavedItem> byPath(String path) =>
      _items.where((i) => i.path == path).toList();

  bool isSaved(String recipeId) => _items.any((i) => i.recipeId == recipeId);

  void save(Suggestion suggestion) {
    if (isSaved(suggestion.recipeId)) return;
    _items.insert(0, SavedItem(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      recipeId: suggestion.recipeId,
      recipeTitle: suggestion.title,
      imageUrl: suggestion.imageUrl,
      path: suggestion.path,
      mealType: 'meal',
      savedAt: DateTime.now(),
    ));
    notifyListeners();
  }

  void unsave(String recipeId) {
    _items.removeWhere((i) => i.recipeId == recipeId);
    notifyListeners();
  }

  void toggle(Suggestion suggestion) {
    if (isSaved(suggestion.recipeId)) {
      unsave(suggestion.recipeId);
    } else {
      save(suggestion);
    }
  }
}
