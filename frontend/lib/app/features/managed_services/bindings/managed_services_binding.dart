import 'package:get/get.dart';
import '../controllers/managed_services_controller.dart';

class ManagedServicesBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ManagedServicesController>(
      ManagedServicesController(),
      permanent: false, // Controller will be removed when page is closed
    );
  }
}
