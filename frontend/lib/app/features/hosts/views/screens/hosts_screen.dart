import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import '../../../../config/app_config.dart';
import '../../../../shared_components/responsive_builder.dart';
import '../../../../shared_components/widgets/loading_widget.dart';
import '../../../../models/host.dart';
import '../../../../shared_components/base_screen_wrapper.dart';
import '../../controllers/hosts_controller.dart';
import '../widgets/host_card.dart';
import '../../../managed_services/views/widgets/service_form_dialog.dart';
import '../widgets/host_form_dialog.dart';
import '../widgets/host_table.dart';

class HostsScreen extends StatelessWidget {
  const HostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HostsController());

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

  Widget _buildMobileLayout(BuildContext context, HostsController controller) {
    return Column(
      children: [
        _buildHeader(context, controller, showMenuButton: true),
        _buildFilters(context, controller),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.hosts.isEmpty) {
              return const Center(child: LoadingWidget());
            }

            if (controller.errorMessage.value.isNotEmpty &&
                controller.hosts.isEmpty) {
              return _buildErrorState(context, controller);
            }

            if (controller.hosts.isEmpty) {
              return const Center(child: Text('No hosts found'));
            }

            return RefreshIndicator(
              onRefresh: controller.refresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppConfig.padding),
                itemCount: controller.hosts.length,
                itemBuilder: (context, index) {
                  final host = controller.hosts[index];
                  return HostCard(
                    host: host,
                    onEdit: () => _showHostDialog(context, host: host),
                    onDelete: () => controller.deleteHost(hostId: host.hostId),
                    onAddService: () => _showServiceDialog(context, host),
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

  Widget _buildTabletLayout(BuildContext context, HostsController controller) {
    return Column(
      children: [
        _buildHeader(context, controller),
        _buildFilters(context, controller),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.hosts.isEmpty) {
              return const Center(child: LoadingWidget());
            }

            if (controller.errorMessage.value.isNotEmpty &&
                controller.hosts.isEmpty) {
              return _buildErrorState(context, controller);
            }

            if (controller.hosts.isEmpty) {
              return const Center(child: Text('No hosts found'));
            }

            return Padding(
              padding: const EdgeInsets.all(AppConfig.padding),
              child: Align(
                alignment: Alignment.topCenter,
                child: HostTable(
                  hosts: controller.hosts,
                  onEdit: (host) => _showHostDialog(context, host: host),
                  onDelete: (host) =>
                      controller.deleteHost(hostId: host.hostId),
                  onAddService: (host) => _showServiceDialog(context, host),
                ),
              ),
            );
          }),
        ),
        _buildPagination(context, controller),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, HostsController controller) {
    return Column(
      children: [
        _buildHeader(context, controller),
        _buildFilters(context, controller),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.hosts.isEmpty) {
              return const Center(child: LoadingWidget());
            }

            if (controller.errorMessage.value.isNotEmpty &&
                controller.hosts.isEmpty) {
              return _buildErrorState(context, controller);
            }

            if (controller.hosts.isEmpty) {
              return const Center(child: Text('No hosts found'));
            }

            return Padding(
              padding: const EdgeInsets.all(AppConfig.padding * 2),
              child: Align(
                alignment: Alignment.topCenter,
                child: HostTable(
                  hosts: controller.hosts,
                  onEdit: (host) => _showHostDialog(context, host: host),
                  onDelete: (host) =>
                      controller.deleteHost(hostId: host.hostId),
                  onAddService: (host) => _showServiceDialog(context, host),
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
    HostsController controller, {
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
          const Icon(EvaIcons.hardDrive, size: 24),
          const SizedBox(width: 12),
          Text(
            'Host Management',
            style: Theme.of(context).textTheme.titleLarge,
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
            onPressed: () => _showHostDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Host'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, HostsController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 800;
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
                    _buildEnvironmentFilter(controller),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildRegionFilter(controller)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatusFilter(controller)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Obx(() => Text(
                                '${controller.totalHosts.value} hosts',
                                style: Theme.of(context).textTheme.bodySmall,
                              )),
                        ),
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
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildEnvironmentFilter(controller)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildRegionFilter(controller)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatusFilter(controller)),
                    const SizedBox(width: 12),
                    Obx(() => Text(
                          '${controller.totalHosts.value} hosts',
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

  Widget _buildEnvironmentFilter(HostsController controller) {
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

  Widget _buildRegionFilter(HostsController controller) {
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

  Widget _buildStatusFilter(HostsController controller) {
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
              value: 'active',
              child: Text('active'),
            ),
            DropdownMenuItem<String>(
              value: 'inactive',
              child: Text('inactive'),
            ),
            DropdownMenuItem<String>(
              value: 'maintenance',
              child: Text('maintenance'),
            ),
          ],
          onChanged: (value) {
            controller.setStatusFilter(value);
          },
        ));
  }

  Widget _buildErrorState(BuildContext context, HostsController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(EvaIcons.alertCircle, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading hosts',
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

  Widget _buildPagination(BuildContext context, HostsController controller) {
    return Obx(() {
      if (controller.hosts.isEmpty) return const SizedBox.shrink();

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
                  onPressed:
                      controller.hasMore ? controller.loadNextPage : null,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  void _showHostDialog(BuildContext context, {Host? host}) {
    showDialog(
      context: context,
      builder: (context) => HostFormDialog(host: host),
    );
  }

  void _showServiceDialog(BuildContext context, Host host) {
    showDialog(
      context: context,
      builder: (context) => ServiceFormDialog(preselectedHostId: host.hostId),
    );
  }
}
