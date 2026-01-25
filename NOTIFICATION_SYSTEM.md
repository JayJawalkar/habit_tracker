# Notification System Documentation

## Overview

The Habit Tracker app now includes a comprehensive local notification system that provides reminders for:

1. **Water Intake**: Hourly reminders with motivational quotes until midnight
2. **Meal Timings**: Reminders for breakfast, lunch, and dinner at user-configured times
3. **Gym Workouts**: Reminder at user-configured gym time

## Features

### 1. Water Intake Reminders

- **Frequency**: Every hour until midnight
- **Content**: 20 different motivational quotes about hydration
- **Customization**: Can be enabled/disabled from settings
- **Schedule**: Automatically resets daily and schedules for the next day

### 2. Meal Reminders

- **Meals**: Breakfast, Lunch, Dinner
- **Customization**: Users can set custom times for each meal
- **Default Times**:
  - Breakfast: 08:00
  - Lunch: 12:30
  - Dinner: 19:00
- **Behavior**: Reminders repeat daily at the set times
- **Enable/Disable**: Can be toggled on/off from settings

### 3. Gym Reminder

- **Customization**: Users can set custom workout time
- **Default Time**: 06:00
- **Behavior**: Repeats daily at the set time
- **Enable/Disable**: Can be toggled on/off from settings

## Architecture

### Services

#### NotificationService (`lib/services/notification_service.dart`)

Singleton service responsible for all notification operations:

**Key Methods:**

- `initialize()`: Initializes the notification system with proper permissions
- `scheduleHourlyWaterReminders()`: Schedules water reminders for every hour until midnight
- `scheduleMealReminders()`: Schedules daily meal reminders
- `scheduleGymReminder()`: Schedules daily gym reminder
- `cancelAllWaterReminders()`: Cancels all pending water reminders
- `cancelAllMealReminders()`: Cancels all pending meal reminders
- `cancelGymReminder()`: Cancels gym reminder
- `cancelAllNotifications()`: Cancels all notifications

**Error Handling:**

- Validates time formats (HH:mm)
- Handles invalid times with proper error messages
- Logs all operations for debugging
- Catches and reports exceptions gracefully

#### PreferencesService (`lib/services/preferences_service.dart`)

Extended with notification-related preferences:

**Notification Settings:**

- `isWaterRemindersEnabled()`: Check if water reminders are active
- `isMealRemindersEnabled()`: Check if meal reminders are active
- `isGymReminderEnabled()`: Check if gym reminder is active

**Meal/Gym Timings:**

- `getBreakfastTime()`, `setBreakfastTime()`
- `getLunchTime()`, `setLunchTime()`
- `getDinnerTime()`, `setDinnerTime()`
- `getGymTime()`, `setGymTime()`

**Time Validation:**

- All times use HH:mm 24-hour format
- Hours: 0-23
- Minutes: 0-59
- Invalid times throw `FormatException` with descriptive messages

### UI Components

#### Settings Screen (`lib/settings_screen.dart`)

Updated with comprehensive notification configuration:

**Sections:**

1. **Notifications**: Toggle switches for each notification type
2. **Meal Timings**: Time pickers for breakfast, lunch, dinner
3. **Gym Timing**: Time picker for workout
4. **Nutrition Goals**: Existing calorie goal configuration (unchanged)

**Features:**

- Real-time time picker using Material Design
- Live preview of selected times
- Immediate notification scheduling upon save
- Comprehensive error handling with user-friendly messages
- Loading states during operations
- Success/error snackbar notifications

## Platform-Specific Configuration

### Android

**Permissions Added:**

- `android.permission.POST_NOTIFICATIONS` (Android 13+)
- `android.permission.SCHEDULE_EXACT_ALARM` (for precise scheduling)

**Notification Channels:**

- `water_intake_channel`: Water intake reminders
- `meal_reminders_channel`: Meal notifications
- `gym_reminder_channel`: Workout reminders

**Features:**

- Exact alarm scheduling for precise timing
- Vibration on notification
- Custom notification sound support

### iOS

**Capabilities Required:**

- Push Notifications (enabled by default in Flutter)
- Background Modes (not required for local notifications)

**Features:**

- Alert, Badge, and Sound permissions requested
- Secure notification handling
- Full support for daily repeated notifications

## Initialization Flow

1. **App Startup** (`main.dart`):

   ```
   - Initialize PreferencesService
   - Initialize NotificationService
   - Load saved notification preferences
   - Schedule all enabled notifications based on saved settings
   ```

2. **Settings Update**:

   ```
   - User changes setting in SettingsScreen
   - Save preference to SharedPreferences
   - Reschedule notifications with new settings
   - Show success/error feedback to user
   ```

