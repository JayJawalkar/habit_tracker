import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/supabase_service.dart';
import '../services/preferences_service.dart';
import '../models/macro_data.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final SupabaseService _supabaseService = SupabaseService();
  late final PreferencesService _preferencesService = PreferencesService();
  int calorieGoal = 2000;

  int todayCalories = 0;
  int streakDays = 0;
  bool isLoadingCalories = true;
  bool isLoadingStreak = true;
  bool isLoadingTrend = true;
  List<double> weeklyTrend = List.filled(7, 0.0);
  String? calorieError;
  String? streakError;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    // Initialize preferences service
    await _preferencesService.init();

    if (!mounted) return;

    // Load calorie goal
    setState(() {
      calorieGoal = _preferencesService.getCalorieGoal();
    });

    // Load dashboard data
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    // Load calories
    _loadTodayCalories();

    // Load streak
    _loadStreak();

    // Load weekly trend
    _loadWeeklyTrend();
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    ).then((_) {
      // Refresh goal when returning from settings
      _refreshCalorieGoal();
    });
  }

  void _refreshCalorieGoal() {
    final newGoal = _preferencesService.getCalorieGoal();
    if (newGoal != calorieGoal) {
      setState(() {
        calorieGoal = newGoal;
      });
    }
  }

  Future<void> _loadTodayCalories() async {
    try {
      if (!mounted) return;

      setState(() => isLoadingCalories = true);

      final total = await _supabaseService.getTodayTotalCalories();

      if (mounted) {
        setState(() {
          todayCalories = total;
          isLoadingCalories = false;
          calorieError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          calorieError = 'Failed to load calories';
          isLoadingCalories = false;
          todayCalories = 0;
        });
      }
    }
  }

  Future<void> _loadStreak() async {
    try {
      if (!mounted) return;

      setState(() => isLoadingStreak = true);

      final streak = await _supabaseService.calculateStreak();

      if (mounted) {
        setState(() {
          streakDays = streak;
          isLoadingStreak = false;
          streakError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          streakError = 'Failed to load streak';
          isLoadingStreak = false;
          streakDays = 0;
        });
      }
    }
  }

  Future<void> _loadWeeklyTrend() async {
    try {
      if (!mounted) return;

      setState(() => isLoadingTrend = true);

      final trend = await _supabaseService.getWeeklyCalorieTrend();

      if (mounted) {
        setState(() {
          weeklyTrend = trend.isNotEmpty ? trend : List.filled(7, 0.0);
          isLoadingTrend = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          weeklyTrend = List.filled(7, 0.0);
          isLoadingTrend = false;
        });
      }
    }
  }

  Widget build(BuildContext context) {
    final remaining = (calorieGoal - todayCalories).clamp(0, calorieGoal);
    final progress = (todayCalories / calorieGoal).clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.white.withOpacity(0.9),
              elevation: 0,
              title: const Text(
                'DASHBOARD',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () {},
              ),
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_rounded),
                      onPressed: () {},
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF13ec80),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: _navigateToSettings,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadDashboardData,
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Calorie Ring
                  _buildCalorieRing(progress, remaining),
                  const SizedBox(height: 32),

                  // Macros Grid
                  _buildMacrosGrid(),
                  const SizedBox(height: 32),

                  // Streak Card
                  _buildStreakCard(),
                  const SizedBox(height: 32),

                  // Quick Actions
                  _buildQuickActions(context),
                  const SizedBox(height: 32),

                  // Weekly Trend
                  _buildWeeklyTrend(),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieRing(double progress, int remaining) {
    if (isLoadingCalories) {
      return Center(
        child: SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(240, 240),
                painter: _CalorieRingPainter(0),
              ),
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      );
    }

    if (calorieError != null) {
      return Center(
        child: SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(240, 240),
                painter: _CalorieRingPainter(0),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    calorieError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: SizedBox(
        width: 240,
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ring
            CustomPaint(
              size: const Size(240, 240),
              painter: _CalorieRingPainter(progress),
            ),
            // Center Text
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Remaining',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      remaining.toString(),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'kcal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Goal: ${calorieGoal.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacrosGrid() {
    final macros = [
      MacroData(name: 'Protein', value: 0, goal: 180),
      MacroData(name: 'Carbs', value: 0, goal: 250),
      MacroData(name: 'Fat', value: 0, goal: 70),
    ];

    if (isLoadingCalories || todayCalories == 0) {
      return Row(
        children: macros.map((macro) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    macro.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '0g',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0,
                      minHeight: 4,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(Colors.grey[300]),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    return Row(
      children: macros.map((macro) {
        final progress = (macro.value / macro.goal).clamp(0.0, 1.0);
        const colors = [
          Color(0xFF13ec80),
          Color(0xFF60a5fa),
          Color(0xFFfb923c),
        ];
        final color = colors[macros.indexOf(macro)];

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  macro.name,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${macro.value}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'g',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStreakCard() {
    if (isLoadingStreak) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF7ED), Color(0xFFFEE2E2)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT STREAK',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    width: 60,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFEE2E2)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT STREAK',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  streakDays == 0 ? '0 Days' : '$streakDays Days',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  streakDays == 0
                      ? "Start tracking to build your streak!"
                      : "You're on fire! Keep it up.",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: streakDays == 0 ? Colors.grey[200] : Colors.orange[100],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                streakDays == 0 ? '❄️' : '🔥',
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context,
            title: 'Log Calories',
            icon: '🍽️',
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF4F46E5)],
            ),
            onTap: () {
              // Navigate to calories screen
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            context,
            title: 'Track Habits',
            icon: '✅',
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
            ),
            onTap: () {
              // Navigate to habits screen
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTrend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Weekly Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildTimeButton('7D', true),
                  _buildTimeButton('30D', false),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(16),
          ),
          child: isLoadingTrend
              ? const Center(child: CircularProgressIndicator())
              : weeklyTrend.every((val) => val == 0)
              ? Center(
                  child: Text(
                    'No calorie data yet',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                )
              : CustomPaint(
                  size: const Size(double.infinity, 150),
                  painter: _WeeklyTrendPainter(weeklyTrend),
                ),
        ),
      ],
    );
  }

  Widget _buildTimeButton(String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        boxShadow: isSelected
            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.black : Colors.grey[600],
        ),
      ),
    );
  }
}

// Custom Painter for Calorie Ring
class _CalorieRingPainter extends CustomPainter {
  final double progress;

  _CalorieRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.grey[100]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = const Color(0xFF13ec80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom Painter for Weekly Trend Chart
class _WeeklyTrendPainter extends CustomPainter {
  final List<double> data;

  _WeeklyTrendPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data.every((val) => val == 0)) {
      return;
    }

    final paint = Paint()
      ..color = const Color(0xFF13ec80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = 0.0;
    final range = maxValue == minValue ? 1.0 : maxValue - minValue;

    for (int i = 0; i < data.length; i++) {
      final x = (size.width / (data.length - 1)) * i;
      final normalizedValue = (data[i] - minValue) / range;
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = const Color(0xFF13ec80)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = (size.width / (data.length - 1)) * i;
      final normalizedValue = (data[i] - minValue) / range;
      final y = size.height - (normalizedValue * size.height);
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(_WeeklyTrendPainter oldDelegate) =>
      oldDelegate.data != data;
}
