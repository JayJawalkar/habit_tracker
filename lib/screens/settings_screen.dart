import 'package:flutter/material.dart';
import '../../services/preferences_service.dart';
import '../../services/notification_service.dart';
import 'dart:developer' as developer;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final PreferencesService _preferencesService = PreferencesService();
  late final NotificationService _notificationService = NotificationService();
  late TextEditingController _calorieGoalController;

  late String _breakfastTime;
  late String _lunchTime;
  late String _dinnerTime;
  late String _gymTime;

  late bool _waterRemindersEnabled;
  late bool _mealRemindersEnabled;
  late bool _gymReminderEnabled;

  late int currentCalorieGoal;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      currentCalorieGoal = _preferencesService.getCalorieGoal();
      _breakfastTime = _preferencesService.getBreakfastTime();
      _lunchTime = _preferencesService.getLunchTime();
      _dinnerTime = _preferencesService.getDinnerTime();
      _gymTime = _preferencesService.getGymTime();

      _waterRemindersEnabled = _preferencesService.isWaterRemindersEnabled();
      _mealRemindersEnabled = _preferencesService.isMealRemindersEnabled();
      _gymReminderEnabled = _preferencesService.isGymReminderEnabled();

      _calorieGoalController = TextEditingController(
        text: currentCalorieGoal.toString(),
      );

      setState(() {});
    } catch (e) {
      developer.log(
        'Error loading settings: $e',
        name: 'SettingsScreen',
        error: e,
      );
      if (mounted) {
        _showErrorSnackBar('Failed to load settings');
      }
    }
  }

  @override
  void dispose() {
    _calorieGoalController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(
    String currentTime,
    Function(String) onTimePicked,
  ) async {
    try {
      final parts = currentTime.split(':');
      final initialHour = int.parse(parts[0]);
      final initialMinute = int.parse(parts[1]);

      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: const TimePickerThemeData(
                dialBackgroundColor: Color(0xFF13ec80),
                hourMinuteTextColor: Colors.white,
                dayPeriodTextColor: Colors.white,
              ),
            ),
            child: child ?? const SizedBox(),
          );
        },
      );

      if (picked != null) {
        final formattedTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        onTimePicked(formattedTime);
        setState(() {});
      }
    } catch (e) {
      developer.log('Error picking time: $e', name: 'SettingsScreen', error: e);
      if (mounted) {
        _showErrorSnackBar('Failed to pick time');
      }
    }
  }

  Future<void> _saveBreakfastTime() async {
    if (!_isValidTime(_breakfastTime)) {
      _showErrorSnackBar('Invalid breakfast time');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await _preferencesService.setBreakfastTime(
        _breakfastTime,
      );
      if (success && _mealRemindersEnabled) {
        await _scheduleMealReminders();
      }

      if (mounted) {
        if (success) {
          _showSuccessSnackBar('Breakfast time updated to $_breakfastTime');
        } else {
          _showErrorSnackBar('Failed to save breakfast time');
        }
      }
    } catch (e) {
      developer.log(
        'Error saving breakfast time: $e',
        name: 'SettingsScreen',
        error: e,
      );
      if (mounted) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLunchTime() async {
    if (!_isValidTime(_lunchTime)) {
      _showErrorSnackBar('Invalid lunch time');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await _preferencesService.setLunchTime(_lunchTime);
      if (success && _mealRemindersEnabled) {
        await _scheduleMealReminders();
      }

      if (mounted) {
        if (success) {
          _showSuccessSnackBar('Lunch time updated to $_lunchTime');
        } else {
          _showErrorSnackBar('Failed to save lunch time');
        }
      }
    } catch (e) {
      developer.log(
        'Error saving lunch time: $e',
        name: 'SettingsScreen',
        error: e,
      );
      if (mounted) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDinnerTime() async {
    if (!_isValidTime(_dinnerTime)) {
      _showErrorSnackBar('Invalid dinner time');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await _preferencesService.setDinnerTime(_dinnerTime);
      if (success && _mealRemindersEnabled) {
        await _scheduleMealReminders();
      }

      if (mounted) {
        if (success) {
          _showSuccessSnackBar('Dinner time updated to $_dinnerTime');
        } else {
          _showErrorSnackBar('Failed to save dinner time');
        }
      }
    } catch (e) {
      developer.log(
        'Error saving dinner time: $e',
        name: 'SettingsScreen',
        error: e,
      );
      if (mounted) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveGymTime() async {
    if (!_isValidTime(_gymTime)) {
      _showErrorSnackBar('Invalid gym time');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await _preferencesService.setGymTime(_gymTime);
      if (success && _gymReminderEnabled) {
        await _notificationService.scheduleGymReminder(_gymTime);
      }

      if (mounted) {
        if (success) {
          _showSuccessSnackBar('Gym time updated to $_gymTime');
        } else {
          _showErrorSnackBar('Failed to save gym time');
        }
      }
    } catch (e) {
      developer.log(
        'Error saving gym time: $e',
        name: 'SettingsScreen',
        error: e,
      );
      if (mounted) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleWaterReminders(bool value) async {
    setState(() => _waterRemindersEnabled = value);

    try {
      await _preferencesService.setWaterRemindersEnabled(value);

      if (value) {
        await _notificationService.scheduleHourlyWaterReminders();
        if (mounted) {
          _showSuccessSnackBar('Water reminders enabled');
        }
      } else {
        await _notificationService.cancelAllWaterReminders();
        if (mounted) {
          _showSuccessSnackBar('Water reminders disabled');
        }
      }
    } catch (e) {
      developer.log(
        'Error toggling water reminders: $e',
        name: 'SettingsScreen',
        error: e,
      );
      setState(() => _waterRemindersEnabled = !value);
      if (mounted) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    }
  }

  Future<void> _toggleMealReminders(bool value) async {
    setState(() => _mealRemindersEnabled = value);

    try {
      await _preferencesService.setMealRemindersEnabled(value);

      if (value) {
        await _scheduleMealReminders();
        if (mounted) {
          _showSuccessSnackBar('Meal reminders enabled');
        }
      } else {
        await _notificationService.cancelAllMealReminders();
        if (mounted) {
          _showSuccessSnackBar('Meal reminders disabled');
        }
      }
    } catch (e) {
      developer.log(
        'Error toggling meal reminders: $e',
        name: 'SettingsScreen',
        error: e,
      );
      setState(() => _mealRemindersEnabled = !value);
      if (mounted) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    }
  }

  Future<void> _toggleGymReminder(bool value) async {
    setState(() => _gymReminderEnabled = value);

    try {
      await _preferencesService.setGymReminderEnabled(value);

      if (value) {
        await _notificationService.scheduleGymReminder(_gymTime);
        if (mounted) {
          _showSuccessSnackBar('Gym reminder enabled');
        }
      } else {
        await _notificationService.cancelGymReminder();
        if (mounted) {
          _showSuccessSnackBar('Gym reminder disabled');
        }
      }
    } catch (e) {
      developer.log(
        'Error toggling gym reminder: $e',
        name: 'SettingsScreen',
        error: e,
      );
      setState(() => _gymReminderEnabled = !value);
      if (mounted) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    }
  }

  Future<void> _scheduleMealReminders() async {
    try {
      await _notificationService.scheduleMealReminders(
        breakfastTime: _breakfastTime,
        lunchTime: _lunchTime,
        dinnerTime: _dinnerTime,
      );
    } catch (e) {
      developer.log(
        'Error scheduling meal reminders: $e',
        name: 'SettingsScreen',
        error: e,
      );
      rethrow;
    }
  }

  Future<void> _saveCalorieGoal() async {
    final value = int.tryParse(_calorieGoalController.text);

    if (value == null || value <= 0) {
      _showErrorSnackBar('Please enter a valid calorie goal (> 0)');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await _preferencesService.setCalorieGoal(value);

      if (mounted) {
        if (success) {
          setState(() => currentCalorieGoal = value);
          _showSuccessSnackBar('Calorie goal updated to $value kcal');
        } else {
          _showErrorSnackBar('Failed to save calorie goal');
        }
      }
    } catch (e) {
      developer.log(
        'Error saving calorie goal: $e',
        name: 'SettingsScreen',
        error: e,
      );
      if (mounted) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetToDefault() async {
    setState(() => _isLoading = true);
    try {
      final success = await _preferencesService.resetCalorieGoal();

      if (mounted) {
        if (success) {
          setState(() {
            currentCalorieGoal = 2200;
            _calorieGoalController.text = '2200';
          });
          _showSuccessSnackBar('Calorie goal reset to default (2200 kcal)');
        }
      }
    } catch (e) {
      developer.log(
        'Error resetting calorie goal: $e',
        name: 'SettingsScreen',
        error: e,
      );
      if (mounted) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isValidTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return false;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
    } catch (e) {
      return false;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_calorieGoalController.text.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notification Settings Section
          const Text(
            'Notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Water Reminders Card
          _buildNotificationCard(
            title: '💧 Water Intake Reminders',
            subtitle: 'Hourly reminders until midnight',
            value: _waterRemindersEnabled,
            onChanged: _toggleWaterReminders,
          ),
          const SizedBox(height: 12),

          // Meal Reminders Card
          _buildNotificationCard(
            title: '🍽️ Meal Reminders',
            subtitle: 'Get reminded for breakfast, lunch & dinner',
            value: _mealRemindersEnabled,
            onChanged: _toggleMealReminders,
          ),
          const SizedBox(height: 12),

          // Gym Reminder Card
          _buildNotificationCard(
            title: '💪 Gym Reminder',
            subtitle: 'Get reminded to workout',
            value: _gymReminderEnabled,
            onChanged: _toggleGymReminder,
          ),
          const SizedBox(height: 32),

          // Meal Timings Section
          const Text(
            'Meal Timings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Breakfast Time
          _buildTimePickerCard(
            title: '🌅 Breakfast',
            time: _breakfastTime,
            onTap: () => _pickTime(_breakfastTime, (time) {
              setState(() => _breakfastTime = time);
            }),
            onSave: _saveBreakfastTime,
          ),
          const SizedBox(height: 12),

          // Lunch Time
          _buildTimePickerCard(
            title: '🥗 Lunch',
            time: _lunchTime,
            onTap: () => _pickTime(_lunchTime, (time) {
              setState(() => _lunchTime = time);
            }),
            onSave: _saveLunchTime,
          ),
          const SizedBox(height: 12),

          // Dinner Time
          _buildTimePickerCard(
            title: '🍲 Dinner',
            time: _dinnerTime,
            onTap: () => _pickTime(_dinnerTime, (time) {
              setState(() => _dinnerTime = time);
            }),
            onSave: _saveDinnerTime,
          ),
          const SizedBox(height: 32),

          // Gym Timing Section
          const Text(
            'Gym Timing',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildTimePickerCard(
            title: '💪 Workout Time',
            time: _gymTime,
            onTap: () => _pickTime(_gymTime, (time) {
              setState(() => _gymTime = time);
            }),
            onSave: _saveGymTime,
          ),
          const SizedBox(height: 32),

          // Nutrition Goals Section
          const Text(
            'Nutrition Goals',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Calorie Goal Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Calorie Goal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set your target daily calorie intake',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _calorieGoalController,
                  keyboardType: TextInputType.number,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'e.g., 2200',
                    suffixText: 'kcal',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveCalorieGoal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF13ec80),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Save Goal',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _resetToDefault,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Reset'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13ec80).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Color(0xFF13ec80),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Current goal: $currentCalorieGoal kcal',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF13ec80),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Recommended Goals Section
          const Text(
            'Recommended Goals',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          _buildGoalQuickAction(1800, 'Low Activity'),
          const SizedBox(height: 8),
          _buildGoalQuickAction(2200, 'Moderate Activity'),
          const SizedBox(height: 8),
          _buildGoalQuickAction(2800, 'High Activity'),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF13ec80),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerCard({
    required String title,
    required String time,
    required VoidCallback onTap,
    required VoidCallback onSave,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _isLoading ? null : onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      time,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF13ec80),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF13ec80),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalQuickAction(int goal, String label) {
    return GestureDetector(
      onTap: () {
        _calorieGoalController.text = goal.toString();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '$goal kcal/day',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