3. **Notification Trigger**:
   ```
   - System triggers notification at scheduled time
   - User receives notification
   - Tapping notification can be handled (customizable)
   ```

## Edge Cases Handled

### Time Validation

- ✅ Invalid hour values (>23 or <0)
- ✅ Invalid minute values (>59 or <0)
- ✅ Malformed time strings
- ✅ Empty or null time values

### Scheduling Edge Cases

- ✅ Times that have already passed today (schedules for tomorrow)
- ✅ Midnight boundary (water reminders stop at midnight)
- ✅ Timezone changes during day
- ✅ Device sleep/wake cycles
- ✅ Permission failures (graceful degradation)
- ✅ Multiple notification updates (proper cancellation before rescheduling)

### Permission Handling

- ✅ iOS runtime permission requests
- ✅ Android 13+ runtime permission requests
- ✅ Graceful behavior if permissions denied
- ✅ Automatic retry on permission grant

### State Management

- ✅ Concurrent updates (loading states prevent multiple operations)
- ✅ App restart with saved preferences
- ✅ Notification persistence across app restarts
- ✅ Proper cleanup on disable/cancel

## Error Messages & Logging

### User-Facing Errors

- "Invalid [meal] time": When user enters invalid time
- "Failed to save [setting]": When storage fails
- "Error: [specific error]": For exceptional cases

### Developer Logs

All operations logged using Dart's `developer.log()`:

- `NotificationService`: Notification-related logs
- `PreferencesService`: Preference-related logs
- `SettingsScreen`: UI/user interaction logs
- `main`: App initialization logs

## Testing Edge Cases

### Manual Testing Checklist

- [ ] Set breakfast time in the past → verify it schedules for tomorrow
- [ ] Disable all notifications → verify all are cancelled
- [ ] Enable water reminders at 10pm → verify stops at midnight
- [ ] Set gym time to edge times (00:00, 23:59) → verify correct scheduling
- [ ] Toggle notifications on/off multiple times → verify proper state
- [ ] Change meal times multiple times → verify latest time is used
- [ ] Kill and restart app → verify notifications still scheduled
- [ ] Enter invalid times (24:00, 60:99) → verify error messages
- [ ] Test on Android 12 and 13+ → verify permission handling
- [ ] Test with device in do-not-disturb mode → verify behavior

## Customization & Extension

### Adding New Notification Types

1. Add constant to `NotificationService`:

   ```dart
   static const int _newNotificationId = 4000;
   ```

2. Create schedule method:

   ```dart
   Future<void> scheduleNewNotification(String time) async { ... }
   ```

3. Add preference keys to `PreferencesService`

4. Add UI to `SettingsScreen`

### Customizing Messages

Edit the `waterQuotes` list in `NotificationService` to add/modify water intake messages.

### Changing Default Times

Update constants in `PreferencesService`:

```dart
static const String _defaultBreakfastTime = '08:00';
// etc.
```

## Known Limitations

1. **Exact Alarm Precision**: Android's exact alarm feature may not trigger at exact millisecond precision if system is in Doze mode
2. **Background Notifications**: Notifications won't trigger if device is powered off
3. **Permission Changes**: Changing notification permissions requires app restart on some devices
4. **Timezone Changes**: If user changes timezone mid-day, water reminders might not reschedule until app restart

## Future Enhancements

- [ ] Custom notification sounds per notification type
- [ ] Notification history/log viewer
- [ ] Snooze functionality for notifications
- [ ] Custom notification text templates
- [ ] Smart pause (don't notify during sleep hours)
- [ ] Notification frequency analytics
- [ ] Do-not-disturb mode integration
- [ ] Weekly vs. daily notification options

## Dependencies

- `flutter_local_notifications: ^17.1.2` - Local notification scheduling
- `timezone: ^0.9.4` - Timezone handling for accurate scheduling
- `shared_preferences: ^2.2.3` - Persisting notification preferences (already included)

## Troubleshooting

### Notifications Not Appearing

1. Check if notifications are enabled in Settings
2. Verify device notification settings for the app
3. Check system Do Not Disturb mode
4. Check app logs for errors: `flutter logs`

### Notifications Appearing at Wrong Time

1. Check device timezone settings
2. Verify the saved time using: `PreferencesService().getBreakfastTime()` etc.
3. Check for conflicting alarm apps

### Permission Issues

1. Go to Settings → Apps → Habit Tracker → Permissions
2. Enable "Notifications" permission
3. Restart the app
4. Try enabling notification from settings screen

## Support & Issues

For issues or feature requests, please check:

1. Device timezone is correct
2. Device time is correct
3. Notification permissions are granted
4. App is not blocked by system restrictions
