import 'package:dermascan/features/doctor/practice/controller/practice_details_controller.dart';
import 'package:get/get.dart';

class PracticeBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PracticeDetailsController());
  }
}
