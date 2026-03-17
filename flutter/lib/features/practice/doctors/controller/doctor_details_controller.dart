import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorDetailsController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  DBService dbService = Get.find<DBService>();

  Rx<bool> isLoading = false.obs;
  Rx<bool> isAssignedToPractice = false.obs;
  late Doctor doctor;

  late void Function({required String invitedDoctorId})? removeInvitedDoctor;

  @override
  void onInit() {
    super.onInit();
    loadValuesFromRoute();
  }

  void loadValuesFromRoute() {
    final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;
    doctor = args['doctor'];
    removeInvitedDoctor = args['removeInvitedDoctor'];
    isAssignedToPractice.value = args['assignedToPractice'];
  }

  Future<void> inviteDoctorToCurrentPractice({required String doctorId}) async {
    isLoading.value = true;

    final String? practiceId = authService.currentUser.value?.id;

    if (practiceId == null) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Invitation failed',
          message: 'You are not signed in correctly.',
        ),
      );
      isLoading.value = false;
      return;
    }

    final bool success = await dbService.inviteDoctorToPractice(
      practiceId: practiceId,
      doctorId: doctorId,
    );

    if (success) {
      removeInvitedDoctor?.call(invitedDoctorId: doctorId);
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.check,
          title: 'Invitation sent',
          message: 'An invitation has been sent to ${doctor.name}!',
        ),
      );
    } else {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Invitation failed',
          message:
              'An error occurred while inviting ${doctor.name} to your practice, maybe he is already invited.',
        ),
      );
    }
    isLoading.value = false;
  }
}
