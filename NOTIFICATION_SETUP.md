# Notification System - Quick Start Guide

## Setup Instructions

### 1. Dependencies

Already added to `pubspec.yaml`:

```yaml
flutter_local_notifications: ^17.1.2
timezone: ^0.9.4
```

Run:

```bash
flutter pub get
```

### 2. Android Setup (Automatic ✅)

- ✅ Permissions added to `AndroidManifest.xml`
- ✅ Notification channels configured in code
- ✅ Raw resource file created for notification sound

### 3. iOS Setup (Automatic ✅)

- ✅ Already configured in code
- ✅ Requests user permission at runtime
- ✅ Full support for local notifications

## Usage

### For Users

#### Enable Water Reminders

1. Go to Settings
2. Toggle "💧 Water Intake Reminders" ON
3. Receive hourly reminders until midnight with motivational quotes

#### Configure Meal Times

1. Go to Settings → Meal Timings
2. Tap the time field for Breakfast, Lunch, or Dinner
3. Select desired time from time picker
4. Tap "Save"
5. Enable "🍽️ Meal Reminders" toggle to receive notifications

#### Set Gym Time

1. Go to Settings → Gym Timing
2. Tap the time field for "💪 Workout Time"
3. Select desired workout time
4. Tap "Save"
5. Enable "💪 Gym Reminder" toggle to receive notifications

### For Developers

#### Check Notification Status

```dart
final notificationService = NotificationService();
final pending = await notificationService.getPendingNotifications();
print('Pending notifications: ${pending.length}');
```

#### Manually Schedule Notifications

```dart
final notificationService = NotificationService();

// Water reminders
await notificationService.scheduleHourlyWaterReminders();

// Meal reminders
await notificationService.scheduleMealReminders(
  breakfastTime: '08:00',
  lunchTime: '12:30',
  dinnerTime: '19:00',
);

// Gym reminder
await notificationService.scheduleGymReminder('06:00');
```

#### Get Current Settings

```dart
final preferencesService = PreferencesService();

print('Breakfast: ${preferencesService.getBreakfastTime()}');
print('Lunch: ${preferencesService.getLunchTime()}');
print('Dinner: ${preferencesService.getDinnerTime()}');
print('Gym: ${preferencesService.getGymTime()}');
print('Water enabled: ${preferencesService.isWaterRemindersEnabled()}');
print('Meals enabled: ${preferencesService.isMealRemindersEnabled()}');
print('Gym enabled: ${preferencesService.isGymReminderEnabled()}');
```

## Troubleshooting

### Android

**Issue**: Notifications not showing

- Solution: Check Settings → Apps → Habit Tracker → Notifications permission
- Check device Do Not Disturb mode

**Issue**: Notifications showing at wrong time

- Solution: Verify device timezone in Settings → Date & Time
- Check if "Automatic date & time" is enabled

### iOS

**Issue**: Permission dialog not appearing

- Solution: Go to Settings → Habit Tracker → Notifications and toggle on
- Restart the app

**Issue**: Notifications not persisting across restarts

- Solution: This is expected - they reschedule on app startup
- Check `main.dart` for initialization code

## Notification Content Examples

### Water Reminders

```
💧 Water Intake Reminder
Your body is 60% water - keep it replenished!
```

### Meal Reminders

```
🍽️ Breakfast Time
It's time for Breakfast! Don't forget to eat healthy.
```

### Gym Reminder

```
💪 Gym Time!
Time to work out! Your health is wealth. Get moving!
```

## Performance Tips

1. **Don't Disable/Enable Too Frequently**: Each toggle reschedules all notifications
2. **Batch Preference Updates**: Update multiple settings together if possible
3. **Clear Old Notifications**: Use `cancelAllNotifications()` if you notice duplicates

## Code Structure

```
lib/
├── services/
│   ├── notification_service.dart    # Main notification logic
│   ├── preferences_service.dart     # Preferences & time storage
│   └── supabase_service.dart        # (existing)
├── settings_screen.dart             # Settings UI with time pickers
└── main.dart                        # App initialization

android/
└── app/src/main/
    ├── AndroidManifest.xml          # Permissions
    └── res/raw/notification.xml     # Notification sound resource

ios/
└── Runner/Info.plist               # (already configured)
```

## Key Files to Know

| File                                     | Purpose                                 |
| ---------------------------------------- | --------------------------------------- |
| `lib/services/notification_service.dart` | Handles all notification scheduling     |
| `lib/services/preferences_service.dart`  | Stores user preferences                 |
| `lib/settings_screen.dart`               | UI for configuration                    |
| `lib/main.dart`                          | App initialization & notification setup |
| `NOTIFICATION_SYSTEM.md`                 | Full documentation                      |

## Common Customizations

### Change Default Breakfast Time

In `preferences_service.dart`:

```dart
static const String _defaultBreakfastTime = '07:00'; // Change from 08:00
```

### Add More Water Quotes

In `notification_service.dart`:

```dart
static const List<String> waterQuotes = [
  // ... existing quotes
  '🌟 New quote here!',
];
```

### Disable Notifications Entirely

Comment out in `main.dart`:

```dart
// if (preferencesService.isWaterRemindersEnabled()) { ... }
```

## Testing

### Test Water Reminders

1. Go to Settings
2. Enable water reminders
3. Wait for next hour mark
4. Notification should appear

### Test Meal Reminders

1. Set breakfast time to 1 minute from now
2. Enable meal reminders
3. Wait 1 minute
4. Notification should appear

### Test Gym Reminder

1. Set gym time to 1 minute from now
2. Enable gym reminder
3. Wait 1 minute
4. Notification should appear

## Next Steps

1. ✅ Build and run the app
2. ✅ Test notification permissions
3. ✅ Configure meal and gym times
4. ✅ Enable reminders
5. ✅ Wait for notifications at scheduled times

Enjoy your notification system! 🎉
