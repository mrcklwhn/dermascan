import 'package:dermascan/features/practice/doctors/controller/doctors_controller.dart';
import 'package:get/get.dart';

class DoctorsBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DoctorsController());
  }
}
