import 'package:dermascan/features/practice/doctors/controller/assigned_doctors_controller.dart';
import 'package:dermascan/features/practice/doctors/controller/available_doctors_controller.dart';
import 'package:dermascan/features/practice/doctors/controller/doctor_details_controller.dart';
import 'package:dermascan/features/practice/doctors/controller/pending_invitations_controller.dart';
import 'package:get/get.dart';

class DoctorsBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AssignedDoctorsController());
    Get.lazyPut(() => AvailableDoctorsController());
    Get.lazyPut(() => DoctorDetailsController());
    Get.lazyPut(() => PendingInvitationsController());
  }
}
