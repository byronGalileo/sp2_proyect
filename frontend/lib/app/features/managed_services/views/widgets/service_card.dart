import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:get/get.dart';
import '../../../../config/app_config.dart';
import '../../../../config/themes/app_theme.dart';
import '../../../../models/managed_service.dart';
import '../../../../features/monitoring/controllers/logs_controller.dart'; // Needed for navigation to logs

class ServiceCard extends StatelessWidget {
  final ManagedService service;
  final Function(ManagedService) onEdit;
  final Function(ManagedService) onDelete;
  final Function(ManagedService)? onViewLogs;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onEdit,
    required this.onDelete,
    this.onViewLogs,
  });

  // Helper to get status color, similar to _getStatusColor in ManagedServicesScreen
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'running':
        return AppColors.success;
      case 'stopped':
        return AppColors.warning;
      case 'error':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'N/A';
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        side: BorderSide(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Status, Service Name, Actions
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getStatusColor(service.status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    service.displayName ?? service.serviceName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 20, color: AppColors.textSecondary),
                          const SizedBox(width: 12),
                          const Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 20, color: AppColors.error),
                          const SizedBox(width: 12),
                          const Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit(service);
                    } else if (value == 'delete') {
                      onDelete(service);
                    }
                  },
                ),
              ],
            ),
            const Divider(height: 24),

            // Info Rows
            _buildInfoRow(
              context,
              icon: EvaIcons.cubeOutline,
              label: 'Service ID',
              value: service.serviceId,
            ),
            _buildInfoRow(
              context,
              icon: EvaIcons.monitorOutline,
              label: 'Host ID',
              value: service.hostId,
            ),
            _buildInfoRow(
              context,
              icon: EvaIcons.layersOutline,
              label: 'Environment',
              value: service.environment,
            ),
            _buildInfoRow(
              context,
              icon: EvaIcons.globe2Outline,
              label: 'Region',
              value: service.region,
            ),
            _buildInfoRow(
              context,
              icon: EvaIcons.activityOutline,
              label: 'Monitoring',
              value: service.monitoring.enabled ? 'Enabled' : 'Disabled',
              valueColor: service.monitoring.enabled ? AppColors.success : AppColors.textSecondary,
            ),
            _buildInfoRow(
              context,
              icon: EvaIcons.alertCircleOutline,
              label: 'Alerting',
              value: service.alerting.enabled ? 'Enabled' : 'Disabled',
              valueColor: service.alerting.enabled ? AppColors.success : AppColors.textSecondary,
            ),

            if (service.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildTagsRow(context, service.tags),
            ],

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last update: ${_formatTimestamp(service.updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    onViewLogs?.call(service);
                  },
                  icon: const Icon(Icons.description, size: 16, color: AppColors.textOnPrimary),
                  label: const Text('Logs'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBase,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: valueColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsRow(BuildContext context, List<String> tags) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(EvaIcons.hashOutline, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          'Tags: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags.map((tag) {
              return Chip(
                backgroundColor: AppColors.primaryBase.withOpacity(0.1),
                label: Text(
                  tag,
                  style: const TextStyle(fontSize: 10, color: AppColors.primaryBase),
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}