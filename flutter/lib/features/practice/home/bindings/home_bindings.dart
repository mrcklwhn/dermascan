import 'package:dermascan/features/practice/doctors/bindings/doctors_bindings.dart';
import 'package:dermascan/features/practice/home/controller/home_controller.dart';
import 'package:dermascan/features/practice/profile/bindings/profile_bindings.dart';
import 'package:get/get.dart';

class PracticeHomeBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PracticeHomeController());
    DoctorsBindings().dependencies();
    PracticeProfileBindings().dependencies();
  }
}
