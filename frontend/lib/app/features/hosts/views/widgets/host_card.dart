import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:get/get.dart';
import '../../../../config/app_config.dart';
import '../../../../models/host.dart';

class HostCard extends StatelessWidget {
  final Host host;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onViewServices;
  final VoidCallback? onAddService;
  final VoidCallback? onGenerateConfig;

  const HostCard({
    super.key,
    required this.host,
    required this.onEdit,
    required this.onDelete,
    this.onViewServices,
    this.onAddService,
    this.onGenerateConfig,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getStatusColor(host.status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    host.hostname,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(EvaIcons.activity, size: 18),
                  onPressed: onViewServices ??
                      () => Get.toNamed('/services/managed-services',
                          arguments: {'hostId': host.hostId}),
                  tooltip: 'View Services',
                  color: Colors.blue,
                ),
                IconButton(
                  icon: const Icon(EvaIcons.edit2Outline, size: 18),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(EvaIcons.trash2Outline, size: 18),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: EvaIcons.monitorOutline,
              label: 'Host ID',
              value: host.hostId,
            ),
            _buildInfoRow(
              context,
              icon: EvaIcons.wifi,
              label: 'IP Address',
              value: host.ipAddress,
            ),
            _buildInfoRow(
              context,
              icon: EvaIcons.globe,
              label: 'Environment',
              value: host.environment,
              badge: true,
            ),
            _buildInfoRow(
              context,
              icon: EvaIcons.pinOutline,
              label: 'Region',
              value: host.region,
            ),
            if (host.metadata.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: host.metadata.tags.map((tag) {
                  return Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 10)),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAddService ??
                        () {
                          // Navigate to services screen with dialog open
                          Get.toNamed('/services/managed-services',
                              arguments: {'hostId': host.hostId, 'openDialog': true});
                        },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Service'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onGenerateConfig,
                    icon: const Icon(EvaIcons.fileTextOutline, size: 16),
                    label: const Text('Gen Config'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last seen: ${_formatTimestamp(host.lastSeen)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(host.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    host.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(host.status),
                    ),
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
    bool badge = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          if (badge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            )
          else
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
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
