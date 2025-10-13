import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import '../../../../config/app_config.dart';
import '../../../../shared_components/responsive_builder.dart';
import '../../../../shared_components/widgets/loading_widget.dart';
import '../../../../shared_components/base_screen_wrapper.dart';
import '../../../../models/managed_service.dart';
import '../../controllers/managed_services_controller.dart';
import '../widgets/service_form_dialog.dart';

class ManagedServicesScreen extends StatelessWidget {
  const ManagedServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ManagedServicesController());

    return BaseScreenWrapper(
      child: ResponsiveBuilder(
        mobileBuilder: (context, constraints) {
          return _buildMobileLayout(context, controller);
        },
        tabletBuilder: (context, constraints) {
          return _buildDesktopLayout(context, controller);
        },
        desktopBuilder: (context, constraints) {
          return _buildDesktopLayout(context, controller);
        },
      ),
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, ManagedServicesController controller) {
    return Column(
      children: [
        _buildHeader(context, controller, showMenuButton: true),
        _buildFilters(context, controller),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.services.isEmpty) {
              return const Center(child: LoadingWidget());
            }

            if (controller.errorMessage.value.isNotEmpty &&
                controller.services.isEmpty) {
              return _buildErrorState(context, controller);
            }

            if (controller.services.isEmpty) {
              return const Center(child: Text('No services found'));
            }

            return RefreshIndicator(
              onRefresh: controller.refresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppConfig.padding),
                itemCount: controller.services.length,
                itemBuilder: (context, index) {
                  final service = controller.services[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        EvaIcons.activity,
                        color: _getStatusColor(service.status),
                      ),
                      title: Text(service.displayName ?? service.serviceName),
                      subtitle: Text(
                        'Type: ${service.serviceType} | Host: ${service.hostId}',
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showServiceDialog(context, service: service);
                          } else if (value == 'delete') {
                            controller.deleteService(service.serviceId);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
        _buildPagination(context, controller),
      ],
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context, ManagedServicesController controller) {
    return Column(
      children: [
        _buildHeader(context, controller),
        _buildFilters(context, controller),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.services.isEmpty) {
              return const Center(child: LoadingWidget());
            }

            if (controller.errorMessage.value.isNotEmpty &&
                controller.services.isEmpty) {
              return _buildErrorState(context, controller);
            }

            if (controller.services.isEmpty) {
              return const Center(child: Text('No services found'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConfig.padding * 2),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Card(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
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
                        rows: controller.services.map((service) {
                          return DataRow(cells: [
                            DataCell(Text(
                                service.displayName ?? service.serviceName)),
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
                                  color: _getStatusColor(service.status)
                                      .withValues(alpha: 0.2),
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
                              Icon(
                                service.monitoring.enabled
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: service.monitoring.enabled
                                    ? Colors.green
                                    : Colors.grey,
                                size: 20,
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _showServiceDialog(context, service: service),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red, size: 20),
                                    onPressed: () =>
                                        controller.deleteService(service.serviceId),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        _buildPagination(context, controller),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ManagedServicesController controller, {
    bool showMenuButton = false,
  }) {
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
      child: Row(
        children: [
          if (showMenuButton) ...[
            const DrawerMenuButton(),
            const SizedBox(width: 8),
          ],
          const Icon(EvaIcons.activity, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.hostId != null
                    ? 'Services for Host: ${controller.hostId}'
                    : 'Service Management',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Obx(() {
                final summary = controller.summaryData.value;
                if (summary != null) {
                  return Text(
                    'Running: ${summary.runningServices} | Stopped: ${summary.stoppedServices} | Error: ${summary.errorServices}',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
          const Spacer(),
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
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showServiceDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Service'),
          ),
          if (controller.hostId != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Hosts'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilters(
      BuildContext context, ManagedServicesController controller) {
    return Container(
      padding: const EdgeInsets.all(AppConfig.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(EvaIcons.funnelOutline, size: 18),
              const SizedBox(width: 8),
              const Text('Filters:'),
              const Spacer(),
              Obx(() {
                if (controller.hasActiveFilters) {
                  return TextButton.icon(
                    onPressed: controller.clearFilters,
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear Filters'),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Obx(() => _buildDropdownFilter(
                    context,
                    label: 'Service Type',
                    value: controller.filterServiceType.value,
                    items: ['All', ...controller.availableServiceTypes],
                    onChanged: (value) {
                      controller.setServiceTypeFilter(
                        value == 'All' ? null : value,
                      );
                    },
                  )),
              Obx(() => _buildDropdownFilter(
                    context,
                    label: 'Environment',
                    value: controller.filterEnvironment.value,
                    items: ['All', ...controller.availableEnvironments],
                    onChanged: (value) {
                      controller.setEnvironmentFilter(
                        value == 'All' ? null : value,
                      );
                    },
                  )),
              Obx(() => _buildDropdownFilter(
                    context,
                    label: 'Region',
                    value: controller.filterRegion.value,
                    items: ['All', ...controller.availableRegions],
                    onChanged: (value) {
                      controller.setRegionFilter(
                        value == 'All' ? null : value,
                      );
                    },
                  )),
              Obx(() => _buildDropdownFilter(
                    context,
                    label: 'Status',
                    value: controller.filterStatus.value,
                    items: const [
                      'All',
                      'running',
                      'stopped',
                      'error',
                      'unknown'
                    ],
                    onChanged: (value) {
                      controller.setStatusFilter(
                        value == 'All' ? null : value,
                      );
                    },
                  )),
              Obx(() => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '${controller.totalServices.value} services',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter(
    BuildContext context, {
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: DropdownButton<String>(
        value: value ?? 'All',
        underline: const SizedBox(),
        isDense: true,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text('$label: $item'),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, ManagedServicesController controller) {
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
            padding:
                const EdgeInsets.symmetric(horizontal: AppConfig.padding * 2),
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

  Widget _buildPagination(
      BuildContext context, ManagedServicesController controller) {
    return Obx(() {
      if (controller.services.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(AppConfig.padding),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Page ${controller.currentPageNumber} of ${controller.totalPages}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: controller.hasPrevious
                      ? controller.loadPreviousPage
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: controller.hasMore ? controller.loadNextPage : null,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'running':
        return Colors.green;
      case 'stopped':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showServiceDialog(BuildContext context, {ManagedService? service}) {
    showDialog(
      context: context,
      builder: (context) => ServiceFormDialog(service: service),
    );
  }
}

class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () {
        Scaffold.of(context).openDrawer();
      },
    );
  }
}
