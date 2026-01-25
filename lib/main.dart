import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habit_tracker/screens/auth_screen.dart';
import 'package:habit_tracker/screens/calories_screen.dart';
import 'package:habit_tracker/screens/dashboard_screen.dart';
import 'package:habit_tracker/screens/habits_screen.dart';
import 'package:habit_tracker/screens/insights_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:habit_tracker/services/preferences_service.dart';
import 'package:habit_tracker/services/notification_service.dart';
import 'dart:developer' as developer;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Preferences Service
    await PreferencesService().init();
    developer.log('Preferences Service initialized', name: 'main');

    // Initialize Notification Service
    await NotificationService().initialize();
    developer.log('Notification Service initialized', name: 'main');

    // Initialize Supabase - REPLACE WITH YOUR CREDENTIALS
    await Supabase.initialize(
      url: 'https://lljkeerrtanuoghevpvu.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxsamtlZXJydGFudW9naGV2cHZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc0MTI1NzksImV4cCI6MjA4Mjk4ODU3OX0.GirklFipK6Ood8iCcI2sSaEr8D_FpvRZ15yib7cF1Kc',
    );
    developer.log('Supabase initialized', name: 'main');

    // Schedule initial notifications if enabled
    final preferencesService = PreferencesService();
    final notificationService = NotificationService();

    if (preferencesService.isWaterRemindersEnabled()) {
      try {
        await notificationService.scheduleHourlyWaterReminders();
        developer.log('Water reminders scheduled', name: 'main');
      } catch (e) {
        developer.log(
          'Error scheduling water reminders: $e',
          name: 'main',
          error: e,
        );
      }
    }

    if (preferencesService.isMealRemindersEnabled()) {
      try {
        await notificationService.scheduleMealReminders(
          breakfastTime: preferencesService.getBreakfastTime(),
          lunchTime: preferencesService.getLunchTime(),
          dinnerTime: preferencesService.getDinnerTime(),
        );
        developer.log('Meal reminders scheduled', name: 'main');
      } catch (e) {
        developer.log(
          'Error scheduling meal reminders: $e',
          name: 'main',
          error: e,
        );
      }
    }

    if (preferencesService.isGymReminderEnabled()) {
      try {
        await notificationService.scheduleGymReminder(
          preferencesService.getGymTime(),
        );
        developer.log('Gym reminder scheduled', name: 'main');
      } catch (e) {
        developer.log(
          'Error scheduling gym reminder: $e',
          name: 'main',
          error: e,
        );
      }
    }
  } catch (e) {
    developer.log(
      'Error during app initialization: $e',
      name: 'main',
      error: e,
    );
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const HabitTrackerApp());
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF13ec80),
          primary: const Color(0xFF13ec80),
          secondary: const Color(0xFF0fb863),
        ),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: GoogleFonts.inter().fontFamily,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF13ec80),
          primary: const Color(0xFF13ec80),
          secondary: const Color(0xFF0fb863),
          brightness: Brightness.dark,
          background: const Color(0xFF101010),
          surface: const Color(0xFF1c1c1c),
        ),
        scaffoldBackgroundColor: const Color(0xFF101010),
        fontFamily: GoogleFonts.inter().fontFamily,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Handle error state
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Connection Error',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Unable to connect. Please check your internet connection.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Trigger rebuild
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Check auth state
        if (snapshot.hasData && snapshot.data?.session != null) {
          return const MainNavigator();
        }

        // Default to auth screen
        return const AuthScreen();
      },
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const CaloriesScreen(),
    const HabitsScreen(),
    const InsightsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.restaurant_rounded,
                  label: 'Log',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.check_circle_rounded,
                  label: 'Habits',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                // Quick add action
              },
              backgroundColor: const Color(0xFF13ec80),
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF13ec80).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF13ec80) : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF13ec80) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
