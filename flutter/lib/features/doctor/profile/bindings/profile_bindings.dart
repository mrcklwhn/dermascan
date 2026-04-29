import 'package:dermascan/features/doctor/profile/controller/profile_controller.dart';
import 'package:get/get.dart';

class DoctorProfileBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DoctorProfileController());
  }
}
