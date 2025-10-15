import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/managed_service.dart';
import '../../../models/host.dart';
import '../../../utils/services/managed_service_service.dart';
import '../../../utils/services/host_service.dart';
import '../../../utils/exceptions/api_exception.dart';

class ManagedServicesController extends GetxController {
  final ManagedServiceService _service = ManagedServiceService();
  final HostService _hostService = HostService();

  // Scaffold key for drawer
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // Observable state
  final RxList<ManagedService> services = <ManagedService>[].obs;
  final RxList<Host> availableHosts = <Host>[].obs;
  final RxList<String> availableServiceTypes = <String>[
    'mysql',
    'nginx',
    'apache',
    'postgresql',
    'mongodb',
    'redis',
    'docker',
    'ssh'
  ].obs;
  final RxList<String> availableEnvironments = <String>[
    'dev',
    'staging',
    'production'
  ].obs;
  final RxList<String> availableRegions = <String>[
    'Guatemala',
    'US',
    'Pending',
    'Other'
  ].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString errorMessage = ''.obs;

  // Pagination
  final RxInt currentPage = 0.obs;
  final RxInt totalServices = 0.obs;
  final int pageSize = 50;

  // Filters
  final Rx<String?> filterHostId = Rx<String?>(null);
  final Rx<String?> filterServiceType = Rx<String?>(null);
  final Rx<String?> filterEnvironment = Rx<String?>(null);
  final Rx<String?> filterRegion = Rx<String?>(null);
  final Rx<String?> filterStatus = Rx<String?>(null);

  // Summary data
  final Rx<ServiceSummaryData?> summaryData = Rx<ServiceSummaryData?>(null);

  @override
  void onInit() {
    super.onInit();
    // If hostId is passed as an argument, set the filter
    if (Get.arguments != null && Get.arguments['hostId'] != null) {
      filterHostId.value = Get.arguments['hostId'];
    }
    loadHosts();
    loadServices();
    loadSummary();
  }

  /// Load available hosts for dropdown
  Future<void> loadHosts() async {
    try {
      final response = await _hostService.getHosts(limit: 1000);
      availableHosts.value = response.data.hosts;
    } catch (e) {
      // Silently fail, not critical
    }
  }

  /// Get host by ID
  Host? getHostById(String hostId) {
    try {
      return availableHosts.firstWhere((h) => h.hostId == hostId);
    } catch (e) {
      return null;
    }
  }

