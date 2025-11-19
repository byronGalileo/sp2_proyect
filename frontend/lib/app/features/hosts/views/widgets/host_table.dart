import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:get/get.dart';
import '../../../../config/themes/app_theme.dart';
import '../../../../config/app_config.dart';
import '../../../../models/host.dart';
import '../../controllers/hosts_controller.dart';
import '../../../managed_services/controllers/managed_services_controller.dart';

class HostTable extends StatelessWidget {
  final List<Host> hosts;
  final Function(Host) onEdit;
  final Function(Host) onDelete;
  final Function(Host) onAddService;
  final Function(Host)? onViewServices;
  final Function(Host)? onGenerateConfig;
  final Function(Host)? onStartExecution;
  final Function(Host)? onStopExecution;

  const HostTable({
    super.key,
    required this.hosts,
    required this.onEdit,
    required this.onDelete,
    required this.onAddService,
    this.onViewServices,
    this.onGenerateConfig,
    this.onStartExecution,
    this.onStopExecution,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HostsController>();

    return Card(
      color: Theme.of(context).cardColor,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        side: BorderSide(color: AppColors.border.withOpacity(0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(
                  fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          headingRowColor: WidgetStateProperty.all(
            Theme.of(context).scaffoldBackgroundColor.withOpacity(0.2),
          ),
          dataTextStyle:
              Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
          columns: const [
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Host ID')),
            DataColumn(label: Text('Hostname')),
            DataColumn(label: Text('IP Address')),
            DataColumn(label: Text('Environment')),
            DataColumn(label: Text('Region')),
            DataColumn(label: Text('SSH User')),
            DataColumn(label: Text('Tags')),
            DataColumn(label: Text('Last Seen')),
            DataColumn(label: Text('Configs')),
            DataColumn(label: Text('Actions')),
          ],
          rows: hosts.map((host) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: _getStatusColor(host.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Obx(() {
                        final isRunning = controller.monitoringStatus[host.hostId] ?? false;

                        if (isRunning) {
                          // Show Stop button
                          return IconButton(
                            icon: const Icon(EvaIcons.stopCircleOutline, size: 16),
                            onPressed: onStopExecution != null
                                ? () => onStopExecution!(host)
                                : null,
                            tooltip: 'Stop Monitoring',
                            color: AppColors.error,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          );
                        } else {
                          // Show Start button
                          return IconButton(
                            icon: const Icon(EvaIcons.playCircleOutline, size: 16),
                            onPressed: onStartExecution != null
                                ? () => onStartExecution!(host)
                                : null,
                            tooltip: 'Start Monitoring',
                            color: AppColors.success,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          );
                        }
                      }),
                    ]
                  )
                ),
                DataCell(
                  Text(
                    host.hostId,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                DataCell(Text(host.hostname)),
                DataCell(Text(host.ipAddress)),
                DataCell(
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBase.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      host.environment,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBase,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(host.region)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(EvaIcons.person,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('${host.sshConfig.user}:${host.sshConfig.port}'),
                    ],
                  ),
                ),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: host.metadata.tags.isNotEmpty
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: host.metadata.tags.take(2).map((tag) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: Chip(
                                  backgroundColor: AppColors.primaryBase.withOpacity(0.1),
                                  label: Text(
                                    tag,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textOnPrimary,
                                    ),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                ),
                              );
                            }).toList(),
                          )
                        : const Text('—'),
                  ),
                ),
                DataCell(
                  Text(
                    _formatTimestamp(host.lastSeen),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(EvaIcons.plusCircleOutline, size: 16),
                        onPressed: () => onAddService(host),
                        tooltip: 'Add Service',
                        color: AppColors.success,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(EvaIcons.fileTextOutline, size: 16),
                        onPressed: onGenerateConfig != null
                            ? () => onGenerateConfig!(host)
                            : null,
                        tooltip: 'Generate Config',
                        color: AppColors.accentAmber,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(EvaIcons.activity, size: 16),
                        onPressed: onViewServices != null
                            ? () => onViewServices!(host)
                            : () {
                                // Delete existing controller if it exists to force fresh initialization
                                try {
                                  Get.delete<ManagedServicesController>(force: true);
                                } catch (e) {
                                  // Controller doesn't exist yet, that's fine
                                }
                                // Navigate with arguments
                                Get.toNamed('/services/managed-services',
                                    arguments: {'hostId': host.hostId});
                              },
                        tooltip: 'View Services',
                        color: AppColors.info,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(EvaIcons.edit2Outline, size: 16),
                        color: AppColors.textSecondary,
                        onPressed: () => onEdit(host),
                        tooltip: 'Edit',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(EvaIcons.trash2Outline, size: 16),
                        onPressed: () => onDelete(host),
                        tooltip: 'Delete',
                        color: AppColors.error,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'inactive':
        return AppColors.textSecondary;
      case 'maintenance':
        return AppColors.warning;
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
