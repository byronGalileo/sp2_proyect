import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../config/app_config.dart';
import '../../../../shared_components/responsive_builder.dart';
import '../../../../shared_components/widgets/loading_widget.dart';
import '../../../../shared_components/base_screen_wrapper.dart';
import '../../controllers/logs_controller.dart';
import '../../../../models/log.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LogsController>();

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
        _buildHeader(context, controller),
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
          const Icon(EvaIcons.fileText, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service Logs',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Obx(() {
                  if (controller.total.value > 0) {
                    return Text(
                      '${controller.total.value} logs found',
                      style: Theme.of(context).textTheme.bodySmall,
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
                : const Icon(Icons.refresh)),
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
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildServiceFilter(LogsController controller) {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedServiceName.value.isEmpty
              ? null
              : controller.selectedServiceName.value,
          decoration: const InputDecoration(
            labelText: 'Service',
            prefixIcon: Icon(EvaIcons.activity, size: 20),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<String>(
              value: '',
              child: Text('All Services'),
            ),
            ...controller.availableServices.map((service) {
              return DropdownMenuItem<String>(
                value: service,
                child: Text(service),
              );
            }),
          ],
          onChanged: (value) {
            controller.applyFilters(serviceName: value ?? '');
          },
        ));
  }

  Widget _buildLogLevelFilter(LogsController controller) {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedLogLevel.value,
          decoration: const InputDecoration(
            labelText: 'Level',
            prefixIcon: Icon(EvaIcons.alertCircle, size: 20),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: controller.logLevels.map((level) {
            return DropdownMenuItem<String>(
              value: level,
              child: Text(level),
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
          value: controller.selectedHours.value,
          decoration: const InputDecoration(
            labelText: 'Time Range',
            prefixIcon: Icon(EvaIcons.clock, size: 20),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: controller.timeRanges.map((hours) {
            return DropdownMenuItem<int>(
              value: hours,
              child: Text(controller.getTimeRangeLabel(hours)),
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
          value: controller.selectedLimit.value,
          decoration: const InputDecoration(
            labelText: 'Limit',
            prefixIcon: Icon(EvaIcons.options, size: 20),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: controller.limitOptions.map((limit) {
            return DropdownMenuItem<int>(
              value: limit,
              child: Text('$limit logs'),
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
              Icon(EvaIcons.inbox, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No logs found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
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
          const Icon(EvaIcons.alertCircle, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading logs',
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

  Widget _buildLogsTable(BuildContext context, LogsController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConfig.padding),
      child: Card(
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
                            label: Text(
                              log.serviceType!,
                              style: const TextStyle(fontSize: 10),
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          )
                        : const Text('Unknown'),
                  ),
                  DataCell(
                    Icon(
                      log.sentToUser ? Icons.check_circle : Icons.pending,
                      size: 20,
                      color: log.sentToUser ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
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
        color: color.withValues(alpha: 0.15),
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
}
