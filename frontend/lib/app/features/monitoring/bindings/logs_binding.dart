import 'package:get/get.dart';
import '../controllers/logs_controller.dart';

class LogsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<LogsController>(
      LogsController(),
      permanent: false,
    );
  }
}
