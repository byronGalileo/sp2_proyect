import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:get/get.dart';
import '../../../../config/app_config.dart';
import '../../../../models/host.dart';

class HostTable extends StatelessWidget {
  final List<Host> hosts;
  final Function(Host) onEdit;
  final Function(Host) onDelete;
  final Function(Host) onAddService;
  final Function(Host)? onViewServices;

  const HostTable({
    super.key,
    required this.hosts,
    required this.onEdit,
    required this.onDelete,
    required this.onAddService,
    this.onViewServices,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
            DataColumn(label: Text('Actions')),
          ],
          rows: hosts.map((host) {
            return DataRow(
              cells: [
                DataCell(
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColor(host.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    host.hostId,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(Text(host.hostname)),
                DataCell(Text(host.ipAddress)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      host.environment,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(host.region)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(EvaIcons.person, size: 14),
                      const SizedBox(width: 4),
                      Text('${host.sshConfig.user}:${host.sshConfig.port}'),
                    ],
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 120,
                    child: host.metadata.tags.isNotEmpty
                        ? Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: host.metadata.tags.take(2).map((tag) {
                              return Chip(
                                label: Text(
                                  tag,
                                  style: const TextStyle(fontSize: 9),
                                ),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          )
                        : const Text('—'),
                  ),
                ),
                DataCell(
                  Text(
                    _formatTimestamp(host.lastSeen),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
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
                            : () => Get.toNamed('/services/managed-services',
                                arguments: {'hostId': host.hostId}),
                        tooltip: 'View Services',
                        color: Colors.blue,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(EvaIcons.plusCircleOutline, size: 16),
                        onPressed: () => onAddService(host),
                        tooltip: 'Add Service',
                        color: Colors.green,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(EvaIcons.edit2Outline, size: 16),
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
                        color: Colors.red,
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
