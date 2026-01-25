import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:developer' as developer;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _isInitialized = false;

  static const int _waterNotificationIdStart = 1000;
  static const int _mealNotificationIdStart = 2000;
  static const int _gymNotificationId = 3000;

  // Water intake quotes
  static const List<String> waterQuotes = [
    '💧 Hydration is the foundation of health! Drink water now.',
    '💦 Your body is 60% water - keep it replenished!',
    '🌊 Time to quench your thirst and boost your energy!',
    '💪 Water fuels your body - take a sip!',
    '🎯 Stay hydrated, stay focused! Grab a glass of water.',
    '✨ Every drop counts! Drink some water now.',
    '🏃 Water is nature\'s energy drink. Time to refuel!',
    '🧠 Dehydration affects your brain - drink water!',
    '💙 Your skin will thank you. Drink some water!',
    '⚡ Energy boost incoming - drink water now!',
    '🌟 Hydration = Health. Take a water break!',
    '🚰 Keep calm and drink water!',
    '💧 Small sips, big benefits - drink water!',
    '🏅 Champions stay hydrated - drink up!',
    '🎊 It\'s water o\'clock somewhere - enjoy!',
    '💯 100% pure hydration time!',
    '🌈 Rainbow your day with water!',
    '⏰ Reminder: Your health is important - drink water!',
    '🔥 Beat the thirst before it starts!',
    '🎁 Gift yourself good hydration - drink water!',
  ];

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Initialize timezone
    tz_data.initializeTimeZones();

    // Android initialization
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          onDidReceiveLocalNotification: null,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidInitializationSettings,
          iOS: iosInitializationSettings,
        );

    try {
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      // Request permissions for iOS
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      // Request permissions for Android (runtime permissions for Android 13+)
      // Note: requestPermission is optional, system will handle if not called

      _isInitialized = true;
      developer.log(
        'Notification service initialized successfully',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        'Error initializing notification service: $e',
        name: 'NotificationService',
        error: e,
      );
      rethrow;
    }
  }

  void _onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) {
    developer.log(
      'Notification tapped: ${notificationResponse.payload}',
      name: 'NotificationService',
    );
  }

  /// Schedule hourly water intake notifications
  Future<void> scheduleHourlyWaterReminders() async {
    if (!_isInitialized) {
      throw Exception('NotificationService not initialized');
    }

    try {
      // Cancel existing water notifications
      await cancelAllWaterReminders();

      final now = tz.TZDateTime.now(tz.local);
      int notificationId = _waterNotificationIdStart;

      // Schedule notifications for every hour until midnight
      for (int hour = now.hour; hour < 24; hour++) {
        final scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          0,
          0,
        );

        // Only schedule if the time is in the future
        if (scheduledDate.isAfter(now.add(Duration(minutes: 1)))) {
          final quote = waterQuotes[notificationId % waterQuotes.length];

          await _flutterLocalNotificationsPlugin.zonedSchedule(
            notificationId,
            '💧 Water Intake Reminder',
            quote,
            scheduledDate,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'water_intake_channel',
                'Water Intake Reminders',
                channelDescription:
                    'Hourly reminders to drink water throughout the day',
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority,
                enableVibration: true,
                sound: RawResourceAndroidNotificationSound('notification'),
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.alarmClock,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );

          notificationId++;
          developer.log(
            'Scheduled water reminder at $scheduledDate',
            name: 'NotificationService',
          );
        }
      }

      developer.log(
        'Hourly water reminders scheduled successfully ($notificationId total)',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        'Error scheduling water reminders: $e',
        name: 'NotificationService',
        error: e,
      );
      rethrow;
    }
  }

  /// Cancel all water intake reminders
  Future<void> cancelAllWaterReminders() async {
    try {
      // Cancel all notifications in the water range
      for (
        int i = _waterNotificationIdStart;
        i < _mealNotificationIdStart;
        i++
      ) {
        await _flutterLocalNotificationsPlugin.cancel(i);
      }
      developer.log(
        'All water reminders cancelled',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        'Error cancelling water reminders: $e',
        name: 'NotificationService',
        error: e,
      );
    }
  }

  /// Schedule meal time notifications
  Future<void> scheduleMealReminders({
    required String breakfastTime, // Format: "HH:mm"
    required String lunchTime,
    required String dinnerTime,
  }) async {
    if (!_isInitialized) {
      throw Exception('NotificationService not initialized');
    }

    try {
      // Validate times
      _validateTimeFormat(breakfastTime);
      _validateTimeFormat(lunchTime);
      _validateTimeFormat(dinnerTime);

      // Cancel existing meal notifications
      await cancelAllMealReminders();

      final meals = [
        ('Breakfast', breakfastTime, _mealNotificationIdStart),
        ('Lunch', lunchTime, _mealNotificationIdStart + 1),
        ('Dinner', dinnerTime, _mealNotificationIdStart + 2),
      ];

      for (final (mealName, time, notificationId) in meals) {
        final parts = time.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        final now = tz.TZDateTime.now(tz.local);
        var scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
          0,
        );

        // If time has passed today, schedule for tomorrow
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        await _flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          '🍽️ $mealName Time',
          'It\'s time for $mealName! Don\'t forget to eat healthy.',
          scheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'meal_reminders_channel',
              'Meal Reminders',
              channelDescription: 'Reminders for breakfast, lunch, and dinner',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
              enableVibration: true,
              sound: RawResourceAndroidNotificationSound('notification'),
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );

        developer.log(
          'Scheduled $mealName reminder at $time',
          name: 'NotificationService',
        );
      }

      developer.log(
        'Meal reminders scheduled successfully',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        'Error scheduling meal reminders: $e',
        name: 'NotificationService',
        error: e,
      );
      rethrow;
    }
  }

  /// Schedule gym reminder
  Future<void> scheduleGymReminder(String gymTime) async {
    if (!_isInitialized) {
      throw Exception('NotificationService not initialized');
    }

    try {
      // Validate time format
      _validateTimeFormat(gymTime);

      // Cancel existing gym notification
      await _flutterLocalNotificationsPlugin.cancel(_gymNotificationId);

      final parts = gymTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
        0,
      );

      // If time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _gymNotificationId,
        '💪 Gym Time!',
        'Time to work out! Your health is wealth. Get moving!',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'gym_reminder_channel',
            'Gym Reminders',
            channelDescription: 'Reminder for gym workout',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            sound: RawResourceAndroidNotificationSound('notification'),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      developer.log(
        'Gym reminder scheduled at $gymTime',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        'Error scheduling gym reminder: $e',
        name: 'NotificationService',
        error: e,
      );
      rethrow;
    }
  }

  /// Cancel all meal reminders
  Future<void> cancelAllMealReminders() async {
    try {
      for (int i = _mealNotificationIdStart; i < _gymNotificationId; i++) {
        await _flutterLocalNotificationsPlugin.cancel(i);
      }
      developer.log(
        'All meal reminders cancelled',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        'Error cancelling meal reminders: $e',
        name: 'NotificationService',
        error: e,
      );
    }
  }

  /// Cancel gym reminder
  Future<void> cancelGymReminder() async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(_gymNotificationId);
      developer.log('Gym reminder cancelled', name: 'NotificationService');
    } catch (e) {
      developer.log(
        'Error cancelling gym reminder: $e',
        name: 'NotificationService',
        error: e,
      );
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      developer.log('All notifications cancelled', name: 'NotificationService');
    } catch (e) {
      developer.log(
        'Error cancelling all notifications: $e',
        name: 'NotificationService',
        error: e,
      );
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

  /// Get all scheduled notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
    } catch (e) {
      developer.log(
        'Error getting pending notifications: $e',
        name: 'NotificationService',
        error: e,
      );
      return [];
    }
  }

  /// Check if water reminders are enabled
  bool get isInitialized => _isInitialized;
}
