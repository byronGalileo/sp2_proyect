import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import '../../../../config/app_config.dart';
import '../../../../shared_components/responsive_builder.dart';
import '../../../../shared_components/widgets/loading_widget.dart';
import '../../../../shared_components/base_screen_wrapper.dart';
import '../../controllers/monitoring_dashboard_controller.dart';
import '../widgets/stat_card.dart';
import '../widgets/logs_chart.dart';

class MonitoringDashboardScreen extends StatelessWidget {
  const MonitoringDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MonitoringDashboardController());

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

  Widget _buildMobileLayout(
      BuildContext context, MonitoringDashboardController controller) {
    return Column(
      children: [
        _buildHeader(context, controller, showMenuButton: true),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConfig.padding),
            child: Column(
              children: [
                Obx(() {
                  if (controller.isLoading.value) {
                    return const LoadingWidget();
                  }
                  return Column(
                    children: [
                      _buildStatCards(context, controller),
                      const SizedBox(height: 24),
                      _buildTimePeriodSelector(context, controller),
                      const SizedBox(height: 16),
                      _buildLogsChart(context, controller),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(
      BuildContext context, MonitoringDashboardController controller) {
    return Column(
      children: [
        _buildHeader(context, controller),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConfig.padding * 2),
            child: Column(
              children: [
                Obx(() {
                  if (controller.isLoading.value) {
                    return const LoadingWidget();
                  }
                  return Column(
                    children: [
                      _buildStatCards(context, controller),
                      const SizedBox(height: 32),
                      _buildTimePeriodSelector(context, controller),
                      const SizedBox(height: 16),
                      _buildLogsChart(context, controller),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context, MonitoringDashboardController controller) {
    return Column(
      children: [
        _buildHeader(context, controller),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConfig.padding * 3),
            child: Column(
              children: [
                Obx(() {
                  if (controller.isLoading.value) {
                    return const LoadingWidget();
                  }
                  return Column(
                    children: [
                      _buildStatCards(context, controller),
                      const SizedBox(height: 40),
                      _buildTimePeriodSelector(context, controller),
                      const SizedBox(height: 16),
                      _buildLogsChart(context, controller),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    MonitoringDashboardController controller, {
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
          Text(
            'Monitoring Dashboard',
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
            onPressed:
                controller.isLoading.value ? null : controller.refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(
      BuildContext context, MonitoringDashboardController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final isDesktop = constraints.maxWidth > 900;

        if (isDesktop) {
          // Desktop: 3 cards in a row
          return Row(
            children: [
              Expanded(
                child: Obx(() => StatCard(
                      title: 'Active Hosts',
                      value: controller.activeHostsCount.value,
                      icon: EvaIcons.hardDrive,
                      color: Colors.green,
                      isLoading: controller.isLoading.value,
                    )),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(() => StatCard(
                      title: 'Inactive Hosts',
                      value: controller.inactiveHostsCount.value,
                      icon: EvaIcons.hardDriveOutline,
                      color: Colors.orange,
                      isLoading: controller.isLoading.value,
                    )),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(() => StatCard(
                      title: 'Inactive Services',
                      value: controller.inactiveServicesCount.value,
                      icon: EvaIcons.alertTriangle,
                      color: Colors.red,
                      isLoading: controller.isLoading.value,
                    )),
              ),
            ],
          );
        } else if (isCompact) {
          // Mobile: 1 card per row
          return Column(
            children: [
              Obx(() => StatCard(
                    title: 'Active Hosts',
                    value: controller.activeHostsCount.value,
                    icon: EvaIcons.hardDrive,
                    color: Colors.green,
                    isLoading: controller.isLoading.value,
                  )),
              const SizedBox(height: 16),
              Obx(() => StatCard(
                    title: 'Inactive Hosts',
                    value: controller.inactiveHostsCount.value,
                    icon: EvaIcons.hardDriveOutline,
                    color: Colors.orange,
                    isLoading: controller.isLoading.value,
                  )),
              const SizedBox(height: 16),
              Obx(() => StatCard(
                    title: 'Inactive Services',
                    value: controller.inactiveServicesCount.value,
                    icon: EvaIcons.alertTriangle,
                    color: Colors.red,
                    isLoading: controller.isLoading.value,
                  )),
            ],
          );
        } else {
          // Tablet: 2 cards in first row, 1 in second
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Obx(() => StatCard(
                          title: 'Active Hosts',
                          value: controller.activeHostsCount.value,
                          icon: EvaIcons.hardDrive,
                          color: Colors.green,
                          isLoading: controller.isLoading.value,
                        )),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(() => StatCard(
                          title: 'Inactive Hosts',
                          value: controller.inactiveHostsCount.value,
                          icon: EvaIcons.hardDriveOutline,
                          color: Colors.orange,
                          isLoading: controller.isLoading.value,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Obx(() => StatCard(
                    title: 'Inactive Services',
                    value: controller.inactiveServicesCount.value,
                    icon: EvaIcons.alertTriangle,
                    color: Colors.red,
                    isLoading: controller.isLoading.value,
                  )),
            ],
          );
        }
      },
    );
  }

  Widget _buildTimePeriodSelector(
      BuildContext context, MonitoringDashboardController controller) {
    return Obx(() {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConfig.padding),
          child: Row(
            children: [
              const Icon(EvaIcons.clockOutline, size: 20),
              const SizedBox(width: 12),
              Text(
                'Time Period:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPeriodChip(
                      context,
                      controller,
                      '6h',
                      6,
                    ),
                    _buildPeriodChip(
                      context,
                      controller,
                      '12h',
                      12,
                    ),
                    _buildPeriodChip(
                      context,
                      controller,
                      '24h',
                      24,
                    ),
                    _buildPeriodChip(
                      context,
                      controller,
                      '2d',
                      48,
                    ),
                    _buildPeriodChip(
                      context,
                      controller,
                      '7d',
                      168,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPeriodChip(
    BuildContext context,
    MonitoringDashboardController controller,
    String label,
    int hours,
  ) {
    final isSelected = controller.selectedHours.value == hours;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          controller.changeTimePeriod(hours);
        }
      },
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildLogsChart(
      BuildContext context, MonitoringDashboardController controller) {
    return Obx(() {
      if (controller.isLoadingCharts.value) {
        return const SizedBox(
          height: 600,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      return LogsChart(
        logsData: controller.logsChartData,
        selectedHours: controller.selectedHours.value,
      );
    });
  }
}
