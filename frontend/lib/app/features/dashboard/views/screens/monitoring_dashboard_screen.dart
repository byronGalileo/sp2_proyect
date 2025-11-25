import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import '../../../../config/app_config.dart';
import '../../../../config/themes/app_theme.dart';
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
      showMobileHeader: false,
      child: ResponsiveBuilder(
        mobileBuilder: (context, constraints) {
          return _buildDashboardLayout(
            context,
            controller,
            padding: AppConfig.padding,
            spacing: 24,
            showMenuButton: true,
          );
        },
        tabletBuilder: (context, constraints) {
          return _buildDashboardLayout(
            context,
            controller,
            padding: AppConfig.padding * 2,
            spacing: 32,
            showMenuButton: true,
          );
        },
        desktopBuilder: (context, constraints) {
          return _buildDashboardLayout(
            context,
            controller,
            padding: AppConfig.padding * 3,
            spacing: 40,
          );
        },
      ),
    );
  }

  Widget _buildDashboardLayout(
    BuildContext context,
    MonitoringDashboardController controller, {
    required double padding,
    required double spacing,
    bool showMenuButton = false,
  }) {
    return Column(
      children: [
        _buildHeader(context, controller, showMenuButton: showMenuButton),
        Expanded(
          child: Container(
            color: AppColors.background,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
                  Obx(() {
                    if (controller.isLoading.value) {
                      return const LoadingWidget();
                    }
                    return Column(
                      children: [
                        _buildStatCards(context, controller),
                        SizedBox(height: spacing),
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
        color: AppColors.primaryDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
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
          Icon(EvaIcons.activity, size: 24, color: AppColors.accentOrange),
          const SizedBox(width: 12),
          Text(
            'Monitoring Dashboard',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: Obx(() => controller.isLoading.value
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
                    ),
                  )
                : const Icon(Icons.refresh, color: AppColors.textOnPrimary)),
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
                      color: AppColors.success,
                      isLoading: controller.isLoading.value,
                    )),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(() => StatCard(
                      title: 'Inactive Hosts',
                      value: controller.inactiveHostsCount.value,
                      icon: EvaIcons.hardDriveOutline,
                      color: AppColors.warning,
                      isLoading: controller.isLoading.value,
                    )),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(() => StatCard(
                      title: 'Inactive Services',
                      value: controller.inactiveServicesCount.value,
                      icon: EvaIcons.alertTriangle,
                      color: AppColors.error,
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
                    color: AppColors.success,
                    isLoading: controller.isLoading.value,
                  )),
              const SizedBox(height: 16),
              Obx(() => StatCard(
                    title: 'Inactive Hosts',
                    value: controller.inactiveHostsCount.value,
                    icon: EvaIcons.hardDriveOutline,
                    color: AppColors.warning,
                    isLoading: controller.isLoading.value,
                  )),
              const SizedBox(height: 16),
              Obx(() => StatCard(
                    title: 'Inactive Services',
                    value: controller.inactiveServicesCount.value,
                    icon: EvaIcons.alertTriangle,
                    color: AppColors.error,
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
                          color: AppColors.success,
                          isLoading: controller.isLoading.value,
                        )),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(() => StatCard(
                          title: 'Inactive Hosts',
                          value: controller.inactiveHostsCount.value,
                          icon: EvaIcons.hardDriveOutline,
                          color: AppColors.warning,
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
                    color: AppColors.error,
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
              Icon(EvaIcons.clockOutline, size: 20, color: AppColors.primaryBase),
              const SizedBox(width: 12),
              Text(
                'Time Period:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
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
      selectedColor: AppColors.primaryBase,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: isSelected ? AppColors.primaryBase : AppColors.border,
        width: isSelected ? 2 : 1,
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
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
