# Release Mode Grey Screen Fix

## Issues Found and Fixed

### 1. **Missing Error Handling in AuthWrapper** (Main Issue)

**Location:** [main.dart](main.dart#L147)

The `StreamBuilder` in the `AuthWrapper` was not handling error or loading states, causing a blank grey screen when:

- The Supabase auth stream had an error
- Initial connection was being established
- Network issues occurred

**Fix:** Added proper state handling:

- Loading state: Shows a loading spinner
- Error state: Shows an error message with a retry button
- Connected state: Properly routes to MainNavigator or AuthScreen

### 2. **Incomplete ProGuard Rules**

**Location:** [android/app/proguard-rules.pro](android/app/proguard-rules.pro)

Missing keep rules for essential libraries used in the app:

- Supabase Flutter SDK
- Flutter local notifications
- Shared preferences
- Flutter plugin system

**Fix:** Added comprehensive keep rules to prevent minification from removing essential classes:

```proguard
-keep class io.supabase.** { *; }
-keep class com.dexterous.flutterlocal.** { *; }
-keep class io.flutter.plugin.** { *; }
```

### 3. **Resource Shrinking Issue**

**Location:** [android/app/build.gradle.kts](android/app/build.gradle.kts)

Resource shrinking (`isShrinkResources = true`) was enabled, which can remove necessary resources and cause UI rendering issues.

**Fix:** Disabled resource shrinking while keeping code minification:

```kotlin
isShrinkResources = false  // Changed from true
```

## How to Test

### Debug Mode (Should work fine)

```bash
flutter run -d <device_id>
```

### Release Mode (Now should be fixed)

```bash
flutter run -d <device_id> --release
```

### Build and Deploy

```bash
# Android
flutter build apk --release
flutter build aab --release

# iOS
flutter build ios --release
```

## What to Look For

If you still see issues:

1. **Grey screen on launch**: Check `flutter run --release -v` for error logs
2. **Navigation not working**: Verify the AuthWrapper is receiving auth state changes
3. **Specific screen grey**: Check that screen's build method for missing error handling

## Additional Notes

- The app now properly displays loading and error states during initialization
- ProGuard minification is still enabled for code optimization
- Remove sensitive Supabase credentials before production release
- Consider adding Firebase Crashlytics for better error tracking in production
