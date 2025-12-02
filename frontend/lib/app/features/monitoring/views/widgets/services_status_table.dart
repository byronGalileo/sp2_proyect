import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import '../../../../config/app_config.dart';
import '../../../../config/themes/app_theme.dart';
import '../../controllers/services_controller.dart';
import '../../controllers/logs_controller.dart';
import 'pagination_footer.dart';

class ServicesStatusTable extends StatelessWidget {
  final ServicesController controller;

  const ServicesStatusTable({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1400),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          side: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                    headingRowColor: WidgetStateProperty.all(
                      Theme.of(context)
                          .scaffoldBackgroundColor
                          .withOpacity(0.2),
                    ),
                    dataTextStyle: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                            color: AppColors.textSecondary, fontSize: 13),
                    columns: const [
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Service ID')),
                      DataColumn(label: Text('Host')),
                      DataColumn(label: Text('Level')),
                      DataColumn(label: Text('Total Logs')),
                      DataColumn(label: Text('Unsent Logs')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Last Update')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: controller.paginatedServices.map((service) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getLevelColor(service.latestLevel),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              service.id, // Assuming service.id is the service name
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary),
                            ),
                          ),
                          DataCell(Text(service.host ?? 'N/A')),
                          DataCell(
                            service.latestLevel != null
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getLevelColor(service.latestLevel)
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      service.latestLevel!,
                                      style: TextStyle(
                                        // Use _getLevelColor for text
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            _getLevelColor(service.latestLevel),
                                      ),
                                    ),
                                  )
                                : const Text('N/A'),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                service.totalLogs.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.info,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: (service.unsentLogs > 0
                                        ? AppColors.warning
                                        : AppColors.textSecondary)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                service.unsentLogs.toString(),
                                style: TextStyle(
                                  // Use semantic colors for unsent logs
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: service.unsentLogs > 0
                                      ? AppColors.warning
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            service.serviceType != null &&
                                    service.serviceType != 'unknown'
                                ? Chip(
                                    backgroundColor: AppColors.primaryBase
                                        .withOpacity(0.1),
                                    label: Text(
                                      service.serviceType ?? 'unknown',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textOnPrimary),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  )
                                : const Text('Unknown'),
                          ),
                          DataCell(
                            Text(
                              service.latestTimestamp != null
                                  ? _formatTimestamp(service.latestTimestamp!)
                                  : 'N/A',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          DataCell(
                            ElevatedButton.icon(
                              onPressed: () {
                                // Delete existing controller if it exists to force fresh initialization
                                try {
                                  Get.delete<LogsController>(force: true);
                                } catch (e) {
                                  // Controller doesn't exist yet, that's fine
                                }
                                // Navigate with arguments - service.id is the service name in this context
                                Get.toNamed('/monitoring/logs',
                                    arguments: {'serviceName': service.id});
                              },
                              icon: const Icon(Icons.description,
                                  size: 16, color: AppColors.textOnPrimary),
                              label: const Text('Logs'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBase,
                                foregroundColor: AppColors.textOnPrimary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PaginationFooter(controller: controller),
            ],
          ),
        ),
      ),
    );
  }



  Color _getLevelColor(String? level) {
    if (level == null) return Colors.grey;
    switch (level.toUpperCase()) {
      case 'ERROR':
        return AppColors.error;
      case 'WARNING':
        return AppColors.warning;
      case 'INFO':
        return AppColors.info;
      case 'DEBUG':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dt);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return timestamp;
    }
  }
}
