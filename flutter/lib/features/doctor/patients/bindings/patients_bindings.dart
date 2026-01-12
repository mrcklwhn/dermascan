import 'package:dermascan/features/doctor/patients/controller/patients_controller.dart';
import 'package:get/get.dart';

class PatientsBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PatientsController());
  }
}
