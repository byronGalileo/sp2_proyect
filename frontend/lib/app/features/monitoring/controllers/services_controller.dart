import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/service.dart';
import '../../../utils/services/monitoring_service.dart';

class ServicesController extends GetxController {
  final MonitoringService _monitoringService = MonitoringService();

  // Scaffold key for drawer
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // Observable state
  final Rxn<ServicesResponse> servicesResponse = Rxn<ServicesResponse>();
  final RxList<Service> services = <Service>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString lastUpdated = ''.obs;
  final RxInt totalServices = 0.obs;

  // Filter state
  final RxString searchQuery = ''.obs;
  final RxString filterLevel = 'All'.obs;
  final RxString filterStatus = 'All'.obs;

  @override
  void onInit() {
    super.onInit();
    loadServices();
  }

  /// Load services from the monitoring API
  Future<void> loadServices() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _monitoringService.getServices();

      servicesResponse.value = response;
      services.value = response.services;
      totalServices.value = response.totalServices;
      lastUpdated.value = response.lastUpdated;
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to load services: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh services
  @override
  Future<void> refresh() async {
    await loadServices();
  }

  /// Set search query
  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Set level filter
  void setLevelFilter(String level) {
    filterLevel.value = level;
  }

  /// Set status filter
  void setStatusFilter(String status) {
    filterStatus.value = status;
  }

  /// Get filtered services based on current filters
  List<Service> get filteredServices {
    var filtered = services.toList();

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((service) {
        final query = searchQuery.value.toLowerCase();
        return service.id.toLowerCase().contains(query) ||
            (service.host?.toLowerCase().contains(query) ?? false) ||
            (service.serviceType?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply level filter
    if (filterLevel.value != 'All') {
      filtered = filtered.where((service) {
        return service.latestLevel == filterLevel.value;
      }).toList();
    }

    // Apply status filter
    if (filterStatus.value != 'All') {
      filtered = filtered.where((service) {
        return service.latestStatus == filterStatus.value;
      }).toList();
    }

    return filtered;
  }

  /// Get unique log levels from services
  List<String> get availableLevels {
    final levels = services
        .where((s) => s.latestLevel != null)
        .map((s) => s.latestLevel!)
        .toSet()
        .toList();
    levels.sort();
    return ['All', ...levels];
  }

  /// Get unique statuses from services
  List<String> get availableStatuses {
    final statuses = services
        .where((s) => s.latestStatus != null)
        .map((s) => s.latestStatus!)
        .toSet()
        .toList();
    statuses.sort();
    return ['All', ...statuses];
  }

  /// Get statistics
  Map<String, int> get statistics {
    int totalLogs = 0;
    int totalUnsentLogs = 0;

    for (var service in services) {
      totalLogs += service.totalLogs;
      totalUnsentLogs += service.unsentLogs;
    }

    return {
      'totalServices': services.length,
      'totalLogs': totalLogs,
      'totalUnsentLogs': totalUnsentLogs,
    };
  }
}
