import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/services/host_service.dart';
import '../../../utils/services/managed_service_service.dart';
import '../../../utils/services/log_service.dart';
import '../../../utils/exceptions/api_exception.dart';

class MonitoringDashboardController extends GetxController {
  final HostService _hostService = HostService();
  final ManagedServiceService _serviceService = ManagedServiceService();
  final LogService _logService = LogService();

  // Observable state
  final RxInt activeHostsCount = 0.obs;
  final RxInt inactiveHostsCount = 0.obs;
  final RxInt inactiveServicesCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingCharts = false.obs;
  final RxString errorMessage = ''.obs;

  // Logs data for chart
  final RxMap<String, List<LogDataPoint>> logsChartData =
      <String, List<LogDataPoint>>{}.obs;
  final RxInt selectedHours = 24.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  /// Load all dashboard data
  Future<void> loadDashboardData() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await Future.wait([
        loadHostsCounts(),
        loadServicesCounts(),
        loadLogsData(),
      ]);
    } catch (e) {
      errorMessage.value = 'Failed to load dashboard data';
      Get.snackbar(
        'Error',
        'Failed to load dashboard data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Load hosts counts (active and inactive)
  Future<void> loadHostsCounts() async {
    try {
      // Get active hosts
      final activeResponse = await _hostService.getHosts(
        status: 'active',
        limit: 1,
      );
      activeHostsCount.value = activeResponse.data.count;

      // Get inactive hosts
      final inactiveResponse = await _hostService.getHosts(
        status: 'inactive',
        limit: 1,
      );
      inactiveHostsCount.value = inactiveResponse.data.count;
    } on ApiException catch (e) {
      debugPrint('Error loading hosts counts: ${e.message}');
    }
  }

  /// Load services counts
  Future<void> loadServicesCounts() async {
    try {
      final summary = await _serviceService.getDashboardSummary();
      // Inactive services = stopped + error
      inactiveServicesCount.value =
          summary.data.stoppedServices + summary.data.errorServices;
    } on ApiException catch (e) {
      debugPrint('Error loading services counts: ${e.message}');
    }
  }

  /// Load logs data for the chart
  Future<void> loadLogsData() async {
    isLoadingCharts.value = true;
    try {
      final response = await _logService.getLogs(
        hours: selectedHours.value,
        limit: 1000, // Get enough logs for accurate charting
      );

      final aggregatedData = _logService.aggregateLogsByLevelAndTime(
        response.logs,
        selectedHours.value,
      );

      logsChartData.value = aggregatedData;
    } on ApiException catch (e) {
      debugPrint('Error loading logs data: ${e.message}');
      logsChartData.value = {};
    } finally {
      isLoadingCharts.value = false;
    }
  }

  /// Change time period for logs chart
  void changeTimePeriod(int hours) {
    selectedHours.value = hours;
    loadLogsData();
  }

  /// Refresh all data
  @override
  Future<void> refresh() async {
    await loadDashboardData();
  }
}
