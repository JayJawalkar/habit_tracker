import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:developer' as developer;
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _isInitialized = false;

  static const int _waterNotificationIdStart = 1000;
  static const int _mealNotificationIdStart = 2000;
  static const int _gymNotificationId = 3000;
  static const int _waterRescheduleNotificationId = 9999;

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

    // Set timezone to IST (Asia/Kolkata) for India
    // This ensures all notifications are scheduled in Indian Standard Time
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      developer.log(
        'Timezone set to IST (Asia/Kolkata)',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        'Error setting timezone: $e',
        name: 'NotificationService',
        error: e,
      );
      // Fallback to local timezone if Asia/Kolkata not available
      tz.setLocalLocation(tz.local);
    }

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
      if (Platform.isIOS) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }

      // Request permissions for Android 13+
      if (Platform.isAndroid) {
        // Request notification permission
        final hasPermission = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
        developer.log(
          'Android notification permission: $hasPermission',
          name: 'NotificationService',
        );

        // Create notification channels
        await _createNotificationChannels();
      }

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

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    try {
      final androidPlugin = AndroidFlutterLocalNotificationsPlugin();

      // Water channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'water_intake_channel',
          'Water Intake Reminders',
          description: 'Hourly reminders to drink water throughout the day',
          importance: Importance.defaultImportance,
          enableVibration: true,
          playSound: true,
        ),
      );

      // Meal channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'meal_reminders_channel',
          'Meal Reminders',
          description: 'Reminders for breakfast, lunch, and dinner',
          importance: Importance.defaultImportance,
          enableVibration: true,
          playSound: true,
        ),
      );

      // Gym channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'gym_reminder_channel',
          'Gym Reminders',
          description: 'Reminder for gym workout',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );

      developer.log(
        'Notification channels created successfully',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        'Error creating notification channels: $e',
        name: 'NotificationService',
        error: e,
      );
    }
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

          developer.log(
            'Water reminder $notificationId: Current=${now.toString()} | Scheduled=${scheduledDate.toString()} | TZ=${tz.local.name}',
            name: 'NotificationService',
          );

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
                showWhen: true,
                onlyAlertOnce: false,
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

      // Schedule a notification at midnight to reschedule water reminders for the next day
      final midnightSchedule =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, 23, 59, 0).add(
            const Duration(minutes: 1),
          ); // Reschedule at 23:59 to ensure daily reset

      // Schedule at midnight to trigger reschedule
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _waterRescheduleNotificationId,
        'Water Reminders Reset',
        'Resetting water reminders for tomorrow',
        midnightSchedule,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'water_intake_channel',
            'Water Intake Reminders',
            channelDescription:
                'Hourly reminders to drink water throughout the day',
            importance: Importance.min,
            priority: Priority.min,
            enableVibration: false,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: false,
            presentBadge: false,
            presentSound: false,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      developer.log(
        'Hourly water reminders scheduled successfully ($notificationId total) + daily reschedule',
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
      // Also cancel the reschedule notification
      await _flutterLocalNotificationsPlugin.cancel(
        _waterRescheduleNotificationId,
      );

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

        developer.log(
          'Scheduling $mealName at $time | Current time: ${now.toString()} | Scheduled: ${scheduledDate.toString()} | TZ: ${tz.local.name}',
          name: 'NotificationService',
        );

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
              showWhen: true,
              onlyAlertOnce: false,
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

      developer.log(
        'Gym reminder: Current=${now.toString()} | Scheduled=${scheduledDate.toString()} | TZ=${tz.local.name}',
        name: 'NotificationService',
      );

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
            showWhen: true,
            onlyAlertOnce: false,
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

  /// Show a test notification immediately
  Future<void> showTestNotification() async {
    if (!_isInitialized) {
      throw Exception('NotificationService not initialized');
    }

    try {
      await _flutterLocalNotificationsPlugin.show(
        9998,
        '🧪 Test Notification',
        'If you see this, notifications are working correctly!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'water_intake_channel',
            'Water Intake Reminders',
            channelDescription:
                'Hourly reminders to drink water throughout the day',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            showWhen: true,
            onlyAlertOnce: false,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      developer.log('Test notification shown', name: 'NotificationService');
    } catch (e) {
      developer.log(
        'Error showing test notification: $e',
        name: 'NotificationService',
        error: e,
      );
      rethrow;
    }
  }

  /// Print debug information about notification system
  Future<void> printDebugInfo() async {
    try {
      final pending = await getPendingNotifications();
      final currentTz = tz.local.name;
      final now = tz.TZDateTime.now(tz.local);

      developer.log('''
=== NOTIFICATION SYSTEM DEBUG INFO ===
Timezone: $currentTz
Current Time: ${now.toString()}
Total Pending Notifications: ${pending.length}
Service Initialized: $_isInitialized

Pending Notifications:
${pending.map((n) => '  - ID: ${n.id}, Title: ${n.title}').join('\n')}

=== END DEBUG INFO ===
''', name: 'NotificationService');
    } catch (e) {
      developer.log(
        'Error printing debug info: $e',
        name: 'NotificationService',
        error: e,
      );
    }
  }

  /// Check if water reminders are enabled
  bool get isInitialized => _isInitialized;
}
