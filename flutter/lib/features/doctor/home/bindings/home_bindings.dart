import 'package:dermascan/features/doctor/capture/bindings/capture_bindings.dart';
import 'package:dermascan/features/doctor/home/controller/home_controller.dart';
import 'package:dermascan/features/doctor/patients/bindings/patients_bindings.dart';
import 'package:dermascan/features/doctor/profile/bindings/profile_bindings.dart';
import 'package:get/get.dart';

class DoctorHomeBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DoctorHomeController());
    PatientsBindings().dependencies();
    CaptureBindings().dependencies();
    DoctorProfileBindings().dependencies();
  }
}
