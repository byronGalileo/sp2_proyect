import 'package:get/get.dart';
import '../controllers/managed_services_controller.dart';

class ManagedServicesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManagedServicesController>(
      () => ManagedServicesController(),
    );
  }
}
