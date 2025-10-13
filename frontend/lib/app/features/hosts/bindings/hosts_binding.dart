import 'package:get/get.dart';
import '../controllers/hosts_controller.dart';

class HostsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HostsController>(() => HostsController());
  }
}
