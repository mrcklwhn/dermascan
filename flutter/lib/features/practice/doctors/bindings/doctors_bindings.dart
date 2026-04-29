import 'package:dermascan/features/practice/doctors/controller/available_doctors_controller.dart';
import 'package:dermascan/features/practice/doctors/controller/doctor_details_controller.dart';
import 'package:dermascan/features/practice/doctors/controller/doctors_controller.dart';
import 'package:dermascan/features/practice/doctors/controller/invited_doctors_controller.dart';
import 'package:get/get.dart';

class DoctorsBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DoctorsController());
    Get.lazyPut(() => AvailableDoctorsController());
    Get.lazyPut(() => DoctorDetailsController());
    Get.lazyPut(() => InvitedDoctorsController());
  }
}
