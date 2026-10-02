import 'package:flutter/foundation.dart';
import '../models/user_preferences.dart';

class PreferencesProvider extends ChangeNotifier {
  bool _isOnboarded = false;
  UserPreferences _preferences = const UserPreferences();

  bool get isOnboarded => _isOnboarded;
  UserPreferences get preferences => _preferences;

  void setDietaryType(String value) {
    _preferences = _preferences.copyWith(dietaryType: value);
    notifyListeners();
  }

  void setCuisines(List<String> value) {
    _preferences = _preferences.copyWith(cuisines: value);
    notifyListeners();
  }

  void setFlavours(List<String> value) {
    _preferences = _preferences.copyWith(flavours: value);
    notifyListeners();
  }

  void setAvoidances(List<String> value) {
    _preferences = _preferences.copyWith(avoidances: value);
    notifyListeners();
  }

  void setHealthyPreference(String value) {
    _preferences = _preferences.copyWith(healthyPreference: value);
    notifyListeners();
  }

  void setInputMode(String value) {
    _preferences = _preferences.copyWith(inputMode: value);
    notifyListeners();
  }

  void completeOnboarding() {
    _isOnboarded = true;
    notifyListeners();
  }

  void resetOnboarding() {
    _isOnboarded = false;
    _preferences = const UserPreferences();
    notifyListeners();
  }

  String get preferencesSummary {
    final parts = <String>[];
    if (_preferences.dietaryType.isNotEmpty) {
      parts.add(_capitalize(_preferences.dietaryType));
    }
    if (_preferences.cuisines.isNotEmpty) {
      parts.add('Loves ${_preferences.cuisines.take(2).join(' & ')}');
    }
    if (_preferences.flavours.isNotEmpty) {
      parts.add('Usually ${_preferences.flavours.take(2).join(' & ')}');
    }
    if (_preferences.healthyPreference == 'healthy_first') {
      parts.add('Healthy options first');
    }
    return parts.isEmpty ? 'No preferences set yet' : parts.join(' · ');
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).replaceAll('-', ' ')}';
}
