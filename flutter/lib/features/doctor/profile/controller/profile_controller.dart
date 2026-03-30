import 'dart:async';

import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/widgets/custom_dialog.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorProfileController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  DBService dbService = Get.find<DBService>();

  ScrollController scrollController = ScrollController();

  TextEditingController nameController = TextEditingController();

  FocusNode nameFocusNode = FocusNode();

  RxBool isLoading = false.obs;
  RxBool isInitializing = true.obs;

  @override
  void onClose() {
    scrollController.dispose();
    nameController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_initializeData());
  }

  Future<void> _initializeData() async {
    try {
      await loadDoctorData();
      await loadPracticeData();
      updateNameController(name: authService.currentDoctor.value!.name);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error while loading doctor data: $e');
      }
    } finally {
      isInitializing.value = false;
    }
  }

  Future<void> loadDoctorData() async {
    final String? doctorId = authService.currentUser.value?.id;

    if (doctorId == null) return;

    final Doctor? fetchedDoctor = await dbService.fetchDoctor(id: doctorId);

    if (fetchedDoctor == null) return;

    authService.currentDoctor.value = fetchedDoctor;
  }

  Future<void> loadPracticeData() async {
    if (authService.currentDoctor.value == null) return;

    final String? practiceId = authService.currentDoctor.value!.practiceId;

    if (practiceId == null) return;

    final Practice? fetchedPractice = await dbService.fetchPractice(
      id: practiceId,
    );

    if (fetchedPractice == null) return;

    authService.currentPractice.value = fetchedPractice;
  }

  Future<void> submitName({required String newName}) async {
    if (isLoading.value || isInitializing.value) return;

    if (authService.currentDoctor.value == null) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Authentication Error',
          message: 'You are not signed in correctly. Please log in again.',
        ),
      );
      return;
    }

    if (newName.trim() == authService.currentDoctor.value!.name) {
      updateNameController(name: authService.currentDoctor.value!.name);
      return;
    }

    if (newName.trim().isEmpty) {
      updateNameController(name: authService.currentDoctor.value!.name);
      return;
    }

    isLoading.value = true;

    try {
      final Doctor? fetchedDoctor = await dbService.changeDoctorName(
        newName: newName.trim(),
      );

      if (fetchedDoctor != null) {
        authService.currentDoctor.value = fetchedDoctor;
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.check_circle,
            title: 'Updated Name',
            message:
                "Your name was successfully changed to '${newName.trim()}'.",
          ),
        );
      } else {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Update Name Failed',
            message:
                'Your name could not be changed. Please check the data or try again later.',
          ),
        );
      }
    } finally {
      updateNameController(name: authService.currentDoctor.value!.name);
      isLoading.value = false;
    }
  }

  Future<void> leaveCurrentPractice() async {
    if (isLoading.value || isInitializing.value) return;

    if (authService.currentDoctor.value == null) return;

    final String? doctorId = authService.currentUser.value?.id;

    if (doctorId == null) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Authentication Error',
          message: 'You are not signed in correctly. Please log in again.',
        ),
      );
      return;
    }

    isLoading.value = true;

    try {
      final bool success = await dbService.leaveCurrentPractice(
        doctorId: authService.currentDoctor.value!.id,
      );
      if (Get.isDialogOpen ?? false) Get.back();
      if (success) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.check,
            title: 'Practice Left',
            message:
                'You are no longer a member of this practice and your access has been revoked.',
          ),
        );
        await authService.evaluateRouteAndNavigate();
      } else {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Error Leaving Practice',
            message:
                'The practice could not be left. You may have already been removed.',
          ),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> showLeavePracticeDialog() async {
    if (isLoading.value || isInitializing.value) return;

    await Get.dialog(
      Obx(
        () => CustomDialog(
          title: 'Leave Practice?',
          subtitle:
              'You are about to leave this practice. You will no longer have access to any shared data with it. Do you want to continue?',
          isDismissable: true,
          onSubmit: isLoading.value || isInitializing.value
              ? null
              : () async => await leaveCurrentPractice(),
          submitText: 'Leave',
        ),
      ),
    );
  }

  void updateNameController({required String name}) {
    nameController.text = name;
  }

  Future<void> openChangeEmailScreen() async {
    if (isLoading.value || isInitializing.value) return;

    await Get.toNamed('/auth/change-mail');
  }

  Future<void> openChangePasswordScreen() async {
    if (isLoading.value || isInitializing.value) return;

    await Get.toNamed('/auth/change-password');
  }

  Future<void> showLogoutDialog() async {
    if (isLoading.value || isInitializing.value) return;

    await Get.dialog(const CustomLogoutDialog());
  }
}
