import 'package:dermascan/features/doctor/patients/controller/create_patient_controller.dart';
import 'package:dermascan/features/doctor/patients/controller/patient_details_controller.dart';
import 'package:dermascan/features/doctor/patients/controller/patients_controller.dart';
import 'package:get/get.dart';

class PatientsBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PatientsController());
    Get.lazyPut(() => CreatePatientController());
    Get.lazyPut(() => PatientDetailsController());
  }
}
