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

class ManagedServicesScreen extends StatefulWidget {
  const ManagedServicesScreen({super.key});

  @override
  State<ManagedServicesScreen> createState() => _ManagedServicesScreenState();
}

class _ManagedServicesScreenState extends State<ManagedServicesScreen> {
  late final ManagedServicesController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ManagedServicesController>();
    // Re-initialize with current arguments every time the screen is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeWithArguments();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: service.monitoring.enabled
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.grey.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  service.monitoring.enabled ? 'Enabled' : 'Disabled',
                                  style: TextStyle(
                                    color: service.monitoring.enabled
                                        ? Colors.green
                                        : Colors.grey,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;
        return Container(
          padding: const EdgeInsets.all(AppConfig.padding),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildHostFilter(controller)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildServiceFilter(controller)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildEnvironmentFilter(controller)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildRegionFilter(controller)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildStatusFilter(controller)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: controller.clearFilters,
                            icon: const Icon(Icons.clear, size: 18),
                            label: const Text('Clear'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Text(
                          '${controller.totalServices.value} services',
                          style: Theme.of(context).textTheme.bodySmall,
                        )),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildHostFilter(controller)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildServiceFilter(controller)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildEnvironmentFilter(controller)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildRegionFilter(controller)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatusFilter(controller)),
                    const SizedBox(width: 12),
                    Obx(() => Text(
                          '${controller.totalServices.value} services',
                          style: Theme.of(context).textTheme.bodySmall,
                        )),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: controller.clearFilters,
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Clear Filters'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildHostFilter(ManagedServicesController controller) {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.filterHostId.value,
          decoration: const InputDecoration(
            labelText: 'Host',
            prefixIcon: Icon(EvaIcons.monitorOutline, size: 20),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Hosts'),
            ),
            ...controller.availableHosts.map((host) {
              return DropdownMenuItem<String>(
                value: host.hostId,
                child: Text('${host.hostname} (${host.ipAddress})'),
              );
            }),
          ],
          onChanged: (value) {
            controller.setHostFilter(value);
          },
        ));
  }

  Widget _buildServiceFilter(ManagedServicesController controller) {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.filterServiceId.value,
          decoration: const InputDecoration(
            labelText: 'Service',
            prefixIcon: Icon(EvaIcons.cube, size: 20),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Services'),
            ),
            ...controller.availableServices.map((service) {
              return DropdownMenuItem<String>(
                value: service.serviceId,
                child: Text(service.displayName ?? service.serviceName),
              );
            }),
          ],
          onChanged: (value) {
            controller.setServiceFilter(value);
          },
        ));
  }

  Widget _buildEnvironmentFilter(ManagedServicesController controller) {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.filterEnvironment.value,
          decoration: const InputDecoration(
            labelText: 'Environment',
            prefixIcon: Icon(EvaIcons.layersOutline, size: 20),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Environments'),
            ),
            ...controller.availableEnvironments.map((env) {
              return DropdownMenuItem<String>(
                value: env,
                child: Text(env),
              );
            }),
          ],
          onChanged: (value) {
            controller.setEnvironmentFilter(value);
          },
        ));
  }

  Widget _buildRegionFilter(ManagedServicesController controller) {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.filterRegion.value,
          decoration: const InputDecoration(
            labelText: 'Region',
            prefixIcon: Icon(EvaIcons.globe, size: 20),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Regions'),
            ),
            ...controller.availableRegions.map((region) {
              return DropdownMenuItem<String>(
                value: region,
                child: Text(region),
              );
            }),
          ],
          onChanged: (value) {
            controller.setRegionFilter(value);
          },
        ));
  }

  Widget _buildStatusFilter(ManagedServicesController controller) {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.filterStatus.value,
          decoration: const InputDecoration(
            labelText: 'Status',
            prefixIcon: Icon(EvaIcons.activityOutline, size: 20),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: const [
            DropdownMenuItem<String>(
              value: null,
              child: Text('All Statuses'),
            ),
            DropdownMenuItem<String>(
              value: 'running',
              child: Text('running'),
            ),
            DropdownMenuItem<String>(
              value: 'stopped',
              child: Text('stopped'),
            ),
            DropdownMenuItem<String>(
              value: 'error',
              child: Text('error'),
            ),
            DropdownMenuItem<String>(
              value: 'unknown',
              child: Text('unknown'),
            ),
          ],
          onChanged: (value) {
            controller.setStatusFilter(value);
          },
        ));
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
