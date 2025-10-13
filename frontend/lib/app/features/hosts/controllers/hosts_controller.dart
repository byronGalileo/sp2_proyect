import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/host.dart';
import '../../../utils/services/host_service.dart';
import '../../../utils/exceptions/api_exception.dart';

class HostsController extends GetxController {
  final HostService _hostService = HostService();

  // Scaffold key for drawer
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // Observable state
  final RxList<Host> hosts = <Host>[].obs;
  final RxList<String> availableEnvironments = <String>['dev', 'staging', 'production'].obs;
  final RxList<String> availableRegions = <String>['Guatemala', 'US', 'Pending', 'Other', 'us-east-1'].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString errorMessage = ''.obs;

  // Pagination
  final RxInt currentPage = 0.obs;
  final RxInt totalHosts = 0.obs;
  final int pageSize = 50;

  // Filters
  final Rx<String?> filterEnvironment = Rx<String?>(null);
  final Rx<String?> filterRegion = Rx<String?>(null);
  final Rx<String?> filterStatus = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    loadHosts();
    loadMetadata();
  }

  /// Load hosts with current filters and pagination
  Future<void> loadHosts({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPage.value = 0;
        hosts.clear();
      }

      isLoading.value = true;
      errorMessage.value = '';

      final response = await _hostService.getHosts(
        skip: currentPage.value * pageSize,
        limit: pageSize,
        environment: filterEnvironment.value,
        region: filterRegion.value,
        status: filterStatus.value,
      );

      if (refresh) {
        hosts.value = response.data.hosts;
      } else {
        hosts.addAll(response.data.hosts);
      }

      totalHosts.value = response.data.count;
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
        'Failed to load hosts: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Load metadata (environments and regions)
  Future<void> loadMetadata() async {
    try {
      // Default values
      final defaultEnvironments = ['dev', 'staging', 'production'];
      final defaultRegions = ['Guatemala', 'US', 'Pending', 'Other'];

      // Fetch from API
      final environments = await _hostService.getEnvironments();
      final regions = await _hostService.getRegions();

      // Merge API data with defaults (remove duplicates)
      final allEnvironments = <String>{
        ...defaultEnvironments,
        ...environments.data,
      }.toList();

      final allRegions = <String>{
        ...defaultRegions,
        ...regions.data,
      }.toList();

      availableEnvironments.value = allEnvironments;
      availableRegions.value = allRegions;
    } catch (e) {
      // If API fails, keep default values already initialized
    }
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (isLoadingMore.value) return;
    if ((currentPage.value + 1) * pageSize >= totalHosts.value) return;

    try {
      isLoadingMore.value = true;
      currentPage.value++;
      await loadHosts();
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
      hosts.clear();
      await loadHosts();
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Create new host
  Future<bool> createHost({
    required String hostId,
    required String hostname,
    required String ipAddress,
    required String environment,
    required String region,
    required String sshUser,
    int sshPort = 22,
    String? sshKeyPath,
    bool useSudo = true,
    String? os,
    String? purpose,
    List<String>? tags,
  }) async {
    try {
      isLoading.value = true;

      await _hostService.createHost(
        hostId: hostId,
        hostname: hostname,
        ipAddress: ipAddress,
        environment: environment,
        region: region,
        sshUser: sshUser,
        sshPort: sshPort,
        sshKeyPath: sshKeyPath,
        useSudo: useSudo,
        os: os,
        purpose: purpose,
        tags: tags,
      );

      Get.snackbar(
        'Success',
        'Host created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
      );

      // Refresh host list
      await loadHosts(refresh: true);
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
        'Failed to create host: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update host
  Future<bool> updateHost({
    required String hostId,
    String? hostname,
    String? ipAddress,
    String? environment,
    String? region,
    String? sshUser,
    int? sshPort,
    String? sshKeyPath,
    bool? useSudo,
    String? os,
    String? purpose,
    List<String>? tags,
    String? status,
  }) async {
    try {
      isLoading.value = true;

      final response = await _hostService.updateHost(
        hostId: hostId,
        hostname: hostname,
        ipAddress: ipAddress,
        environment: environment,
        region: region,
        sshUser: sshUser,
        sshPort: sshPort,
        sshKeyPath: sshKeyPath,
        useSudo: useSudo,
        os: os,
        purpose: purpose,
        tags: tags,
        status: status,
      );

      // Update in list
      final index = hosts.indexWhere((h) => h.hostId == hostId);
      if (index != -1) {
        hosts[index] = response.data;
      }

      Get.snackbar(
        'Success',
        'Host updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
      );

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
        'Failed to update host: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete host
  Future<void> deleteHost({
    required String hostId,
    bool deleteServices = false,
  }) async {
    try {
      // Show confirmation dialog
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete Host'),
          content: Text(
            deleteServices
                ? 'Are you sure you want to delete this host and all its services? This action cannot be undone.'
                : 'Are you sure you want to delete this host? Its services will remain.',
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

      await _hostService.deleteHost(
        hostId: hostId,
        deleteServices: deleteServices,
      );

      // Remove from list
      hosts.removeWhere((h) => h.hostId == hostId);
      totalHosts.value--;

      Get.snackbar(
        'Success',
        'Host deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
      );
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
        'Failed to delete host: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggle environment filter
  void setEnvironmentFilter(String? environment) {
    filterEnvironment.value = environment;
    loadHosts(refresh: true);
  }

  /// Toggle region filter
  void setRegionFilter(String? region) {
    filterRegion.value = region;
    loadHosts(refresh: true);
  }

  /// Toggle status filter
  void setStatusFilter(String? status) {
    filterStatus.value = status;
    loadHosts(refresh: true);
  }

  /// Clear all filters
  void clearFilters() {
    filterEnvironment.value = null;
    filterRegion.value = null;
    filterStatus.value = null;
    loadHosts(refresh: true);
  }

  /// Refresh hosts
  @override
  Future<void> refresh() async {
    await loadHosts(refresh: true);
  }

  // Computed properties
  bool get hasMore => (currentPage.value + 1) * pageSize < totalHosts.value;
  bool get hasPrevious => currentPage.value > 0;
  int get currentPageNumber => currentPage.value + 1;
  int get totalPages => (totalHosts.value / pageSize).ceil();
  bool get hasActiveFilters =>
      filterEnvironment.value != null ||
      filterRegion.value != null ||
      filterStatus.value != null;
}
