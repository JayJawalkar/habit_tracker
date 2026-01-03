import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:habit_tracker/habit_tracker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CalorieChartScreen extends StatefulWidget {
  const CalorieChartScreen({super.key});

  @override
  State<CalorieChartScreen> createState() => _CalorieChartScreenState();
}

class _CalorieChartScreenState extends State<CalorieChartScreen> {
  final supabase = Supabase.instance.client;
  List<CalorieEntry> calorieEntries = [];
  Map<String, int> dailyCalories = {};
  String selectedTimeframe = '7 days';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCalorieData();
  }

  String get userId => supabase.auth.currentUser!.id;

  Future<void> _loadCalorieData() async {
    setState(() => isLoading = true);

    try {
      DateTime startDate;
      switch (selectedTimeframe) {
        case '30 days':
          startDate = DateTime.now().subtract(const Duration(days: 30));
          break;
        case '3 months':
          startDate = DateTime.now().subtract(const Duration(days: 90));
          break;
        default: // 7 days
          startDate = DateTime.now().subtract(const Duration(days: 7));
      }

      final response = await supabase
          .from('calories')
          .select()
          .eq('user_id', userId)
          .gte('created_at', startDate.toIso8601String())
          .order('created_at', ascending: true);

      setState(() {
        calorieEntries = (response as List)
            .map((item) => CalorieEntry.fromJson(item))
            .toList();

        // Group by date
        dailyCalories = {};
        for (var entry in calorieEntries) {
          final date = DateTime.parse(entry.createdAt);
          final dateKey = DateFormat('MMM d').format(date);
          dailyCalories.update(
            dateKey,
            (value) => value + entry.calories,
            ifAbsent: () => entry.calories,
          );
        }

        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading calorie chart data: $e');
      setState(() => isLoading = false);
    }
  }

  List<FlSpot> _getChartData() {
    final sortedDates = dailyCalories.keys.toList()
      ..sort((a, b) {
        try {
          final dateA = DateFormat('MMM d').parse(a);
          final dateB = DateFormat('MMM d').parse(b);
          return dateA.compareTo(dateB);
        } catch (e) {
          return 0;
        }
      });

    return List.generate(sortedDates.length, (index) {
      return FlSpot(
        index.toDouble(),
        dailyCalories[sortedDates[index]]!.toDouble(),
      );
    });
  }

  Widget _buildLineChart() {
    final chartData = _getChartData();

    if (chartData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No calorie data available',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Add calorie entries to see the chart',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}');
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final sortedDates = dailyCalories.keys.toList()
                    ..sort((a, b) {
                      try {
                        final dateA = DateFormat('MMM d').parse(a);
                        final dateB = DateFormat('MMM d').parse(b);
                        return dateA.compareTo(dateB);
                      } catch (e) {
                        return 0;
                      }
                    });

                  if (value.toInt() < sortedDates.length &&
                      value.toInt() >= 0) {
                    final date = sortedDates[value.toInt()];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(date, style: const TextStyle(fontSize: 10)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: chartData,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withAlpha(38),
              ),
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calorie Chart'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                selectedTimeframe = value;
                _loadCalorieData();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7 days', child: Text('Last 7 days')),
              const PopupMenuItem(
                value: '30 days',
                child: Text('Last 30 days'),
              ),
              const PopupMenuItem(
                value: '3 months',
                child: Text('Last 3 months'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(selectedTimeframe),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCalorieData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Calorie Consumption Trend',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildLineChart(),
                          const SizedBox(height: 16),
                          if (dailyCalories.isNotEmpty) _buildStatsSummary(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRecentEntries(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsSummary() {
    final values = dailyCalories.values.toList();
    final maxCalories = values.isNotEmpty
        ? values.reduce((a, b) => a > b ? a : b)
        : 0;
    final minCalories = values.isNotEmpty
        ? values.reduce((a, b) => a < b ? a : b)
        : 0;
    final average = values.isNotEmpty
        ? values.reduce((a, b) => a + b) ~/ values.length
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Summary',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatCard('Average', '$average kcal', Icons.trending_up),
            _buildStatCard('Max', '$maxCalories kcal', Icons.arrow_upward),
            _buildStatCard('Min', '$minCalories kcal', Icons.arrow_downward),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 24, color: Colors.green),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentEntries() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Entries',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...calorieEntries.take(5).map((entry) {
              final date = DateTime.parse(entry.createdAt);
              final formatted = DateFormat('MMM dd, HH:mm').format(date);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.green[100],
                  child: const Icon(Icons.restaurant, size: 20),
                ),
                title: Text(entry.mealName),
                subtitle: Text(formatted),
                trailing: Text(
                  '${entry.calories} kcal',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
