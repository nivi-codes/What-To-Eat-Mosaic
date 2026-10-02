class UserPreferences {
  final String dietaryType; // veg, non-veg, vegan, eggetarian
  final List<String> cuisines;
  final List<String> flavours;
  final List<String> avoidances;
  final String healthyPreference; // healthy_first, regular_first, both
  final String inputMode; // voice, tap

  const UserPreferences({
    this.dietaryType = 'non-veg',
    this.cuisines = const [],
    this.flavours = const [],
    this.avoidances = const [],
    this.healthyPreference = 'both',
    this.inputMode = 'tap',
  });

  UserPreferences copyWith({
    String? dietaryType,
    List<String>? cuisines,
    List<String>? flavours,
    List<String>? avoidances,
    String? healthyPreference,
    String? inputMode,
  }) {
    return UserPreferences(
      dietaryType: dietaryType ?? this.dietaryType,
      cuisines: cuisines ?? this.cuisines,
      flavours: flavours ?? this.flavours,
      avoidances: avoidances ?? this.avoidances,
      healthyPreference: healthyPreference ?? this.healthyPreference,
      inputMode: inputMode ?? this.inputMode,
    );
  }
}
