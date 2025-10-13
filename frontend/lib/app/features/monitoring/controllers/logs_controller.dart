import 'package:get/get.dart';
import '../../../models/log.dart';
import '../../../utils/services/logs_service.dart';

class LogsController extends GetxController {
  final LogsService _logsService = LogsService();

  // Observable lists
  final RxList<Log> allLogs = <Log>[].obs; // All fetched logs
  final RxList<Log> logs = <Log>[].obs; // Current page logs
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt total = 0.obs;

  // Client-side pagination
  final RxInt currentPage = 0.obs;
  final RxInt pageSize = 50.obs;

  // Filter observables
  final RxString selectedServiceName = RxString('');
  final RxString selectedLogLevel = 'ALL'.obs;
  final RxInt selectedHours = 24.obs;
  final RxInt selectedLimit = 500.obs; // How many logs to fetch from API

  // Dummy service names for dropdown (will be replaced with real data later)
  final RxList<String> availableServices = <String>[
    'postgres',
    'nginx',
    'redis',
    'mongodb',
    'elasticsearch',
  ].obs;

  final List<String> logLevels = ['ALL', 'ERROR', 'WARNING', 'INFO', 'DEBUG'];
  final List<int> timeRanges = [1, 6, 12, 24, 48, 72, 168]; // hours
  final List<int> limitOptions = [100, 250, 500, 1000, 2000]; // API fetch limit
  final List<int> pageSizeOptions = [25, 50, 100, 200]; // Client-side page size

  @override
  void onInit() {
    super.onInit();
    // Check if we have initial filters from navigation
    if (Get.parameters.containsKey('service')) {
      selectedServiceName.value = Get.parameters['service'] ?? '';
    }
    fetchLogs();
  }

  Future<void> fetchLogs({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPage.value = 0;
      }

      isLoading.value = true;
      errorMessage.value = '';

      final response = await _logsService.getLogs(
        serviceName: selectedServiceName.value.isEmpty ? null : selectedServiceName.value,
        logLevel: selectedLogLevel.value == 'ALL' ? null : selectedLogLevel.value,
        hours: selectedHours.value,
        limit: selectedLimit.value,
      );

      allLogs.value = response.logs;
      total.value = response.total;
      currentPage.value = 0; // Reset to first page
      _updateDisplayedLogs();
    } catch (e) {
      errorMessage.value = e.toString();
      allLogs.clear();
      logs.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Update the displayed logs based on current page
  void _updateDisplayedLogs() {
    final startIndex = currentPage.value * pageSize.value;
    final endIndex = (startIndex + pageSize.value).clamp(0, allLogs.length);

    if (startIndex < allLogs.length) {
      logs.value = allLogs.sublist(startIndex, endIndex);
    } else {
      logs.value = [];
    }
  }

  /// Load next page (client-side)
  void loadNextPage() {
    if ((currentPage.value + 1) * pageSize.value >= allLogs.length) return;
    currentPage.value++;
    _updateDisplayedLogs();
  }

  /// Load previous page (client-side)
  void loadPreviousPage() {
    if (currentPage.value <= 0) return;
    currentPage.value--;
    _updateDisplayedLogs();
  }

  /// Change page size (client-side)
  void changePageSize(int newPageSize) {
    pageSize.value = newPageSize;
    currentPage.value = 0;
    _updateDisplayedLogs();
  }

  @override
  Future<void> refresh() async {
    await fetchLogs();
  }

  void applyFilters({
    String? serviceName,
    String? logLevel,
    int? hours,
    int? limit,
  }) {
    if (serviceName != null) {
      selectedServiceName.value = serviceName;
    }
    if (logLevel != null) {
      selectedLogLevel.value = logLevel;
    }
    if (hours != null) {
      selectedHours.value = hours;
    }
    if (limit != null) {
      selectedLimit.value = limit;
    }
    fetchLogs(refresh: true);
  }

  void clearFilters() {
    selectedServiceName.value = '';
    selectedLogLevel.value = 'ALL';
    selectedHours.value = 24;
    selectedLimit.value = 500;
    fetchLogs(refresh: true);
  }

  // Computed properties for client-side pagination
  bool get hasMore => (currentPage.value + 1) * pageSize.value < allLogs.length;
  bool get hasPrevious => currentPage.value > 0;
  int get currentPageNumber => currentPage.value + 1;
  int get totalPages => allLogs.isNotEmpty ? (allLogs.length / pageSize.value).ceil() : 0;

  String getTimeRangeLabel(int hours) {
    if (hours < 24) {
      return '$hours hours';
    } else if (hours == 24) {
      return 'Last 24 hours';
    } else {
      final days = hours ~/ 24;
      return 'Last $days days';
    }
  }
}
