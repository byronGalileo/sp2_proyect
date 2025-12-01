import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../config/app_config.dart';
import '../../../../config/themes/app_theme.dart';
import '../../controllers/logs_controller.dart';
import 'logs_pagination_footer.dart';

class LogsTable extends StatelessWidget {
  final LogsController controller;

  const LogsTable({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConfig.padding),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            ),
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        Theme.of(context).primaryColor.withOpacity(0.1),
                      ),
                      columnSpacing: 24,
                      columns: const [
                        DataColumn(label: Text('Timestamp')),
                        DataColumn(label: Text('Level')),
                        DataColumn(label: Text('Service')),
                        DataColumn(label: Text('Host')),
                        DataColumn(label: Text('Message')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: controller.logs.map((log) {
                        return DataRow(
                          cells: [
                            DataCell(_buildTimestampCell(log.timestamp)),
                            DataCell(_buildLevelBadge(log.logLevel)),
                            DataCell(
                              Text(
                                log.serviceName,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ),
                            DataCell(Text(log.host ?? 'N/A')),
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 400),
                                child: Tooltip(
                                  message: log.message,
                                  child: Text(
                                    log.message,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              log.serviceType != null && log.serviceType != 'unknown'
                                  ? Chip(
                                      backgroundColor: AppColors.primaryBase.withOpacity(0.1),
                                      label: Text(
                                        log.serviceType!,
                                        style: const TextStyle(fontSize: 10, color: AppColors.textOnPrimary),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    )
                                  : const Text('Unknown'),
                            ),
                            DataCell(
                              Tooltip(
                                message: log.sentToUser ? 'Sent to user' : 'Not sent',
                                child: Icon(
                                  log.sentToUser ? EvaIcons.checkmarkCircle2 : EvaIcons.clockOutline,
                                  size: 20,
                                  color: log.sentToUser ? AppColors.success : AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LogsPaginationFooter(controller: controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimestampCell(String timestamp) {
    final dateFormat = DateFormat('MMM dd, HH:mm:ss');
    try {
      final dt = DateTime.parse(timestamp);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dateFormat.format(dt),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      );
    } catch (e) {
      return Text(timestamp);
    }
  }

  Widget _buildLevelBadge(String level) {
    final color = _getLevelColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        level,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
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
}
