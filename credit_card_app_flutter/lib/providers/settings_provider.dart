import 'package:flutter/foundation.dart';
import '../models/user_preferences.dart';
import '../models/point_type.dart';
import '../services/data_manager.dart';

class SettingsProvider extends ChangeNotifier {
  final DataManager _dataManager;

  UserPreferences _preferences = UserPreferences();
  bool _hasCompletedOnboarding = false;

  SettingsProvider(this._dataManager) {
    _load();
  }

  UserPreferences get preferences => _preferences;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get useApplePay => _preferences.useApplePay;
  bool get notificationsEnabled => _preferences.notificationsEnabled;
  PointType get preferredPointSystem => _preferences.preferredPointSystem;

  Future<void> _load() async {
    _preferences = await _dataManager.loadUserPreferences();
    _hasCompletedOnboarding = await _dataManager.hasCompletedOnboarding();
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    await _dataManager.completeOnboarding();
    notifyListeners();
  }

  Future<void> toggleApplePay() async {
    _preferences.useApplePay = !_preferences.useApplePay;
    await _dataManager.saveUserPreferences(_preferences);
    notifyListeners();
  }

  Future<void> toggleNotifications() async {
    _preferences.notificationsEnabled = !_preferences.notificationsEnabled;
    await _dataManager.saveUserPreferences(_preferences);
    notifyListeners();
  }

  Future<void> setPreferredPointSystem(PointType type) async {
    _preferences.preferredPointSystem = type;
    await _dataManager.saveUserPreferences(_preferences);
    notifyListeners();
  }

  Future<void> setLanguage(Language lang) async {
    _preferences.language = lang;
    await _dataManager.saveUserPreferences(_preferences);
    notifyListeners();
  }
}
