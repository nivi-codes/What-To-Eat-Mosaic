class SavedItem {
  final String id;
  final String recipeId;
  final String recipeTitle;
  final String imageUrl;
  final String path; // cook, order, dine
  final String mealType;
  final DateTime savedAt;

  const SavedItem({
    required this.id,
    required this.recipeId,
    required this.recipeTitle,
    required this.imageUrl,
    required this.path,
    required this.mealType,
    required this.savedAt,
  });
}
