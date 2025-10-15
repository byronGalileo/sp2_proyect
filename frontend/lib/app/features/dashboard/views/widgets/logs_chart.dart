import 'package:flutter/material.dart';
import '../../../../config/app_config.dart';
import '../../../../utils/services/log_service.dart';
import 'level_chart.dart';

class LogsChart extends StatelessWidget {
  final Map<String, List<LogDataPoint>> logsData;
  final int selectedHours;

  const LogsChart({
    super.key,
    required this.logsData,
    required this.selectedHours,
  });

  @override
  Widget build(BuildContext context) {
    final levelColors = {
      'INFO': Colors.blue,
      'WARNING': Colors.orange,
      'ERROR': Colors.red,
      'CRITICAL': Colors.purple,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConfig.padding),
          child: Text(
            'Logs Over Time by Level',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;
            final isDesktop = constraints.maxWidth > 900;

            if (isDesktop) {
              // Desktop: 2x2 grid
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: levelColors.entries.map((entry) {
                  return LevelChart(
                    level: entry.key,
                    dataPoints: logsData[entry.key] ?? [],
                    color: entry.value,
                    selectedHours: selectedHours,
                  );
                }).toList(),
              );
            } else if (isCompact) {
              // Mobile: 1 column
              return Column(
                children: levelColors.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SizedBox(
                      height: 250,
                      child: LevelChart(
                        level: entry.key,
                        dataPoints: logsData[entry.key] ?? [],
                        color: entry.value,
                        selectedHours: selectedHours,
                      ),
                    ),
                  );
                }).toList(),
              );
            } else {
              // Tablet: 2 columns
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: levelColors.entries.map((entry) {
                  return LevelChart(
                    level: entry.key,
                    dataPoints: logsData[entry.key] ?? [],
                    color: entry.value,
                    selectedHours: selectedHours,
                  );
                }).toList(),
              );
            }
          },
        ),
      ],
    );
  }
}
