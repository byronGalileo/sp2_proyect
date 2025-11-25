import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../config/app_config.dart';
import '../../../../config/themes/app_theme.dart';
import '../../../../shared_components/responsive_builder.dart';
import '../../../../shared_components/widgets/loading_widget.dart';
import '../../../../shared_components/base_screen_wrapper.dart';
import '../../controllers/logs_controller.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  late final LogsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<LogsController>();
    // Re-initialize with current arguments every time the screen is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeWithArguments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenWrapper(
      showMobileHeader: false,
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

  Widget _buildMobileLayout(BuildContext context, LogsController controller) {
    return Column(
      children: [
        _buildHeader(context, controller, showMenuButton: true),
        _buildFiltersBar(context, controller, isCompact: true),
        Expanded(child: _buildLogsContent(context, controller)),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, LogsController controller) {
    return Column(
      children: [
        _buildHeader(context, controller, showMenuButton: true),
        _buildFiltersBar(context, controller),
        Expanded(child: _buildLogsContent(context, controller)),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, LogsController controller) {
    return Column(
      children: [
        _buildHeader(context, controller),
        _buildFiltersBar(context, controller),
        Expanded(child: _buildLogsContent(context, controller)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, LogsController controller,
      {bool showMenuButton = false}) {
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
      child: Row(
        children: [
          if (showMenuButton) ...[
            const DrawerMenuButton(),
            const SizedBox(width: 8),
          ],
          const Icon(EvaIcons.fileText, size: 24, color: AppColors.accentOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service Logs',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Obx(() {
                  if (controller.allLogs.isNotEmpty) {
                    return Text(
                      '${controller.allLogs.length} logs loaded',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textLight),
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
    );
  }

  Widget _buildFiltersBar(BuildContext context, LogsController controller,
      {bool isCompact = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConfig.padding, vertical: 8),
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
                  _buildServiceFilter(controller),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildLogLevelFilter(controller)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTimeRangeFilter(controller)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildLimitFilter(controller)),
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
                  Expanded(flex: 2, child: _buildServiceFilter(controller)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildLogLevelFilter(controller)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTimeRangeFilter(controller)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildLimitFilter(controller)),
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
  }

  Widget _buildServiceFilter(LogsController controller) {
    return Obx(() => DropdownButtonFormField<String>(
          dropdownColor: AppColors.primaryDark,
          style: const TextStyle(color: AppColors.textOnPrimary),
          iconEnabledColor: AppColors.textLight,
          value: controller.selectedServiceId.value.isEmpty
              ? null
              : controller.selectedServiceId.value,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Service',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            prefixIcon: Icon(EvaIcons.activity, size: 20),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<String>(
              value: '',
              child: Text(
                'All Services',
                style: TextStyle(color: AppColors.textOnPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...controller.availableServices.map((service) {
              return DropdownMenuItem<String>(
                value: service.serviceId,
                child: Text(
                  service.displayName ?? service.serviceName,
                  style: const TextStyle(color: AppColors.textOnPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: (value) {
            // Find the service name from serviceId
            final service = controller.availableServices.firstWhereOrNull(
              (s) => s.serviceId == value,
            );
            controller.selectedServiceId.value = value ?? '';
            controller.selectedServiceName.value =
                service?.serviceName ?? '';
            controller.fetchLogs(refresh: true);
          },
        ));
  }

  Widget _buildLogLevelFilter(LogsController controller) {
    return Obx(() => DropdownButtonFormField<String>(
          dropdownColor: AppColors.primaryDark,
          style: const TextStyle(color: AppColors.textOnPrimary),
          iconEnabledColor: AppColors.textLight,
          value: controller.selectedLogLevel.value,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Level',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            prefixIcon: Icon(EvaIcons.alertCircle, size: 20),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: controller.logLevels.map((level) {
            return DropdownMenuItem<String>(
              value: level,
              child: Text(
                level,
                style: const TextStyle(color: AppColors.textOnPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              controller.applyFilters(logLevel: value);
            }
          },
        ));
  }

  Widget _buildTimeRangeFilter(LogsController controller) {
    return Obx(() => DropdownButtonFormField<int>(
          dropdownColor: AppColors.primaryDark,
          style: const TextStyle(color: AppColors.textOnPrimary),
          iconEnabledColor: AppColors.textLight,
          value: controller.selectedHours.value,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Time Range',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            prefixIcon: Icon(EvaIcons.clock, size: 20),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: controller.timeRanges.map((hours) {
            return DropdownMenuItem<int>(
              value: hours,
              child: Text(
                controller.getTimeRangeLabel(hours),
                style: const TextStyle(color: AppColors.textOnPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              controller.applyFilters(hours: value);
            }
          },
        ));
  }

  Widget _buildLimitFilter(LogsController controller) {
    return Obx(() => DropdownButtonFormField<int>(
          dropdownColor: AppColors.primaryDark,
          style: const TextStyle(color: AppColors.textOnPrimary),
          iconEnabledColor: AppColors.textLight,
          value: controller.selectedLimit.value,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Fetch Limit',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            prefixIcon: Icon(EvaIcons.download, size: 20),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: controller.limitOptions.map((limit) {
            return DropdownMenuItem<int>(
              value: limit,
              child: Text(
                '$limit logs',
                style: const TextStyle(color: AppColors.textOnPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              controller.applyFilters(limit: value);
            }
          },
        ));
  }

  Widget _buildLogsContent(BuildContext context, LogsController controller) {
    return Obx(() {
      if (controller.isLoading.value && controller.logs.isEmpty) {
        return const Center(child: LoadingWidget());
      }

      if (controller.errorMessage.value.isNotEmpty && controller.logs.isEmpty) {
        return _buildErrorState(context, controller);
      }

      if (controller.logs.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(EvaIcons.inbox, size: 64, color: AppColors.textLight),
              const SizedBox(height: 16),
              Text(
                'No logs found',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight.withOpacity(0.8),
                ),
              ),
            ],
          ),
        );
      }

      return _buildLogsTable(context, controller);
    });
  }

  Widget _buildErrorState(BuildContext context, LogsController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(EvaIcons.alertCircle, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Error loading logs',
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

  Widget _buildLogsTable(BuildContext context, LogsController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConfig.padding),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('Timestamp')),
                  DataColumn(label: Text('Level')),
                  DataColumn(label: Text('Service')),
                  DataColumn(label: Text('Host')),
                  DataColumn(label: Text('Message')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Status')),
                ],
                rows: controller.logs.map((log) {
                  return DataRow(
                    cells: [
                      DataCell(_buildTimestampCell(log.timestamp)),
                      DataCell(_buildLevelBadge(log.logLevel)),
                      DataCell(
                        Text(
                          log.serviceName,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                      DataCell(Text(log.host ?? 'N/A')),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Tooltip(
                            message: log.message,
                            child: Text(
                              log.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        log.serviceType != null && log.serviceType != 'unknown'
                            ? Chip(
                                backgroundColor: AppColors.primaryBase.withOpacity(0.1),
                                label: Text(
                                  log.serviceType!,
                                  style: const TextStyle(fontSize: 10, color: AppColors.textOnPrimary),
                                ),
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              )
                            : const Text('Unknown'),
                      ),
                      DataCell(
                        Tooltip(
                          message: log.sentToUser ? 'Sent to user' : 'Not sent',
                          child: Icon(
                            log.sentToUser ? EvaIcons.checkmarkCircle2 : EvaIcons.clockOutline,
                            size: 20,
                            color: log.sentToUser ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            _buildPagination(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildTimestampCell(String timestamp) {
    final dateFormat = DateFormat('MMM dd, HH:mm:ss');
    try {
      final dt = DateTime.parse(timestamp);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dateFormat.format(dt),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      );
    } catch (e) {
      return Text(timestamp);
    }
  }

  Widget _buildLevelBadge(String level) {
    final color = _getLevelColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        level,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
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

  Widget _buildPagination(BuildContext context, LogsController controller) {
    return Obx(() {
      if (controller.logs.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppConfig.padding, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryDark.withOpacity(0.5),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.apply(bodyColor: AppColors.textLight, displayColor: AppColors.textLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Page size selector
              Row(
                children: [
                  const Text('Rows per page:'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: controller.pageSize.value,
                    dropdownColor: AppColors.primaryDark,
                    style: const TextStyle(color: AppColors.textOnPrimary),
                    iconEnabledColor: AppColors.textLight,
                    underline: const SizedBox(),
                    items: controller.pageSizeOptions.map((size) {
                      return DropdownMenuItem<int>(
                        value: size,
                        child: Text('$size', style: const TextStyle(color: AppColors.textOnPrimary)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        controller.changePageSize(value);
                      }
                    },
                  ),
                ],
              ),
              // Page info and navigation
              Row(
                children: [
                  Text(
                    'Page ${controller.currentPageNumber} of ${controller.totalPages}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: AppColors.textLight),
                    onPressed:
                        controller.hasPrevious ? controller.loadPreviousPage : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: AppColors.textLight),
                    onPressed: controller.hasMore ? controller.loadNextPage : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
