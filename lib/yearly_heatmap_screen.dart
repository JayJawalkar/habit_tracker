import 'package:flutter/material.dart';
import 'package:habit_tracker/heatmap_calender.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class YearlyHeatmapScreen extends StatefulWidget {
  const YearlyHeatmapScreen({super.key});

  @override
  State<YearlyHeatmapScreen> createState() => _YearlyHeatmapScreenState();
}

class _YearlyHeatmapScreenState extends State<YearlyHeatmapScreen> {
  final supabase = Supabase.instance.client;
  Map<DateTime, int> heatmapData = {};
  bool isLoading = true;
  int selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadYearlyData();
  }

  String get userId => supabase.auth.currentUser!.id;

  Future<void> _loadYearlyData() async {
    setState(() => isLoading = true);

    try {
      final startDate = DateTime(selectedYear, 1, 1);
      final endDate = DateTime(selectedYear, 12, 31);

      final response = await supabase
          .from('habits')
          .select()
          .eq('user_id', userId)
          .gte('date', DateFormat('yyyy-MM-dd').format(startDate))
          .lte('date', DateFormat('yyyy-MM-dd').format(endDate));

      // Reset data
      heatmapData = {};

      // Initialize all dates in the year with 0
      for (
        var date = startDate;
        date.isBefore(endDate.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))
      ) {
        heatmapData[date] = 0;
      }

      // Count habits per day
      for (var item in response) {
        final date = DateTime.parse(item['date']);
        heatmapData.update(date, (value) => value + 1, ifAbsent: () => 1);
      }

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('Error loading yearly data: $e');
      setState(() => isLoading = false);
    }
  }

  Widget _buildStatsCard() {
    final totalCompletions = heatmapData.values.fold(
      0,
      (sum, completions) => sum + completions,
    );
    final activeDays = heatmapData.values
        .where((completions) => completions > 0)
        .length;
    final currentStreak = _calculateCurrentStreak();
    final bestStreak = _calculateBestStreak();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Yearly Stats',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                DropdownButton<int>(
                  value: selectedYear,
                  items: List.generate(5, (index) {
                    final year = DateTime.now().year - index;
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedYear = value;
                        _loadYearlyData();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Total', '$totalCompletions\ncompletions'),
                _buildStatItem('Active', '$activeDays\ndays'),
                _buildStatItem('Current', '$currentStreak days\nstreak'),
                _buildStatItem('Best', '$bestStreak days\nstreak'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _calculateCurrentStreak() {
    final now = DateTime.now();
    var currentDate = DateTime(now.year, now.month, now.day);
    var streak = 0;

    while (heatmapData.containsKey(currentDate) &&
        heatmapData[currentDate]! > 0) {
      streak++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int _calculateBestStreak() {
    final dates = heatmapData.keys.toList()..sort();
    var bestStreak = 0;
    var currentStreak = 0;

    for (final date in dates) {
      if (heatmapData[date]! > 0) {
        currentStreak++;
        if (currentStreak > bestStreak) {
          bestStreak = currentStreak;
        }
      } else {
        currentStreak = 0;
      }
    }

    return bestStreak;
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yearly Heatmap')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadYearlyData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatsCard(),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Habit Activity Heatmap',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Showing activity for $selectedYear',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),
                          HeatmapCalendar(
                            data: heatmapData,
                            year: selectedYear,
                            baseColor: Colors.grey[200]!,
                            intensityColors: [
                              Colors.green[100]!,
                              Colors.green[300]!,
                              Colors.green[500]!,
                              Colors.green[700]!,
                            ],
                            cellSize: 18.0,
                            cellMargin: 1.0,
                            onCellTap: (date) {
                              final completions = heatmapData[date] ?? 0;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${DateFormat('MMM d, yyyy').format(date)}\n'
                                    'Habit completions: $completions',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
