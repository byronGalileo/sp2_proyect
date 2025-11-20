import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import '../../../../config/app_config.dart';
import '../../../../config/themes/app_theme.dart';
import '../../../../shared_components/responsive_builder.dart';
import '../../../../shared_components/widgets/loading_widget.dart';
import '../../../../shared_components/base_screen_wrapper.dart';
import '../../../../models/managed_service.dart';
import '../../controllers/managed_services_controller.dart';
import '../widgets/service_form_dialog.dart';
import '../widgets/service_card.dart';
import '../../../../features/monitoring/controllers/logs_controller.dart'; // Import LogsController for navigation
import '../widgets/service_table.dart';

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
      floatingActionButton: MediaQuery.of(context).size.width < 900
          ? FloatingActionButton.extended(
              onPressed: () => _showServiceDialog(context),
              icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
              label: const Text('Add Service'),
            )
          : null,
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
        _buildHeader(context, controller, showMenuButton: true, showAddButton: false),
        _buildFilters(context, controller),
        // Service count above the list
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConfig.padding,
            vertical: AppConfig.padding / 2,
          ),
          child: Row(
            children: [
              Obx(() => Text( // The text color should be light to be visible on the dark background
                    '${controller.totalServices.value} services',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textLight),
                  )),
            ],
          ),
        ),
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
                  return ServiceCard(
                    service: service,
                    onEdit: (s) => _showServiceDialog(context, service: s),
                    onDelete: (s) => controller.deleteService(s.serviceId),
                    onViewLogs: (s) {
                      // Delete existing controller if it exists to force fresh initialization
                      try { Get.delete<LogsController>(force: true); } catch (e) {}
                      Get.toNamed('/monitoring/logs', arguments: {'serviceName': s.serviceId});
                    },
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
        // Service count above the table
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConfig.padding * 2,
            vertical: AppConfig.padding / 2,
          ),
          child: Row(
            children: [
              Obx(() => Text( // The text color should be light to be visible on the dark background
                    '${controller.totalServices.value} services',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textLight),
                  )),
            ],
          ),
        ),
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
                  child: ServiceTable(
                    services: controller.services,
                    onEdit: (service) =>
                        _showServiceDialog(context, service: service),
                    onDelete: (service) =>
                        controller.deleteService(service.serviceId),
                  )),
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
    bool showAddButton = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConfig.padding),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
          const Icon(EvaIcons.activity, size: 24, color: AppColors.accentOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.hostId != null ? 'Services for Host: ${controller.hostId}' : 'Service Management',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                Obx(() {
                  final summary = controller.summaryData.value;
                  if (summary != null) {
                    return Text(
                      'Running: ${summary.runningServices} | Stopped: ${summary.stoppedServices} | Error: ${summary.errorServices}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textLight),
                      overflow: TextOverflow.ellipsis,
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),
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
          if (showAddButton) ...[
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showServiceDialog(context),
              icon: const Icon(Icons.add, size: 18, color: AppColors.textOnPrimary),
              label: const Text('Add Service'),
            ),
          ],
          if (controller.hostId != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
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
            color: AppColors.primaryDark.withOpacity(0.5),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme:
                  Theme.of(context).inputDecorationTheme.copyWith(
                        labelStyle: const TextStyle(color: AppColors.textLight),
                        prefixIconColor: AppColors.textLight,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: AppColors.accentOrange, width: 2),
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
                                backgroundColor: AppColors.border,
                                foregroundColor: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                      ElevatedButton.icon(
                        onPressed: controller.clearFilters,
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('Clear Filters'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.border,
                          foregroundColor: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildHostFilter(ManagedServicesController controller) {
    return Obx(() => DropdownButtonFormField<String>( // Apply dark theme styles
          value: controller.filterHostId.value,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Host',
            prefixIcon: Icon(EvaIcons.monitorOutline, size: 20),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          dropdownColor: AppColors.primaryDark,
          style: const TextStyle(color: AppColors.textOnPrimary),
          iconEnabledColor: AppColors.textLight,
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text(
                'All Hosts',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...controller.availableHosts.map((host) {
              return DropdownMenuItem<String>(
                value: host.hostId,
                child: Text(
                  '${host.hostname} (${host.ipAddress})',
                  overflow: TextOverflow.ellipsis, // Add style for dropdown items
                  style: const TextStyle(color: AppColors.textOnPrimary),
                ),
              );
            }),
          ],
          onChanged: (value) {
            controller.setHostFilter(value);
          },
        ));
  }

  Widget _buildServiceFilter(ManagedServicesController controller) {
    return Obx(() => DropdownButtonFormField<String>( // Apply dark theme styles
          value: controller.filterServiceId.value,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Service',
            prefixIcon: Icon(EvaIcons.cube, size: 20),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          dropdownColor: AppColors.primaryDark,
          style: const TextStyle(color: AppColors.textOnPrimary),
          iconEnabledColor: AppColors.textLight,
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text(
                'All Services',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...controller.availableServices.map((service) {
              return DropdownMenuItem<String>(
                value: service.serviceId,
                child: Text(
                  service.displayName ?? service.serviceName,
                  overflow: TextOverflow.ellipsis, // Add style for dropdown items
                  style: const TextStyle(color: AppColors.textOnPrimary),
                ),
              );
            }),
          ],
          onChanged: (value) {
            controller.setServiceFilter(value);
          },
        ));
  }

  Widget _buildEnvironmentFilter(ManagedServicesController controller) {
    return Obx(() => DropdownButtonFormField<String>( // Apply dark theme styles
          value: controller.filterEnvironment.value,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Environment',
            prefixIcon: Icon(EvaIcons.layersOutline, size: 20),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          dropdownColor: AppColors.primaryDark,
          style: const TextStyle(color: AppColors.textOnPrimary),
          iconEnabledColor: AppColors.textLight,
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text(
                'All Environments',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...controller.availableEnvironments.map((env) {
              return DropdownMenuItem<String>(
                value: env,
                child: Text(
                  env,
                  overflow: TextOverflow.ellipsis, // Add style for dropdown items
                  style: const TextStyle(color: AppColors.textOnPrimary),
                ),
              );
            }),
          ],
          onChanged: (value) {
            controller.setEnvironmentFilter(value);
          },
        ));
  }

  Widget _buildRegionFilter(ManagedServicesController controller) {
    return Obx(() => DropdownButtonFormField<String>( // Apply dark theme styles
          value: controller.filterRegion.value,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Region',
            prefixIcon: Icon(EvaIcons.globe, size: 20),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          dropdownColor: AppColors.primaryDark,
          style: const TextStyle(color: AppColors.textOnPrimary),
          iconEnabledColor: AppColors.textLight,
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text(
                'All Regions',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...controller.availableRegions.map((region) {
              return DropdownMenuItem<String>(
                value: region,
                child: Text(
                  region,
                  overflow: TextOverflow.ellipsis, // Add style for dropdown items
                  style: const TextStyle(color: AppColors.textOnPrimary),
                ),
              );
            }),
          ],
          onChanged: (value) {
            controller.setRegionFilter(value);
          },
        ));
  }

  Widget _buildStatusFilter(ManagedServicesController controller) {
    return Obx(() => DropdownButtonFormField<String>( // Apply dark theme styles
          value: controller.filterStatus.value,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Status',
            prefixIcon: Icon(EvaIcons.activityOutline, size: 20),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          dropdownColor: AppColors.primaryDark,
          style: const TextStyle(color: AppColors.textOnPrimary),
          iconEnabledColor: AppColors.textLight,
          items: const [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                'All Statuses',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem<String>(
              value: 'running',
              child: Text(
                'running',
                overflow: TextOverflow.ellipsis, // Add style for dropdown items
                style: TextStyle(color: AppColors.textOnPrimary),
              ),
            ),
            DropdownMenuItem<String>(
              value: 'stopped',
              child: Text(
                'stopped',
                overflow: TextOverflow.ellipsis, // Add style for dropdown items
                style: TextStyle(color: AppColors.textOnPrimary),
              ),
            ),
            DropdownMenuItem<String>(
              value: 'error',
              child: Text(
                'error',
                overflow: TextOverflow.ellipsis, // Add style for dropdown items
                style: TextStyle(color: AppColors.textOnPrimary),
              ),
            ),
            DropdownMenuItem<String>(
              value: 'unknown',
              child: Text(
                'unknown',
                overflow: TextOverflow.ellipsis, // Add style for dropdown items
                style: TextStyle(color: AppColors.textOnPrimary),
              ),
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
          Text( // Apply light text color
            'Error loading services',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textOnPrimary),
          ),
          const SizedBox(height: 8),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppConfig.padding * 2),
            child: Text( // Apply light text color
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

  Widget _buildPagination(
      BuildContext context, ManagedServicesController controller) {
    return Obx(() {
      if (controller.services.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(AppConfig.padding),
        decoration: BoxDecoration( // Apply dark background
          color: AppColors.primaryDark.withOpacity(0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Page ${controller.currentPageNumber} of ${controller.totalPages}',
              style: Theme.of(context) // Apply light text color
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textLight),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppColors.textLight), // Apply light icon color
                  onPressed: controller.hasPrevious
                      ? controller.loadPreviousPage
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppColors.textLight), // Apply light icon color
                  onPressed: controller.hasMore ? controller.loadNextPage : null,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  void _showServiceDialog(BuildContext context, {ManagedService? service}) {
    showDialog(
      context: context,
      builder: (context) => ServiceFormDialog(service: service),
    );
  }
}
