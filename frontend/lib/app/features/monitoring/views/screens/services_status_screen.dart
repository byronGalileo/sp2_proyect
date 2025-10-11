import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import '../../../../config/app_config.dart';
import '../../../../shared_components/responsive_builder.dart';
import '../../../../shared_components/widgets/loading_widget.dart';
import '../../../../shared_components/app_sidebar.dart';
import '../../controllers/services_controller.dart';
import '../widgets/service_card.dart';
import '../widgets/services_statistics.dart';

class ServicesStatusScreen extends StatefulWidget {
  const ServicesStatusScreen({super.key});

  @override
  State<ServicesStatusScreen> createState() => _ServicesStatusScreenState();
}

class _ServicesStatusScreenState extends State<ServicesStatusScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ServicesController>();

    return Scaffold(
      key: _scaffoldKey,
      drawer: ResponsiveBuilder.isDesktop(context)
          ? null
          : Drawer(
              child: SafeArea(
                child: SingleChildScrollView(
                  child: const AppSidebar(),
                ),
              ),
            ),
      body: SafeArea(
        child: ResponsiveBuilder(
          mobileBuilder: (context, constraints) {
            return _buildMobileLayout(context, controller);
          },
          tabletBuilder: (context, constraints) {
            return _buildTabletLayout(context, controller, constraints);
          },
          desktopBuilder: (context, constraints) {
            return _buildDesktopLayout(context, controller, constraints);
          },
        ),
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
                    const Icon(EvaIcons.alertCircle, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading services',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppConfig.padding),
                      child: Text(
                        controller.errorMessage.value,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
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

  Widget _buildTabletLayout(
      BuildContext context, ServicesController controller, BoxConstraints constraints) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: constraints.maxWidth > 1350 ? 3 : 4,
          child: SingleChildScrollView(
            child: AppSidebar(onItemSelected: () => _scaffoldKey.currentState?.closeDrawer()),
          ),
        ),
        const VerticalDivider(width: 1),
        Flexible(
          flex: 7,
          child: Column(
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
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context, ServicesController controller, BoxConstraints constraints) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: constraints.maxWidth > 1350 ? 3 : 4,
          child: SingleChildScrollView(
            child: AppSidebar(onItemSelected: () => _scaffoldKey.currentState?.closeDrawer()),
          ),
        ),
        const VerticalDivider(width: 1),
        Flexible(
          flex: 8,
          child: Column(
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
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ServicesController controller, {bool showMenuButton = false}) {
    return Container(
      padding: const EdgeInsets.all(AppConfig.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (showMenuButton) ...[
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(EvaIcons.activity, size: 24),
              const SizedBox(width: 12),
              Text(
                'Services Status',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              Obx(() {
                if (controller.lastUpdated.value.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      'Last updated: ${_formatLastUpdated(controller.lastUpdated.value)}',
                      style: Theme.of(context).textTheme.bodySmall,
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
                    : const Icon(Icons.refresh)),
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
          const Icon(EvaIcons.alertCircle, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading services',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConfig.padding * 2),
            child: Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
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
                      color: _getStatusColor(service.latestLevel),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    service.id,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(Text(service.host ?? 'N/A')),
                DataCell(
                  service.latestLevel != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(service.latestLevel).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            service.latestLevel!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(service.latestLevel),
                            ),
                          ),
                        )
                      : const Text('N/A'),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      service.totalLogs.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: service.unsentLogs > 0 ? Colors.orange[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      service.unsentLogs.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: service.unsentLogs > 0 ? Colors.orange[700] : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                DataCell(
                  service.serviceType != null && service.serviceType != 'unknown'
                      ? Chip(
                          label: Text(
                            service.serviceType!,
                            style: const TextStyle(fontSize: 10),
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
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                DataCell(
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.toNamed('/monitoring/logs', parameters: {'service': service.id});
                    },
                    icon: const Icon(Icons.description, size: 16),
                    label: const Text('Logs'),
                    style: ElevatedButton.styleFrom(
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

  Color _getStatusColor(String? level) {
    if (level == null) return Colors.grey;
    switch (level.toUpperCase()) {
      case 'ERROR':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      case 'INFO':
        return Colors.blue;
      case 'DEBUG':
        return Colors.green;
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
