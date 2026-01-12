import 'package:dermascan/features/practice/profile/controller/profile_controller.dart';
import 'package:get/get.dart';

class PracticeProfileBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PracticeProfileController());
  }
}
