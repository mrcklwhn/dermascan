import 'package:dermascan/features/help/controller/documentation_controller.dart';
import 'package:get/get.dart';

class HelpBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DocumentationController());
  }
}
