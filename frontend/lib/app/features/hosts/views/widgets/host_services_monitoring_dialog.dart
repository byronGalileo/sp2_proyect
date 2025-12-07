import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import '../../../../config/app_config.dart';
import '../../../../config/themes/app_theme.dart';
import '../../../../models/host.dart';
import '../../../../models/service.dart';
import '../../../../models/log.dart';
import '../../../../models/managed_service.dart';
import '../../../../utils/services/monitoring_service.dart';
import '../../../../utils/services/managed_service_service.dart';
import '../../../../utils/services/notification_service.dart';


class HostServicesMonitoringDialog extends StatefulWidget {
  final Host host;

  const HostServicesMonitoringDialog({
    super.key,
    required this.host,
  });

  @override
  State<HostServicesMonitoringDialog> createState() =>
      _HostServicesMonitoringDialogState();
}

class _HostServicesMonitoringDialogState
    extends State<HostServicesMonitoringDialog>
    with SingleTickerProviderStateMixin {
  final MonitoringService _monitoringService = MonitoringService();
  final ManagedServiceService _managedServiceService = ManagedServiceService();
  final NotificationService _notificationService = NotificationService();

  late AnimationController _refreshController;

  List<Service> _services = [];
  // Map of service name to its status history from logs
  final Map<String, List<ServiceLogPoint>> _serviceLogsHistory = {};
  // Map of service name to ManagedService configuration
  final Map<String, ManagedService> _managedServicesConfig = {};
  // Map of service name to current recovery attempt count
  final Map<String, int> _recoveryAttempts = {};
  // Map to track if notification has been sent for a service
  final Map<String, bool> _notificationSent = {};
  // Map to track last log level for each service (to detect transitions)
  final Map<String, String> _lastLogLevel = {};
  // Map to track expanded state of each service card
  final Map<String, bool> _expandedServices = {};

  bool _isLoading = true;
  String _errorMessage = '';
  Timer? _refreshTimer;
  String _lastUpdated = '';

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _loadServicesAndLogs();
    // Auto-refresh every 10 seconds for real-time updates
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadServicesAndLogs(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadServicesAndLogs() async {
    try {
      if (!_refreshController.isAnimating) {
        _refreshController.repeat();
      }
      final response = await _monitoringService.getServices();

      // Filter services for this host
      final hostServices = response.services
          .where((s) => s.host == widget.host.hostId || s.host == widget.host.hostname)
          .toList();

      // Load managed services configuration to get max_recovery_attempts
      await _loadManagedServicesConfig();

      // Load unsent logs for each service and update chart
      for (var service in hostServices) {
        await _loadServiceLogs(service.id);

        // Initialize expanded state for new services
        if (!_expandedServices.containsKey(service.id)) {
          _expandedServices[service.id] = false;
        }
      }

      setState(() {
        _services = hostServices;
        _lastUpdated = response.lastUpdated;
        _isLoading = false;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    } finally {
      if (mounted) {
        _refreshController.stop();
        _refreshController.reset();
      }
    }
  }

  Future<void> _loadManagedServicesConfig() async {
    try {
      final response = await _managedServiceService.getServices(
        hostId: widget.host.hostId,
      );

      for (var managedService in response.data.services) {
        _managedServicesConfig[managedService.serviceName] = managedService;
      }
    } catch (e) {
      debugPrint('Error loading managed services config: $e');
    }
  }

  Future<void> _loadServiceLogs(String serviceName) async {
    try {
      // Get unsent logs for this service
      final logsResponse = await _monitoringService.getUnsentLogs(
        serviceName: serviceName,
        limit: 100,
      );

      if (logsResponse.logs.isEmpty) return;

      // Initialize history list if not exists
      if (!_serviceLogsHistory.containsKey(serviceName)) {
        _serviceLogsHistory[serviceName] = [];
      }

      // Convert logs to chart data points
      final logIds = <String>[];
      for (var log in logsResponse.logs) {
        logIds.add(log.id);

        // Check for recovery attempt messages in logs
        await _checkRecoveryAttempts(serviceName, log);

        // Determine status from the log's status field: 1 = UP (active), 0 = DOWN (inactive/failed)
        double statusValue;
        final logStatus = log.status?.toLowerCase() ?? '';

        if (logStatus == 'active' || logStatus == 'running' || logStatus == 'up') {
          statusValue = 1.0; // UP
        } else if (logStatus == 'inactive' || logStatus == 'stopped' || logStatus == 'down') {
          statusValue = 0.0; // DOWN
        } else if (logStatus == 'warning' || logStatus == 'degraded') {
          statusValue = 0.5; // WARNING
        } else {
          // Fallback: try to parse from message if status field is not clear
          final message = log.message.toLowerCase();
          if (message.contains('active=true') || message.contains('status=active')) {
            statusValue = 1.0;
          } else if (message.contains('active=false') || message.contains('status=inactive')) {
            statusValue = 0.0;
          } else {
            statusValue = 0.5; // Unknown state
          }
        }

        final point = ServiceLogPoint(
          timestamp: DateTime.tryParse(log.timestamp) ?? DateTime.now(),
          status: statusValue,
          level: log.logLevel,
          message: log.message,
        );

        _serviceLogsHistory[serviceName]!.add(point);
      }

      // Sort by timestamp
      _serviceLogsHistory[serviceName]!.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Keep last 50 data points per service
      if (_serviceLogsHistory[serviceName]!.length > 50) {
        _serviceLogsHistory[serviceName] =
            _serviceLogsHistory[serviceName]!.sublist(_serviceLogsHistory[serviceName]!.length - 50);
      }

      // Mark logs as received to avoid duplicates
      if (logIds.isNotEmpty) {
        await _monitoringService.markLogsAsSent(logIds);
      }
    } catch (e) {
      // Don't fail the whole operation if one service fails
      debugPrint('Error loading logs for $serviceName: $e');
    }
  }

  /// Check recovery attempts in log messages and send notification if max attempts reached
  /// This counts ERROR logs with "restart failed" as each represents a failed restart attempt
  Future<void> _checkRecoveryAttempts(String serviceName, Log log) async {
    try {
      // Get the managed service config for this service
      final managedService = _managedServicesConfig[serviceName];
      if (managedService == null) return;

      final message = log.message.toLowerCase();
      final logLevel = log.logLevel.toUpperCase();
      final logStatus = log.status?.toLowerCase() ?? '';
      final tags = log.tags ?? [];

      // Initialize recovery attempts counter if not exists
      if (!_recoveryAttempts.containsKey(serviceName)) {
        _recoveryAttempts[serviceName] = 0;
      }

      // Check if service is back to active/running - reset counter and notification flag
      if (logStatus == 'active' ||
          logStatus == 'running' ||
          logStatus == 'up' ||
          message.contains('status=active') ||
          message.contains('active=true')) {

        // Reset counters when service recovers
        _recoveryAttempts[serviceName] = 0;
        _notificationSent[serviceName] = false;
        _lastLogLevel[serviceName] = logLevel;
        debugPrint('✅ Service $serviceName recovered - counters reset');
        return;
      }

      // Check if this is an ERROR log indicating a failed restart attempt
      // Pattern: ERROR with "restart failed" and tags containing "remediation" or "restart"
      final isRestartError = logLevel == 'ERROR' &&
          (message.contains('restart failed') ||
           message.contains('failed to restart')) &&
          (tags.contains('remediation') || tags.contains('restart'));

      if (isRestartError) {
        // Increment the recovery attempts counter
        _recoveryAttempts[serviceName] = (_recoveryAttempts[serviceName] ?? 0) + 1;
        final currentAttempts = _recoveryAttempts[serviceName]!;

        debugPrint('❌ Service $serviceName: Recovery attempt $currentAttempts FAILED (ERROR log with restart failed)');

        // Check if max attempts reached
        final maxAttempts = managedService.recovery.maxRecoveryAttempts;
        if (currentAttempts >= maxAttempts &&
            _notificationSent[serviceName] != true) {

          // Send notification
          await _sendMaxAttemptsNotification(serviceName, managedService, currentAttempts);

          // Mark as sent to avoid duplicate notifications
          _notificationSent[serviceName] = true;

          debugPrint('🔔 Notification sent for $serviceName: Max recovery attempts ($maxAttempts) reached after $currentAttempts failed restart attempts');
        }
      }

      // Track INFO logs showing service status for debugging
      if (logLevel == 'INFO' && logStatus == 'inactive') {
        final currentAttempts = _recoveryAttempts[serviceName] ?? 0;
        debugPrint('ℹ️  Service $serviceName: Status check - inactive (attempts so far: $currentAttempts)');
      }

      // Update last log level for this service
      _lastLogLevel[serviceName] = logLevel;

    } catch (e) {
      debugPrint('Error checking recovery attempts for $serviceName: $e');
    }
  }

  /// Send notification when max recovery attempts are reached
  Future<void> _sendMaxAttemptsNotification(
    String serviceName,
    ManagedService managedService,
    int attempts,
  ) async {
    try {
      await _notificationService.sendNotification(
        serviceName: serviceName,
        host: managedService.hostId,
        eventType: 'service_restart_failed',
        message: 'Service $serviceName failed to recover after $attempts attempts. Maximum recovery attempts (${managedService.recovery.maxRecoveryAttempts}) reached.',
      );

      // Show snackbar to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notification sent: $serviceName reached max recovery attempts',
            ),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending notification for $serviceName: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final width = isMobile
            ? constraints.maxWidth * 0.95
            : constraints.maxWidth * 0.85;
        final height = isMobile
            ? constraints.maxHeight * 0.9
            : constraints.maxHeight * 0.8;

        return Dialog(
          backgroundColor: AppColors.primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          ),
          child: Container(
            width: width > 1200 ? 1200 : width,
            height: height,
            padding: const EdgeInsets.all(AppConfig.padding * 1.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                if (_isLoading && _services.isEmpty)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_errorMessage.isNotEmpty && _services.isEmpty)
                  Expanded(child: _buildErrorState(context))
                else
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryCards(context),
                          const SizedBox(height: 24),
                          _buildIndividualServiceCharts(context),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 600;
      if (isSmall) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    EvaIcons.activity,
                    color: AppColors.accentOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Services Monitoring',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.textOnPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        widget.host.hostname,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textLight,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: RotationTransition(
                    turns: _refreshController,
                    child: const Icon(Icons.refresh, color: AppColors.textOnPrimary),
                  ),
                  onPressed: _isLoading ? null : _loadServicesAndLogs,
                  tooltip: 'Refresh',
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textOnPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
            if (_lastUpdated.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Updated: ${_formatTimestamp(_lastUpdated)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textLight,
                      ),
                ),
              ),
            ],
          ],
        );
      } else {
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                EvaIcons.activity,
                color: AppColors.accentOrange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Services Monitoring',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textOnPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    widget.host.hostname,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textLight,
                        ),
                  ),
                ],
              ),
            ),
            if (_lastUpdated.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  'Updated: ${_formatTimestamp(_lastUpdated)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textLight,
                      ),
                ),
              ),
            IconButton(
              icon: RotationTransition(
                turns: _refreshController,
                child: const Icon(Icons.refresh, color: AppColors.textOnPrimary),
              ),
              onPressed: _isLoading ? null : _loadServicesAndLogs,
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textOnPrimary),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Close',
            ),
          ],
        );
      }
    });
  }

  Widget _buildSummaryCards(BuildContext context) {
    int unsentLogs = 0;
    int activeServices = 0;
    int errorServices = 0;

    for (var service in _services) {
      unsentLogs += service.unsentLogs;

      if (service.latestLevel?.toUpperCase() == 'ERROR' ||
          service.latestLevel?.toUpperCase() == 'CRITICAL') {
        errorServices++;
      }

      if (service.latestStatus?.toLowerCase() == 'active') {
        activeServices++;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int columns = 4;
        if (width < 500) {
          columns = 1;
        } else if (width < 900) {
          columns = 2;
        }

        final spacing = 12.0;
        final cardWidth = (width - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildSummaryCard(
                context,
                icon: EvaIcons.layersOutline,
                label: 'Total Services',
                value: _services.length.toString(),
                color: AppColors.info,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildSummaryCard(
                context,
                icon: EvaIcons.checkmarkCircle2,
                label: 'Active',
                value: activeServices.toString(),
                color: AppColors.success,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildSummaryCard(
                context,
                icon: EvaIcons.alertTriangle,
                label: 'Errors',
                value: errorServices.toString(),
                color: AppColors.error,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildSummaryCard(
                context,
                icon: EvaIcons.fileTextOutline,
                label: 'Unsent Logs',
                value: unsentLogs.toString(),
                color: AppColors.warning,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      color: AppColors.primaryBase,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const Spacer(),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textLight,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualServiceCharts(BuildContext context) {
    if (_services.isEmpty) {
      return Card(
        color: AppColors.primaryBase,
        child: Padding(
          padding: const EdgeInsets.all(AppConfig.padding * 2),
          child: Center(
            child: Column(
              children: [
                const Icon(
                  EvaIcons.infoOutline,
                  size: 48,
                  color: AppColors.textLight,
                ),
                const SizedBox(height: 12),
                Text(
                  'No services found for this host',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textLight,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(
                EvaIcons.pieChartOutline,
                size: 20,
                color: AppColors.accentOrange,
              ),
              const SizedBox(width: 8),
              Text(
                'Individual Service Charts',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnPrimary,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    final allExpanded = _expandedServices.values.every((e) => e);
                    for (var serviceId in _expandedServices.keys) {
                      _expandedServices[serviceId] = !allExpanded;
                    }
                  });
                },
                icon: Icon(
                  _expandedServices.values.every((e) => e)
                      ? Icons.unfold_less
                      : Icons.unfold_more,
                  size: 16,
                  color: AppColors.accentOrange,
                ),
                label: Text(
                  _expandedServices.values.every((e) => e)
                      ? 'Collapse All'
                      : 'Expand All',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.accentOrange,
                  ),
                ),
              ),
            ],
          ),
        ),
        ..._services.map((service) => _buildServiceCard(context, service)),
      ],
    );
  }

  Widget _buildServiceCard(BuildContext context, Service service) {
    final isExpanded = _expandedServices[service.id] ?? false;
    final hasData = _serviceLogsHistory.containsKey(service.id) &&
                    _serviceLogsHistory[service.id]!.length >= 2;

    // Get service color based on status
    Color serviceColor = _getLevelColor(service.latestLevel);

    return Card(
      color: AppColors.primaryBase,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        side: BorderSide(
          color: serviceColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Header
          InkWell(
            onTap: () {
              setState(() {
                _expandedServices[service.id] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppConfig.borderRadius),
              bottom: isExpanded ? Radius.zero : Radius.circular(AppConfig.borderRadius),
            ),
            child: Container(
              padding: const EdgeInsets.all(AppConfig.padding),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.3),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppConfig.borderRadius),
                  bottom: isExpanded ? Radius.zero : Radius.circular(AppConfig.borderRadius),
                ),
              ),
              child: Row(
                children: [
                  // Status indicator
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: serviceColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: serviceColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Service name and info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.id,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.textOnPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (service.latestLevel != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: serviceColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  service.latestLevel!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: serviceColor,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            if (service.serviceType != null)
                              Text(
                                service.serviceType!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            const Spacer(),
                            if (service.latestTimestamp != null)
                              Text(
                                _formatTimestamp(service.latestTimestamp!),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Stats badges
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(EvaIcons.fileTextOutline,
                                   size: 12,
                                   color: AppColors.info),
                        const SizedBox(width: 4),
                        Text(
                          '${service.totalLogs}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (service.unsentLogs > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(EvaIcons.emailOutline,
                                     size: 12,
                                     color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            '${service.unsentLogs}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Expand/Collapse icon
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textLight,
                  ),
                ],
              ),
            ),
          ),
          // Expandable chart section
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(AppConfig.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chart title with legend
                  Row(
                    children: [
                      const Icon(
                        EvaIcons.trendingUpOutline,
                        size: 16,
                        color: AppColors.accentOrange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Status Timeline',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textOnPrimary,
                            ),
                      ),
                      const Spacer(),
                      _buildServiceStatusLegend(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Chart
                  if (!hasData)
                    const SizedBox(
                      height: 150,
                      child: Center(
                        child: Text(
                          'Collecting data...\nChart will appear after receiving logs.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                  else
                    _buildServiceChart(service),
                  const SizedBox(height: 12),
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (service.unsentLogs > 0)
                        TextButton.icon(
                          onPressed: () => _showLogsDialog(context, service),
                          icon: const Icon(EvaIcons.eyeOutline, size: 14),
                          label: const Text('View Unsent Logs'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.accentOrange,
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServiceChart(Service service) {
    final logs = _serviceLogsHistory[service.id] ?? [];
    if (logs.length < 2) return const SizedBox.shrink();

    // Calculate required width based on data points
    final double pointsWidth = logs.length * 40.0;
    final double minChartWidth = 400.0;
    final double chartWidth = math.max(minChartWidth, pointsWidth);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: chartWidth,
        height: 180,
        child: LineChart(_buildSingleServiceChartData(logs, service.id)),
      ),
    );
  }

  LineChartData _buildSingleServiceChartData(List<ServiceLogPoint> logs, String serviceName) {
    // Create spots for this service's status over time
    final spots = logs.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.status);
    }).toList();

    // Determine service color based on latest status
    Color lineColor = AppColors.info;
    if (logs.isNotEmpty) {
      final latestStatus = logs.last.status;
      if (latestStatus >= 0.8) {
        lineColor = AppColors.success;
      } else if (latestStatus >= 0.3) {
        lineColor = AppColors.warning;
      } else {
        lineColor = AppColors.error;
      }
    }

    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          color: lineColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              // Color the dot based on status value
              Color dotColor;
              if (spot.y >= 0.8) {
                dotColor = AppColors.success; // UP
              } else if (spot.y >= 0.3) {
                dotColor = AppColors.warning; // WARNING
              } else {
                dotColor = AppColors.error; // DOWN
              }
              return FlDotCirclePainter(
                radius: 4,
                color: dotColor,
                strokeWidth: 2,
                strokeColor: AppColors.primaryDark,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                lineColor.withValues(alpha: 0.2),
                lineColor.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      minY: 0,
      maxY: 1,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            interval: 0.5,
            getTitlesWidget: (value, meta) {
              String label;
              if (value == 1.0) {
                label = 'UP';
              } else if (value == 0.5) {
                label = 'WARN';
              } else if (value == 0.0) {
                label = 'DOWN';
              } else {
                return const SizedBox.shrink();
              }
              return Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 25,
            interval: (logs.length / 5).ceilToDouble().clamp(1, double.infinity),
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < logs.length) {
                final timestamp = logs[value.toInt()].timestamp;
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 0.5,
        getDrawingHorizontalLine: (value) {
          Color lineColorGrid;
          if (value == 1.0) {
            lineColorGrid = AppColors.success.withValues(alpha: 0.2);
          } else if (value == 0.5) {
            lineColorGrid = AppColors.warning.withValues(alpha: 0.2);
          } else if (value == 0.0) {
            lineColorGrid = AppColors.error.withValues(alpha: 0.2);
          } else {
            lineColorGrid = AppColors.border.withValues(alpha: 0.1);
          }
          return FlLine(
            color: lineColorGrid,
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        },
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (spot) => AppColors.primaryDark.withValues(alpha: 0.9),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              String statusLabel;
              Color statusColor;
              if (spot.y >= 0.8) {
                statusLabel = 'UP';
                statusColor = AppColors.success;
              } else if (spot.y >= 0.3) {
                statusLabel = 'WARNING';
                statusColor = AppColors.warning;
              } else {
                statusLabel = 'DOWN';
                statusColor = AppColors.error;
              }

              final log = logs[spot.x.toInt()];
              final time = '${log.timestamp.hour.toString().padLeft(2, '0')}:'
                          '${log.timestamp.minute.toString().padLeft(2, '0')}:'
                          '${log.timestamp.second.toString().padLeft(2, '0')}';

              return LineTooltipItem(
                '$statusLabel\n$time\n${log.level}',
                TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildServiceStatusLegend() {
    return Wrap(
      spacing: 6,
      runSpacing: 2,
      children: [
        _buildLegendItem('UP', AppColors.success),
        _buildLegendItem('WARN', AppColors.warning),
        _buildLegendItem('DOWN', AppColors.error),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(EvaIcons.alertCircle, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Error loading services',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppColors.textOnPrimary),
          ),
          const SizedBox(height: 8),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppConfig.padding * 2),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textLight),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadServicesAndLogs,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Show dialog to view and clear unsent logs for a service
  void _showLogsDialog(BuildContext context, Service service) {
    showDialog(
      context: context,
      builder: (context) => _UnsentLogsDialog(
        serviceName: service.id,
        monitoringService: _monitoringService,
        onLogsCleared: () {
          // Refresh the services list after clearing logs
          _loadServicesAndLogs();
        },
      ),
    );
  }

  Color _getLevelColor(String? level) {
    if (level == null) return AppColors.textSecondary;
    switch (level.toUpperCase()) {
      case 'ERROR':
      case 'CRITICAL':
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

/// Data class to track individual service log point for charts
class ServiceLogPoint {
  final DateTime timestamp;
  final double status; // 1.0 = UP, 0.5 = WARNING, 0.0 = DOWN
  final String level;
  final String message;

  ServiceLogPoint({
    required this.timestamp,
    required this.status,
    required this.level,
    required this.message,
  });
}

/// Dialog to view and clear unsent logs for a service
class _UnsentLogsDialog extends StatefulWidget {
  final String serviceName;
  final MonitoringService monitoringService;
  final VoidCallback onLogsCleared;

  const _UnsentLogsDialog({
    required this.serviceName,
    required this.monitoringService,
    required this.onLogsCleared,
  });

  @override
  State<_UnsentLogsDialog> createState() => _UnsentLogsDialogState();
}

class _UnsentLogsDialogState extends State<_UnsentLogsDialog> {
  List<Log> _logs = [];
  bool _isLoading = true;
  bool _isClearing = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUnsentLogs();
  }

  Future<void> _loadUnsentLogs() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await widget.monitoringService.getUnsentLogs(
        serviceName: widget.serviceName,
        limit: 100,
      );

      setState(() {
        _logs = response.logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsSent() async {
    if (_logs.isEmpty) return;

    try {
      setState(() {
        _isClearing = true;
      });

      final logIds = _logs.map((log) => log.id).toList();
      final response = await widget.monitoringService.markLogsAsSent(logIds);

      setState(() {
        _isClearing = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${response.markedCount} logs marked as sent'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      // Notify parent and close dialog
      widget.onLogsCleared();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isClearing = false;
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final width = isMobile
            ? constraints.maxWidth * 0.95
            : constraints.maxWidth * 0.7;
        final height = isMobile
            ? constraints.maxHeight * 0.9
            : constraints.maxHeight * 0.7;

        return Dialog(
          backgroundColor: AppColors.primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          ),
          child: Container(
            width: width,
            height: height,
            padding: const EdgeInsets.all(AppConfig.padding * 1.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        EvaIcons.emailOutline,
                        color: AppColors.warning,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unsent Logs',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.textOnPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            widget.serviceName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textLight,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textOnPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage.isNotEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(EvaIcons.alertCircle,
                                      size: 48, color: AppColors.error),
                                  const SizedBox(height: 12),
                                  Text(
                                    _errorMessage,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: AppColors.textLight),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: _loadUnsentLogs,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : _logs.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(EvaIcons.checkmarkCircle2,
                                          size: 48, color: AppColors.success),
                                      SizedBox(height: 12),
                                      Text(
                                        'No unsent logs',
                                        style: TextStyle(color: AppColors.textLight),
                                      ),
                                    ],
                                  ),
                                )
                              : _buildLogsList(),
                ),
                // Footer with action button
                if (_logs.isNotEmpty) ...[
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_logs.length} unsent logs',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textLight,
                            ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isClearing ? null : _markAllAsSent,
                        icon: _isClearing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(EvaIcons.checkmarkCircle2),
                        label: Text(_isClearing ? 'Clearing...' : 'Mark All as Sent'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.textOnPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogsList() {
    return ListView.builder(
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        return Card(
          color: AppColors.primaryBase,
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getLevelColor(log.logLevel).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.logLevel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getLevelColor(log.logLevel),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatLogTimestamp(log.timestamp),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  log.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textOnPrimary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
      case 'CRITICAL':
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

  String _formatLogTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }
}
