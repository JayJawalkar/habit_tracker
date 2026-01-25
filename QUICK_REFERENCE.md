# Quick Reference Guide - Notification System

## 🚀 Quick Start (30 seconds)

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Go to Settings tab
# Enable notifications and set your preferred times
# Done! 🎉
```

## 📋 Default Notification Times

| Type      | Time               | Enabled by Default |
| --------- | ------------------ | ------------------ |
| Water     | Hourly until 23:00 | Yes                |
| Breakfast | 08:00              | Yes                |
| Lunch     | 12:30              | Yes                |
| Dinner    | 19:00              | Yes                |
| Gym       | 06:00              | Yes                |

## 🎛️ How to Configure

### From Settings Screen

1. Tap **Settings** (bottom navigation)
2. Under **Notifications** section, toggle the desired reminder type
3. Under **Meal Timings** or **Gym Timing**, tap the time field
4. Select your preferred time from the picker
5. Tap **Save**

### Programmatically

```dart
final prefs = PreferencesService();
final notif = NotificationService();

// Set breakfast time
await prefs.setBreakfastTime('07:30');

// Schedule meal reminders if enabled
if (prefs.isMealRemindersEnabled()) {
  await notif.scheduleMealReminders(
    breakfastTime: prefs.getBreakfastTime(),
    lunchTime: prefs.getLunchTime(),
    dinnerTime: prefs.getDinnerTime(),
  );
}

// Toggle water reminders
await prefs.setWaterRemindersEnabled(true);
await notif.scheduleHourlyWaterReminders();
```

## 🎯 Common Scenarios

### Scenario 1: User wants water reminders only

```
1. Go to Settings
2. Toggle "Water Intake Reminders" ON
3. Toggle "Meal Reminders" OFF
4. Toggle "Gym Reminder" OFF
```

### Scenario 2: User wants to change lunch time to 1:00 PM

```
1. Go to Settings → Meal Timings
2. Tap the time field under "Lunch"
3. Select 13:00 from the time picker
4. Tap Save
5. (If meal reminders enabled, they'll update automatically)
```

### Scenario 3: User wants to be reminded for gym at 6:30 PM

```
1. Go to Settings → Gym Timing
2. Tap the time field under "Workout Time"
3. Select 18:30 from the time picker
4. Tap Save
5. Make sure "Gym Reminder" toggle is ON
```

## 🔍 Troubleshooting Quick Fixes

| Problem                      | Solution                                        |
| ---------------------------- | ----------------------------------------------- |
| No notifications appearing   | Check Settings → Notifications permission is ON |
| Notifications at wrong time  | Check device time & timezone are correct        |
| Notifications keep appearing | Check they aren't duplicated in settings        |
| Settings not saving          | Check app has storage permissions               |
| Time picker not working      | Try restarting the app                          |

## 📱 What Each Notification Type Does

### 💧 Water Intake Reminders

- **Frequency:** Every hour
- **Time Range:** Current hour until 23:00 (stops before midnight)
- **Content:** Random hydration quote from 20 options
- **Example:** "💧 Hydration is the foundation of health! Drink water now."

### 🍽️ Meal Reminders

- **Type:** 3 separate reminders (breakfast, lunch, dinner)
- **Frequency:** Once daily at your set time
- **Content:** Meal-specific reminder message
- **Examples:**
  - "🌅 Breakfast Time - It's time for Breakfast! Don't forget to eat healthy."
  - "🥗 Lunch Time - It's time for Lunch! Don't forget to eat healthy."
  - "🍲 Dinner Time - It's time for Dinner! Don't forget to eat healthy."

### 💪 Gym Reminder

- **Frequency:** Once daily at your set time
- **Content:** Motivation message
- **Example:** "💪 Gym Time! - Time to work out! Your health is wealth. Get moving!"

## ⚙️ Technical Details

### Notification IDs

- Water reminders: 1000-1999 (hourly, changes daily)
- Meal reminders: 2000-2002 (breakfast, lunch, dinner)
- Gym reminder: 3000 (single gym reminder)

### Storage

- All settings stored in **SharedPreferences**
- Persists across app restarts
- No cloud sync (local device only)

### Permissions Required

- **Android 13+:** POST_NOTIFICATIONS
- **Android 12+:** SCHEDULE_EXACT_ALARM
- **iOS:** Alert, Badge, Sound (requested at runtime)

## 🐛 Debug Logging

To see notification logs in terminal:

```bash
flutter logs
```

Look for entries starting with:

- `NotificationService` - Notification scheduling
- `PreferencesService` - Settings changes
- `SettingsScreen` - UI interactions
- `main` - App initialization

## 💡 Pro Tips

1. **Test Notifications:** Set a time 1 minute from now to quickly test
2. **Battery Optimization:** Use "allowWhileIdle" mode, won't drain battery significantly
3. **Silent Mode:** Device quiet/vibrate mode respects notification sound
4. **Do Not Disturb:** Check device DND settings if notifications seem quiet
5. **Notifications Off:** Users can still disable notifications in OS settings

## 🔄 Reset Everything

To reset all notification settings to defaults:

```dart
final prefs = PreferencesService();
await prefs.resetAllSettings();
```

Then restart the app.

## 📚 Documentation Files

1. **`NOTIFICATION_SETUP.md`** - Setup & usage guide
2. **`NOTIFICATION_SYSTEM.md`** - Full technical documentation
3. **`IMPLEMENTATION_COMPLETE.md`** - Implementation summary
4. **`VERIFICATION_CHECKLIST.md`** - Complete feature checklist
5. **`QUICK_REFERENCE.md`** - This file!

## 🎓 For Developers

### Key Classes

- `NotificationService` (lib/services/notification_service.dart) - Main API
- `PreferencesService` (lib/services/preferences_service.dart) - Settings storage
- `SettingsScreen` (lib/settings_screen.dart) - Settings UI

### Main Methods

```dart
// Schedule notifications
await notificationService.scheduleHourlyWaterReminders();
await notificationService.scheduleMealReminders(...);
await notificationService.scheduleGymReminder(...);

// Cancel notifications
await notificationService.cancelAllWaterReminders();
await notificationService.cancelAllMealReminders();
await notificationService.cancelGymReminder();
await notificationService.cancelAllNotifications();

// Get preferences
preferencesService.getBreakfastTime(); // Returns HH:mm
preferencesService.isWaterRemindersEnabled(); // Returns bool
```

### Add New Notification Type

1. Add notification ID constant:

```dart
static const int _newNotificationId = 4000;
```

2. Create schedule method:

```dart
Future<void> scheduleNewReminder(String time) async {
  // Implementation
}
```

3. Add preference methods to `PreferencesService`

4. Add UI to `SettingsScreen`

## ✅ Pre-Deployment Checklist

- [ ] Test on Android device/emulator
- [ ] Test on iOS device/simulator
- [ ] Verify water reminders hourly
- [ ] Verify meal reminders at set times
- [ ] Verify gym reminder at set time
- [ ] Test permission requests
- [ ] Test app restart
- [ ] Test time picker
- [ ] Test error messages
- [ ] Verify no compile errors

## 📞 Need Help?

1. Check `NOTIFICATION_SYSTEM.md` for detailed info
2. Review `VERIFICATION_CHECKLIST.md` for known issues
3. Check app logs: `flutter logs`
4. Verify device permissions in Settings
5. Try restarting the app

---

**Last Updated:** January 2026  
**Status:** ✅ Production Ready  
**Version:** 1.0
