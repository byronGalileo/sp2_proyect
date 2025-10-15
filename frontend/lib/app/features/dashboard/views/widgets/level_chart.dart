import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../config/app_config.dart';
import '../../../../utils/services/log_service.dart';

class LevelChart extends StatelessWidget {
  final String level;
  final List<LogDataPoint> dataPoints;
  final Color color;
  final int selectedHours;

  const LevelChart({
    super.key,
    required this.level,
    required this.dataPoints,
    required this.color,
    required this.selectedHours,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.padding * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  level,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: dataPoints.isEmpty
                  ? const Center(
                      child: Text('No data available'),
                    )
                  : LineChart(
                      _buildChartData(context),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildChartData(BuildContext context) {
    final spots = dataPoints
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble()))
        .toList();

    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          color: color,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: dataPoints.length <= 24,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: color,
                strokeWidth: 0,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: selectedHours <= 48 ? 40 : 35,
            interval: _getInterval(),
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < dataPoints.length) {
                final timestamp = dataPoints[value.toInt()].timestamp;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Transform.rotate(
                    angle: -0.5,
                    child: Text(
                      _formatTimestamp(timestamp),
                      style: const TextStyle(fontSize: 9),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 1,
        verticalInterval: _getInterval(),
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          );
        },
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toInt()} $level logs',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    if (selectedHours <= 24) {
      // Show HH:MM for periods up to 24 hours (6h, 12h, 24h)
      return DateFormat('HH:mm').format(timestamp);
    } else if (selectedHours <= 48) {
      // Show MMM DD HH AM/PM for 2 days (48h)
      return DateFormat('MMM dd hh a').format(timestamp);
    } else {
      // Show MMM DD for 7 days and longer
      return DateFormat('MMM dd').format(timestamp);
    }
  }

  double _getInterval() {
    final length = dataPoints.length;
    if (length <= 12) return 1;
    if (length <= 24) return 2;
    if (length <= 48) return 4;
    return 6;
  }
}
