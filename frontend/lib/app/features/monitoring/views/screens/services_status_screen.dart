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
import '../widgets/services_status_table.dart';
import '../widgets/pagination_footer.dart';

class ServicesStatusScreen extends StatelessWidget {
  const ServicesStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ServicesController>();

    return BaseScreenWrapper(
      showMobileHeader: false, // Disable default header to avoid duplication
      child: ResponsiveBuilder(
        mobileBuilder: (context, constraints) {
          return _buildServicesLayout(
            context,
            controller,
            padding: AppConfig.padding,
            showMenuButton: true,
            isMobile: true,
          );
        },
        tabletBuilder: (context, constraints) {
          return _buildServicesLayout(
            context,
            controller,
            padding: AppConfig.padding,
            showMenuButton: true,
            isMobile: false,
          );
        },
        desktopBuilder: (context, constraints) {
          return _buildServicesLayout(
            context,
            controller,
            padding: AppConfig.padding * 2,
            showMenuButton: false,
            isMobile: false,
          );
        },
      ),
    );
  }

  Widget _buildServicesLayout(
    BuildContext context,
    ServicesController controller, {
    required double padding,
    bool showMenuButton = false,
    required bool isMobile,
  }) {
    return Column(
      children: [
        _buildHeader(context, controller, showMenuButton: showMenuButton),
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

            if (isMobile) {
              return Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: controller.refresh,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(padding),
                        child: Column(
                          children: [
                            ServicesStatistics(
                              totalServices: controller.statistics['totalServices']!,
                              totalLogs: controller.statistics['totalLogs']!,
                              totalUnsentLogs: controller.statistics['totalUnsentLogs']!,
                            ),
                            const SizedBox(height: 16),
                            ...controller.paginatedServices.map(
                              (service) => ServiceCard(service: service),
                            ),
                            const SizedBox(height: 16),
                            PaginationFooter(controller: controller),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        ServicesStatistics(
                          totalServices: controller.statistics['totalServices']!,
                          totalLogs: controller.statistics['totalLogs']!,
                          totalUnsentLogs: controller.statistics['totalUnsentLogs']!,
                        ),
                        const SizedBox(height: 24),
                        ServicesStatusTable(controller: controller),
                      ],
                    ),
                  ),
                ),
              );
            }
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Services Status',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Obx(() {
                      if (controller.lastUpdated.value.isNotEmpty) {
                        return Text(
                          'Last updated: ${_formatLastUpdated(controller.lastUpdated.value)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textLight),
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


}


