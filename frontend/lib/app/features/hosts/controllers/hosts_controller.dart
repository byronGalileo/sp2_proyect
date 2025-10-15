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

  // Monitoring status tracking: hostId -> isRunning
  final RxMap<String, bool> monitoringStatus = <String, bool>{}.obs;

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

  /// Check monitoring status for a specific host
  Future<void> checkMonitoringStatus(Host host) async {
    final configPath = host.metadata.configPath;
    if (configPath == null || configPath.isEmpty) {
      monitoringStatus[host.hostId] = false;
      return;
    }

    try {
      final configName = configPath.split('/').last;
      final response = await _hostService.getExecutionStatus(configName);
      final isRunning = response['data']?['is_running'] ?? false;
      monitoringStatus[host.hostId] = isRunning;
    } catch (e) {
      // If status check fails, assume not running
      monitoringStatus[host.hostId] = false;
    }
  }

  /// Check monitoring status for all loaded hosts
  Future<void> checkAllMonitoringStatus() async {
    for (final host in hosts) {
      await checkMonitoringStatus(host);
    }
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

      // Check monitoring status for all hosts
      await checkAllMonitoringStatus();
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
        ...?environments.data.environments,
      }.toList();

      final allRegions = <String>{
        ...defaultRegions,
        ...?regions.data.regions,
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
    String? hostId,
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

      await _hostService.updateHost(
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

      Get.snackbar(
        'Success',
        'Host updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
      );

      // Refresh host list to get the updated data
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
                : 'Are you sure you want to delete this host? Its related services will be remain.',
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

  /// Generate configuration file for a host
  Future<void> generateConfig(String hostId) async {
    try {
      isLoading.value = true;

      final response = await _hostService.generateConfig(hostId);

      // Show success message with details
      final message = response['message'] ?? 'Config generated successfully';
      final relativePath = response['data']?['relative_path'];
      final servicesCount = response['data']?['services_count'];

      Get.snackbar(
        'Success',
        '$message\nServices: $servicesCount\nPath: $relativePath',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
        duration: const Duration(seconds: 5),
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
        'Failed to generate config: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Start monitoring execution for a host
  /// Extracts config filename from host metadata config_path
  Future<void> startExecution(Host host) async {
    try {
      // Extract config filename from config_path
      final configPath = host.metadata.configPath;

      if (configPath == null || configPath.isEmpty) {
        Get.snackbar(
          'Error',
          'No config file found for this host. Please generate a config first.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[900],
        );
        return;
      }

      // Extract filename from path (e.g., "monitor/config/config.beagle_01.json" -> "config.beagle_01.json")
      final configName = configPath.split('/').last;

      isLoading.value = true;

      final response = await _hostService.startExecution(configName);

      // Show success message with details
      final message = response['message'] ?? 'Monitor started successfully';

      Get.snackbar(
        'Success',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
        duration: const Duration(seconds: 5),
      );

      // Update monitoring status
      await checkMonitoringStatus(host);
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
        'Failed to start monitoring: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Stop monitoring execution for a host
  /// Shows confirmation dialog before stopping
  Future<void> stopExecution(Host host) async {
    // Extract config filename from config_path
    final configPath = host.metadata.configPath;

    if (configPath == null || configPath.isEmpty) {
      Get.snackbar(
        'Error',
        'No config file found for this host.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[900],
      );
      return;
    }

    // Extract filename from path
    final configName = configPath.split('/').last;

    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Stop Monitoring'),
        content: Text(
          'Are you sure you want to stop monitoring for ${host.hostname}?\n\nThis will stop the monitoring process for config: $configName',
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
            child: const Text('Stop'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      isLoading.value = true;

      final response = await _hostService.stopExecution(configName);

      // Show success message with details
      final message = response['message'] ?? 'Monitor stopped successfully';

      Get.snackbar(
        'Success',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
        duration: const Duration(seconds: 5),
      );

      // Update monitoring status
      await checkMonitoringStatus(host);
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
        'Failed to stop monitoring: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
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
