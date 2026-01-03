import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HeatmapCalendar extends StatelessWidget {
  final Map<DateTime, int> data;
  final int year;
  final Color baseColor;
  final List<Color> intensityColors;
  final double cellSize;
  final double cellMargin;
  final Function(DateTime)? onCellTap;

  const HeatmapCalendar({
    super.key,
    required this.data,
    required this.year,
    this.baseColor = Colors.grey,
    this.intensityColors = const [
      Colors.green,
      Colors.lightGreen,
      Colors.greenAccent,
      Colors.lightGreenAccent,
    ],
    this.cellSize = 16.0,
    this.cellMargin = 2.0,
    this.onCellTap,
  });

  List<DateTime> _getYearDates() {
    final dates = <DateTime>[];
    final start = DateTime(year, 1, 1);
    final end = DateTime(year, 12, 31);

    for (
      var date = start;
      date.isBefore(end.add(const Duration(days: 1)));
      date = date.add(const Duration(days: 1))
    ) {
      dates.add(date);
    }
    return dates;
  }

  Color _getCellColor(DateTime date) {
    final value = data[date] ?? 0;
    if (value == 0) return baseColor;

    final intensity = value.clamp(1, intensityColors.length);
    return intensityColors[intensity - 1];
  }

  Widget _buildMonthLabel(int month) {
    return SizedBox(
      width: 50,
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Text(
          DateFormat('MMM').format(DateTime(year, month)),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
      ),
    );
  }

  Widget _buildHeatmapGrid() {
    final dates = _getYearDates();
    final gridData = <int, List<Widget>>{};

    // Group dates by month
    for (final date in dates) {
      final month = date.month;
      if (!gridData.containsKey(month)) {
        gridData[month] = [];
      }

      final weekday = date.weekday;
      // Add empty cells for days before the 1st of the month
      if (date.day == 1 && weekday > 1) {
        for (int i = 1; i < weekday; i++) {
          gridData[month]!.add(
            Container(
              width: cellSize,
              height: cellSize,
              margin: EdgeInsets.all(cellMargin),
            ),
          );
        }
      }

      gridData[month]!.add(
        GestureDetector(
          onTap: () => onCellTap?.call(date),
          child: Tooltip(
            message:
                '${DateFormat('MMM d, yyyy').format(date)}\n'
                'Completions: ${data[date] ?? 0}',
            child: Container(
              width: cellSize,
              height: cellSize,
              margin: EdgeInsets.all(cellMargin),
              decoration: BoxDecoration(
                color: _getCellColor(date),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(12, (monthIndex) {
          final month = monthIndex + 1;
          return Column(
            children: [
              _buildMonthLabel(month),
              const SizedBox(height: 8),
              SizedBox(
                width: 7 * (cellSize + 2 * cellMargin),
                child: Wrap(
                  spacing: 0,
                  runSpacing: 0,
                  children: gridData[month] ?? [],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeatmapGrid(),
        const SizedBox(height: 16),
        _buildLegend(),
      ],
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activity Intensity:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildLegendItem('None', baseColor),
            ...List.generate(intensityColors.length, (index) {
              return _buildLegendItem('${index + 1}+', intensityColors[index]);
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
