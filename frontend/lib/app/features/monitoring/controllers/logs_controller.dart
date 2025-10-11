import 'package:get/get.dart';
import '../../../models/log.dart';
import '../../../utils/services/logs_service.dart';

class LogsController extends GetxController {
  final LogsService _logsService = LogsService();

  // Observable lists
  final RxList<Log> logs = <Log>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt total = 0.obs;

  // Filter observables
  final RxString selectedServiceName = RxString('');
  final RxString selectedLogLevel = 'ALL'.obs;
  final RxInt selectedHours = 24.obs;
  final RxInt selectedLimit = 100.obs;

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
  final List<int> limitOptions = [50, 100, 200, 500, 1000];

  @override
  void onInit() {
    super.onInit();
    // Check if we have initial filters from navigation
    if (Get.parameters.containsKey('service')) {
      selectedServiceName.value = Get.parameters['service'] ?? '';
    }
    fetchLogs();
  }

  Future<void> fetchLogs() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _logsService.getLogs(
        serviceName: selectedServiceName.value.isEmpty ? null : selectedServiceName.value,
        logLevel: selectedLogLevel.value == 'ALL' ? null : selectedLogLevel.value,
        hours: selectedHours.value,
        limit: selectedLimit.value,
      );

      logs.value = response.logs;
      total.value = response.total;
    } catch (e) {
      errorMessage.value = e.toString();
      logs.clear();
    } finally {
      isLoading.value = false;
    }
  }

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
    fetchLogs();
  }

  void clearFilters() {
    selectedServiceName.value = '';
    selectedLogLevel.value = 'ALL';
    selectedHours.value = 24;
    selectedLimit.value = 100;
    fetchLogs();
  }

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