  /// Load services with current filters and pagination
  Future<void> loadServices({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPage.value = 0;
        services.clear();
      }

      isLoading.value = true;
      errorMessage.value = '';

      final response = await _service.getServices(
        skip: currentPage.value * pageSize,
        limit: pageSize,
        hostId: filterHostId.value,
        serviceType: filterServiceType.value,
        environment: filterEnvironment.value,
        region: filterRegion.value,
        status: filterStatus.value,
      );

      if (refresh) {
        services.value = response.data.services;
      } else {
        services.addAll(response.data.services);
      }

      totalServices.value = response.data.count;
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      Get.snackbar(
        'Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to load services: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Load dashboard summary
  Future<void> loadSummary() async {
    try {
      final response = await _service.getDashboardSummary();
      summaryData.value = response.data;
    } catch (e) {
      // Silently fail for summary, not critical
    }
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (isLoadingMore.value) return;
    if ((currentPage.value + 1) * pageSize >= totalServices.value) return;

    try {
      isLoadingMore.value = true;
      currentPage.value++;
      await loadServices();
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Load previous page
  Future<void> loadPreviousPage() async {
    if (isLoadingMore.value) return;
    if (currentPage.value <= 0) return;

    try {
      isLoadingMore.value = true;
      currentPage.value--;
      services.clear();
      await loadServices();
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Create new service
  Future<bool> createService({
    String? serviceId,
    required String hostId,
    required String serviceName,
    required String serviceType,
    String? displayName,
    String? description,
    required String environment,
    required String region,
    required ServiceMonitoring monitoring,
    required ServiceRecovery recovery,
    required ServiceAlerting alerting,
    List<String>? tags,
    List<String>? dependencies,
  }) async {
    try {
      isLoading.value = true;

      await _service.createService(
        serviceId: serviceId,
        hostId: hostId,
        serviceName: serviceName,
        serviceType: serviceType,
        displayName: displayName,
        description: description,
        environment: environment,
        region: region,
        monitoring: monitoring,
        recovery: recovery,
        alerting: alerting,
        tags: tags,
        dependencies: dependencies,
      );

      Get.snackbar(
        'Success',
        'Service created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
      );

      // Refresh service list
      await loadServices(refresh: true);
      await loadSummary();
      return true;
    } on ApiException catch (e) {
      Get.snackbar(
        'Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create service: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update service
  Future<bool> updateService({
    required String serviceId,
    String? hostId,
    String? serviceName,
    String? serviceType,
    String? displayName,
    String? description,
    String? environment,
    String? region,
    ServiceMonitoring? monitoring,
    ServiceRecovery? recovery,
    ServiceAlerting? alerting,
    List<String>? tags,
    List<String>? dependencies,
    String? status,
  }) async {
    try {
      isLoading.value = true;

      await _service.updateService(
        serviceId: serviceId,
        hostId: hostId,
        serviceName: serviceName,
        serviceType: serviceType,
        displayName: displayName,
        description: description,
        environment: environment,
        region: region,
        monitoring: monitoring,
        recovery: recovery,
        alerting: alerting,
        tags: tags,
        dependencies: dependencies,
        status: status,
      );

      Get.snackbar(
        'Success',
        'Service updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
      );

      // Refresh service list and summary to get the updated data
      await loadServices(refresh: true);
      await loadSummary();
      return true;
    } on ApiException catch (e) {
      Get.snackbar(
        'Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update service: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete service
  Future<void> deleteService(String serviceId) async {
    try {
      // Show confirmation dialog
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete Service'),
          content: const Text(
            'Are you sure you want to delete this service? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      isLoading.value = true;

      await _service.deleteService(serviceId);

      // Remove from list
      services.removeWhere((s) => s.serviceId == serviceId);
      totalServices.value--;

      Get.snackbar(
        'Success',
        'Service deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
      );

      await loadSummary();
    } on ApiException catch (e) {
      Get.snackbar(
        'Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete service: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Set host filter (used when navigating from hosts screen)
  void setHostFilter(String? hostId) {
    filterHostId.value = hostId;
    loadServices(refresh: true);
  }

  /// Toggle service type filter
  void setServiceTypeFilter(String? serviceType) {
    filterServiceType.value = serviceType;
    loadServices(refresh: true);
  }

  /// Toggle environment filter
  void setEnvironmentFilter(String? environment) {
    filterEnvironment.value = environment;
    loadServices(refresh: true);
  }

  /// Toggle region filter
  void setRegionFilter(String? region) {
    filterRegion.value = region;
    loadServices(refresh: true);
  }

  /// Toggle status filter
  void setStatusFilter(String? status) {
    filterStatus.value = status;
    loadServices(refresh: true);
  }

  /// Clear all filters
  void clearFilters() {
    filterHostId.value = null;
    filterServiceType.value = null;
    filterEnvironment.value = null;
    filterRegion.value = null;
    filterStatus.value = null;
    loadServices(refresh: true);
  }

  /// Refresh services
  @override
  Future<void> refresh() async {
    await loadServices(refresh: true);
    await loadSummary();
  }

  // Computed properties
  bool get hasMore => (currentPage.value + 1) * pageSize < totalServices.value;
  bool get hasPrevious => currentPage.value > 0;
  int get currentPageNumber => currentPage.value + 1;
  int get totalPages => (totalServices.value / pageSize).ceil();
  bool get hasActiveFilters =>
      filterHostId.value != null ||
      filterServiceType.value != null ||
      filterEnvironment.value != null ||
      filterRegion.value != null ||
      filterStatus.value != null;

  String? get hostId => filterHostId.value;
}
