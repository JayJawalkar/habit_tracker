import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  static const String _calorieGoalKey = 'calorie_goal';
  static const int _defaultCalorieGoal = 2200;

  // Notification timing keys
  static const String _breakfastTimeKey = 'breakfast_time';
  static const String _lunchTimeKey = 'lunch_time';
  static const String _dinnerTimeKey = 'dinner_time';
  static const String _gymTimeKey = 'gym_time';
  static const String _waterRemindersEnabledKey = 'water_reminders_enabled';
  static const String _mealRemindersEnabledKey = 'meal_reminders_enabled';
  static const String _gymReminderEnabledKey = 'gym_reminder_enabled';

  // Default times
  static const String _defaultBreakfastTime = '08:00';
  static const String _defaultLunchTime = '12:30';
  static const String _defaultDinnerTime = '19:00';
  static const String _defaultGymTime = '06:00';

  late SharedPreferences _prefs;
  bool _initialized = false;

  factory PreferencesService() {
    return _instance;
  }

  PreferencesService._internal();

  /// Initialize the preferences service
  Future<void> init() async {
    if (_initialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      developer.log(
        'PreferencesService initialized successfully',
        name: 'PreferencesService',
      );
    } catch (e) {
      developer.log(
        'Error initializing PreferencesService: $e',
        name: 'PreferencesService',
        error: e,
      );
      rethrow;
    }
  }

  /// Get the current calorie goal
  int getCalorieGoal() {
    if (!_initialized) {
      return _defaultCalorieGoal;
    }
    return _prefs.getInt(_calorieGoalKey) ?? _defaultCalorieGoal;
  }

  /// Set the calorie goal
  Future<bool> setCalorieGoal(int goal) async {
    if (!_initialized) {
      await init();
    }
    if (goal <= 0) {
      return false;
    }
    return await _prefs.setInt(_calorieGoalKey, goal);
  }

  /// Reset to default calorie goal
  Future<bool> resetCalorieGoal() async {
    if (!_initialized) {
      await init();
    }
    return await _prefs.remove(_calorieGoalKey);
  }

  // ===== Meal Timings =====

  /// Get breakfast time
  String getBreakfastTime() {
    if (!_initialized) {
      return _defaultBreakfastTime;
    }
    return _prefs.getString(_breakfastTimeKey) ?? _defaultBreakfastTime;
  }

  /// Set breakfast time (format: HH:mm)
  Future<bool> setBreakfastTime(String time) async {
    if (!_initialized) {
      await init();
    }
    try {
      _validateTimeFormat(time);
      return await _prefs.setString(_breakfastTimeKey, time);
    } catch (e) {
      developer.log(
        'Error setting breakfast time: $e',
        name: 'PreferencesService',
        error: e,
      );
      return false;
    }
  }

  /// Get lunch time
  String getLunchTime() {
    if (!_initialized) {
      return _defaultLunchTime;
    }
    return _prefs.getString(_lunchTimeKey) ?? _defaultLunchTime;
  }

  /// Set lunch time (format: HH:mm)
  Future<bool> setLunchTime(String time) async {
    if (!_initialized) {
      await init();
    }
    try {
      _validateTimeFormat(time);
      return await _prefs.setString(_lunchTimeKey, time);
    } catch (e) {
      developer.log(
        'Error setting lunch time: $e',
        name: 'PreferencesService',
        error: e,
      );
      return false;
    }
  }

  /// Get dinner time
  String getDinnerTime() {
    if (!_initialized) {
      return _defaultDinnerTime;
    }
    return _prefs.getString(_dinnerTimeKey) ?? _defaultDinnerTime;
  }

  /// Set dinner time (format: HH:mm)
  Future<bool> setDinnerTime(String time) async {
    if (!_initialized) {
      await init();
    }
    try {
      _validateTimeFormat(time);
      return await _prefs.setString(_dinnerTimeKey, time);
    } catch (e) {
      developer.log(
        'Error setting dinner time: $e',
        name: 'PreferencesService',
        error: e,
      );
      return false;
    }
  }

  // ===== Gym Timing =====

  /// Get gym time
  String getGymTime() {
    if (!_initialized) {
      return _defaultGymTime;
    }
    return _prefs.getString(_gymTimeKey) ?? _defaultGymTime;
  }

  /// Set gym time (format: HH:mm)
  Future<bool> setGymTime(String time) async {
    if (!_initialized) {
      await init();
    }
    try {
      _validateTimeFormat(time);
      return await _prefs.setString(_gymTimeKey, time);
    } catch (e) {
      developer.log(
        'Error setting gym time: $e',
        name: 'PreferencesService',
        error: e,
      );
      return false;
    }
  }

  // ===== Notification Preferences =====

  /// Check if water reminders are enabled
  bool isWaterRemindersEnabled() {
    if (!_initialized) {
      return true; // Default enabled
    }
    return _prefs.getBool(_waterRemindersEnabledKey) ?? true;
  }

  /// Set water reminders enabled state
  Future<bool> setWaterRemindersEnabled(bool enabled) async {
    if (!_initialized) {
      await init();
    }
    return await _prefs.setBool(_waterRemindersEnabledKey, enabled);
  }

  /// Check if meal reminders are enabled
  bool isMealRemindersEnabled() {
    if (!_initialized) {
      return true; // Default enabled
    }
    return _prefs.getBool(_mealRemindersEnabledKey) ?? true;
  }

  /// Set meal reminders enabled state
  Future<bool> setMealRemindersEnabled(bool enabled) async {
    if (!_initialized) {
      await init();
    }
    return await _prefs.setBool(_mealRemindersEnabledKey, enabled);
  }

  /// Check if gym reminder is enabled
  bool isGymReminderEnabled() {
    if (!_initialized) {
      return true; // Default enabled
    }
    return _prefs.getBool(_gymReminderEnabledKey) ?? true;
  }

  /// Set gym reminder enabled state
  Future<bool> setGymReminderEnabled(bool enabled) async {
    if (!_initialized) {
      await init();
    }
    return await _prefs.setBool(_gymReminderEnabledKey, enabled);
  }

  /// Reset all settings to defaults
  Future<bool> resetAllSettings() async {
    if (!_initialized) {
      await init();
    }
    try {
      await _prefs.remove(_calorieGoalKey);
      await _prefs.remove(_breakfastTimeKey);
      await _prefs.remove(_lunchTimeKey);
      await _prefs.remove(_dinnerTimeKey);
      await _prefs.remove(_gymTimeKey);
      await _prefs.remove(_waterRemindersEnabledKey);
      await _prefs.remove(_mealRemindersEnabledKey);
      await _prefs.remove(_gymReminderEnabledKey);
      developer.log(
        'All settings reset to defaults',
        name: 'PreferencesService',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error resetting all settings: $e',
        name: 'PreferencesService',
        error: e,
      );
      return false;
    }
  }

  /// Validate time format (HH:mm)
  void _validateTimeFormat(String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) {
        throw FormatException('Invalid time format. Use HH:mm');
      }

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      if (hour < 0 || hour > 23) {
        throw RangeError('Hour must be between 0 and 23');
      }

      if (minute < 0 || minute > 59) {
        throw RangeError('Minute must be between 0 and 59');
      }
    } catch (e) {
      throw FormatException('Invalid time format or values: $e');
    }
  }
}
