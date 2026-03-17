import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PracticeDetailsController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  DBService dbService = Get.find<DBService>();

  Rx<bool> isLoading = false.obs;
  Rx<bool> isPracticeOfCurrentDoctor = false.obs;
  late Practice practice;

  @override
  void onInit() {
    super.onInit();
    loadValuesFromRoute();
  }

  void loadValuesFromRoute() {
    final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;
    practice = args['practice'];
    isPracticeOfCurrentDoctor.value = args['isPracticeOfCurrentDoctor'];
  }

  Future<void> acceptPracticeInvitation({required String practiceId}) async {
    isLoading.value = true;

    final String? doctorId = authService.currentUser.value?.id;

    if (doctorId == null) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Accept Invitation failed',
          message: 'You are not signed in correctly.',
        ),
      );
      isLoading.value = false;
      return;
    }

    final bool success = await dbService.acceptPracticeInvitation(
      practiceId: practiceId,
    );

    if (success) {
      authService.hasPractice.value = success;
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.check,
          title: 'Invitation accepted',
          message:
              'The invitation of the Practice ${practice.name} has been accepted!',
        ),
      );
      await authService.evaluateRouteAndNavigate();
    } else {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Accept Invitation failed',
          message:
              'An error occurred while accepting the invitation of  ${practice.name}, maybe you are already assigned.',
        ),
      );
    }

    isLoading.value = false;
  }
}
