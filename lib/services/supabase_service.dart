import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/calorie.dart';
import '../models/habit.dart';
import '../models/habit_type.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  late final SupabaseClient _client = Supabase.instance.client;

  String? get userId => _client.auth.currentUser?.id;

  /// Fetch all calories for today
  Future<List<Calorie>> getTodayCalories() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      if (userId == null) {
        return [];
      }

      final response = await _client
          .from('calories')
          .select()
          .eq('user_id', userId!)
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String())
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        return [];
      }

      return (response as List<dynamic>)
          .map((item) => Calorie.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching today calories: $e');
      return [];
    }
  }

  /// Get total calories for today
  Future<int> getTodayTotalCalories() async {
    try {
      final calories = await getTodayCalories();
      return calories.fold<int>(0, (sum, calorie) => sum + calorie.calories);
    } catch (e) {
      print('Error calculating total calories: $e');
      return 0;
    }
  }

  /// Fetch all calories for a date range (for weekly trend)
  Future<List<Calorie>> getCaloriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      if (userId == null) {
        return [];
      }

      final response = await _client
          .from('calories')
          .select()
          .eq('user_id', userId!)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: true);

      if (response.isEmpty) {
        return [];
      }

      return (response as List<dynamic>)
          .map((item) => Calorie.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching calories by date range: $e');
      return [];
    }
  }

  /// Get daily calorie totals for the last 7 days
  Future<List<double>> getWeeklyCalorieTrend() async {
    try {
      final now = DateTime.now();
      final trend = <double>[];

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final calories = await getCaloriesByDateRange(startOfDay, endOfDay);
        final total = calories.fold<int>(0, (sum, cal) => sum + cal.calories);
        trend.add(total.toDouble());
      }

      return trend;
    } catch (e) {
      print('Error fetching weekly trend: $e');
      return List.filled(7, 0.0);
    }
  }

  /// Fetch all habits for today
  Future<List<Habit>> getTodayHabits() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      if (userId == null) {
        return [];
      }

      final response = await _client
          .from('habits')
          .select()
          .eq('user_id', userId!)
          .eq('date', startOfDay.toString().split(' ')[0])
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        return [];
      }

      return (response as List<dynamic>)
          .map((item) => Habit.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching today habits: $e');
      return [];
    }
  }

  /// Calculate habit streak (consecutive days with at least one habit)
  Future<int> calculateStreak() async {
    try {
      if (userId == null) {
        return 0;
      }

      int streak = 0;
      var currentDate = DateTime.now();

      // Go back checking each day for habits
      while (true) {
        final startOfDay = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
        );
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final response = await _client
            .from('habits')
            .select()
            .eq('user_id', userId!)
            .gte('created_at', startOfDay.toIso8601String())
            .lt('created_at', endOfDay.toIso8601String())
            .limit(1);

        if ((response as List<dynamic>).isEmpty) {
          break;
        }

        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      }

      return streak;
    } catch (e) {
      print('Error calculating streak: $e');
      return 0;
    }
  }

  /// Fetch all habit types for the user
  Future<List<HabitType>> getHabitTypes() async {
    try {
      if (userId == null) {
        return [];
      }

      final response = await _client
          .from('habit_types')
          .select()
          .eq('user_id', userId!)
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        return [];
      }

      return (response as List<dynamic>)
          .map((item) => HabitType.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching habit types: $e');
      return [];
    }
  }

  /// Add a new calorie entry
  Future<bool> addCalorie({
    required int calories,
    required String mealName,
  }) async {
    try {
      if (userId == null) {
        return false;
      }

      await _client.from('calories').insert({
        'calories': calories,
        'meal_name': mealName,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error adding calorie: $e');
      return false;
    }
  }

  /// Add a new habit entry
  Future<bool> addHabit({
    required int habitTypeId,
    required String habitName,
    required DateTime date,
  }) async {
    try {
      if (userId == null) {
        return false;
      }

      await _client.from('habits').insert({
        'habit_type_id': habitTypeId,
        'habit_name': habitName,
        'date': date.toString().split(' ')[0],
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error adding habit: $e');
      return false;
    }
  }
}
