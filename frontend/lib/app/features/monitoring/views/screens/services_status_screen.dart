import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import '../../../../config/app_config.dart';
import '../../../../config/themes/app_theme.dart';
import '../../../../shared_components/responsive_builder.dart';
import '../../../../shared_components/widgets/loading_widget.dart';
import '../../../../shared_components/base_screen_wrapper.dart';
import '../../controllers/services_controller.dart';
import '../../controllers/logs_controller.dart';
import '../widgets/service_card.dart';
import '../widgets/services_statistics.dart';

class ServicesStatusScreen extends StatelessWidget {
  const ServicesStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ServicesController>();

    return BaseScreenWrapper(
      child: ResponsiveBuilder(
        mobileBuilder: (context, constraints) {
          return _buildMobileLayout(context, controller);
        },
        tabletBuilder: (context, constraints) {
          return _buildTabletLayout(context, controller);
        },
        desktopBuilder: (context, constraints) {
          return _buildDesktopLayout(context, controller);
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, ServicesController controller) {
    return Column(
      children: [
        _buildHeader(context, controller, showMenuButton: true),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.services.isEmpty) {
              return const Center(child: LoadingWidget());
            }

            if (controller.errorMessage.value.isNotEmpty && controller.services.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(EvaIcons.alertCircle, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading services',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textOnPrimary),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppConfig.padding),
                      child: Text(
                        controller.errorMessage.value,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: controller.refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (controller.services.isEmpty) {
              return const Center(child: Text('No services found'));
            }

            return RefreshIndicator(
              onRefresh: controller.refresh,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConfig.padding),
                child: Column(
                  children: [
                    ServicesStatistics(
                      totalServices: controller.statistics['totalServices']!,
                      totalLogs: controller.statistics['totalLogs']!,
                      totalUnsentLogs: controller.statistics['totalUnsentLogs']!,
                    ),
                    const SizedBox(height: 16),
                    ...controller.filteredServices.map(
                      (service) => ServiceCard(service: service),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, ServicesController controller) {
    return Column(
      children: [
        _buildHeader(context, controller),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.services.isEmpty) {
              return const Center(child: LoadingWidget());
            }

            if (controller.errorMessage.value.isNotEmpty && controller.services.isEmpty) {
              return _buildErrorState(context, controller);
            }

            if (controller.services.isEmpty) {
              return const Center(child: Text('No services found'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConfig.padding),
              child: Column(
                children: [
                  ServicesStatistics(
                    totalServices: controller.statistics['totalServices']!,
                    totalLogs: controller.statistics['totalLogs']!,
                    totalUnsentLogs: controller.statistics['totalUnsentLogs']!,
                  ),
                  const SizedBox(height: 16),
                  _buildServicesTable(context, controller),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, ServicesController controller) {
    return Column(
      children: [
        _buildHeader(context, controller),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.services.isEmpty) {
              return const Center(child: LoadingWidget());
            }

            if (controller.errorMessage.value.isNotEmpty && controller.services.isEmpty) {
              return _buildErrorState(context, controller);
            }

            if (controller.services.isEmpty) {
              return const Center(child: Text('No services found'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConfig.padding * 2),
              child: Column(
                children: [
                  ServicesStatistics(
                    totalServices: controller.statistics['totalServices']!,
                    totalLogs: controller.statistics['totalLogs']!,
                    totalUnsentLogs: controller.statistics['totalUnsentLogs']!,
                  ),
                  const SizedBox(height: 24),
                  _buildServicesTable(context, controller),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ServicesController controller, {bool showMenuButton = false}) {
    return Container(
      padding: const EdgeInsets.all(AppConfig.padding),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (showMenuButton) ...[
                const DrawerMenuButton(),
                const SizedBox(width: 8),
              ],
              const Icon(EvaIcons.activity, size: 24, color: AppColors.accentOrange),
              const SizedBox(width: 12),
              Text(
                'Services Status',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Obx(() {
                if (controller.lastUpdated.value.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      'Last updated: ${_formatLastUpdated(controller.lastUpdated.value)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textLight),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              IconButton(
                icon: Obx(() => controller.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, color: AppColors.textOnPrimary)),
                onPressed: controller.isLoading.value ? null : controller.refresh,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatLastUpdated(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  Widget _buildErrorState(BuildContext context, ServicesController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(EvaIcons.alertCircle, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Error loading services',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textOnPrimary),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConfig.padding * 2),
            child: Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTable(BuildContext context, ServicesController controller) {
    return Card(
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
          dataTextStyle: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary, fontSize: 13),
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
          rows: controller.filteredServices.map((service) {
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
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                DataCell(Text(service.host ?? 'N/A')),
                DataCell(
                  service.latestLevel != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getLevelColor(service.latestLevel).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            service.latestLevel!,
                            style: TextStyle( // Use _getLevelColor for text
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _getLevelColor(service.latestLevel),
                            ),
                          ),
                        )
                      : const Text('N/A'),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (service.unsentLogs > 0 ? AppColors.warning : AppColors.textSecondary).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      service.unsentLogs.toString(),
                      style: TextStyle( // Use semantic colors for unsent logs
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: service.unsentLogs > 0 ? AppColors.warning : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  service.serviceType != null && service.serviceType != 'unknown'
                      ? Chip(
                          backgroundColor: AppColors.primaryBase.withOpacity(0.1),
                          label: Text(
                            service.serviceType ?? 'unknown',
                            style: const TextStyle(fontSize: 10, color: AppColors.textOnPrimary),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                      Get.toNamed('/monitoring/logs', arguments: {'serviceName': service.id});
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
                ),
              ],
            );
          }).toList(),
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
