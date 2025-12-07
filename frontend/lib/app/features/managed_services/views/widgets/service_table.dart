import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import '../../../../config/app_config.dart';
import '../../../../config/themes/app_theme.dart';
import '../../../../models/managed_service.dart';
import '../../controllers/managed_services_controller.dart';
import 'managed_service_pagination_footer.dart';

class ServiceTable extends StatelessWidget {
  final List<ManagedService> services;
  final Function(ManagedService) onEdit;
  final Function(ManagedService) onDelete;
  final Function(ManagedService)? onNotification;

  const ServiceTable({
    super.key,
    required this.services,
    required this.onEdit,
    required this.onDelete,
    this.onNotification,
    required this.controller,
  });

  final ManagedServicesController controller;

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
            mainAxisSize: MainAxisSize.min,
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
                      fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              headingRowColor: WidgetStateProperty.all(
                Theme.of(context).scaffoldBackgroundColor.withOpacity(0.2),
              ),
              columns: const [
                DataColumn(label: Text('Service Name')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Host ID')),
                DataColumn(label: Text('Environment')),
                DataColumn(label: Text('Region')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Monitoring')),
                DataColumn(label: Text('Actions')),
              ],
              rows: services.map((service) {
                return DataRow(cells: [
                  DataCell(
                    Text(service.displayName ?? service.serviceName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                  ),
                  DataCell(Text(service.serviceType)),
                  DataCell(Text(service.hostId)),
                  DataCell(Text(service.environment)),
                  DataCell(Text(service.region)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(service.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        service.status ?? 'unknown',
                        style: TextStyle(
                          color: _getStatusColor(service.status),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (service.monitoring.enabled
                                ? AppColors.success
                                : AppColors.textSecondary)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        service.monitoring.enabled ? 'Enabled' : 'Disabled',
                        style: TextStyle(
                          color: service.monitoring.enabled
                              ? AppColors.success
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit,
                              size: 20, color: AppColors.textSecondary),
                          onPressed: () => onEdit(service),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: AppColors.error, size: 20),
                          onPressed: () => onDelete(service),
                          tooltip: 'Delete',
                        ),
                        IconButton(
                          icon: const Icon(EvaIcons.bellOutline,
                              size: 20, color: AppColors.textSecondary),
                          onPressed: () => onNotification?.call(service),
                          tooltip: 'Notifications',
                        ),
                      ],
                    ),
                  ),
                ]);
              }).toList(),
            ),
            ),
          ),
              const SizedBox(height: 16),
              ManagedServicePaginationFooter(controller: controller),
            ],
          ),
        ),
      ),
    );
  }

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
}