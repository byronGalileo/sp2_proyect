import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import '../../../../config/app_config.dart';

class ServicesStatistics extends StatelessWidget {
  final int totalServices;
  final int totalLogs;
  final int totalUnsentLogs;

  const ServicesStatistics({
    super.key,
    required this.totalServices,
    required this.totalLogs,
    required this.totalUnsentLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.padding),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Use compact layout if card width is less than 550px
            final useCompactLayout = constraints.maxWidth < 550;

            if (useCompactLayout) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatCard(
                    context,
                    icon: EvaIcons.activity,
                    label: 'Total Services',
                    value: totalServices.toString(),
                    color: Colors.blue,
                    isCompact: true,
                  ),
                  const Divider(height: 24),
                  _buildStatCard(
                    context,
                    icon: EvaIcons.fileText,
                    label: 'Total Logs',
                    value: totalLogs.toString(),
                    color: Colors.green,
                    isCompact: true,
                  ),
                  const Divider(height: 24),
                  _buildStatCard(
                    context,
                    icon: EvaIcons.alertCircle,
                    label: 'Unsent Logs',
                    value: totalUnsentLogs.toString(),
                    color: totalUnsentLogs > 0 ? Colors.orange : Colors.grey,
                    isCompact: true,
                  ),
                ],
              );
            }

            // Regular horizontal layout
            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: EvaIcons.activity,
                    label: 'Total Services',
                    value: totalServices.toString(),
                    color: Colors.blue,
                  ),
                ),
                Container(
                  height: 60,
                  width: 1,
                  color: Theme.of(context).dividerColor,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: EvaIcons.fileText,
                    label: 'Total Logs',
                    value: totalLogs.toString(),
                    color: Colors.green,
                  ),
                ),
                Container(
                  height: 60,
                  width: 1,
                  color: Theme.of(context).dividerColor,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: EvaIcons.alertCircle,
                    label: 'Unsent Logs',
                    value: totalUnsentLogs.toString(),
                    color: totalUnsentLogs > 0 ? Colors.orange : Colors.grey,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isCompact = false,
  }) {
    if (isCompact) {
      return Row(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ],
    );
  }
}
