import 'dart:async';

import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service/doctor_db_service.dart';
import 'package:dermascan/core/services/db_service/practice_db_service.dart';
import 'package:dermascan/core/widgets/custom_dialog.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorProfileController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  DoctorDbService doctorDbService = Get.find<DoctorDbService>();
  PracticeDbService practiceDbService = Get.find<PracticeDbService>();

  TextEditingController nameController = TextEditingController();

  FocusNode nameFocusNode = FocusNode();

  RxBool isLoading = false.obs;
  RxBool isInitializing = true.obs;

  @override
  void onClose() {
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
      updateNameController(name: authService.currentDoctor.value?.name ?? '');
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

    final Doctor? fetchedDoctor = await doctorDbService.fetchDoctor(id: doctorId);

    if (fetchedDoctor == null) return;

    authService.currentDoctor.value = fetchedDoctor;
  }

  Future<void> loadPracticeData() async {
    final Doctor? currentDoctor = authService.currentDoctor.value;
    if (currentDoctor == null) return;

    final String? practiceId = currentDoctor.practiceId;

    if (practiceId == null) return;

    final Practice? fetchedPractice = await practiceDbService.fetchPractice(
      id: practiceId,
    );

    if (fetchedPractice == null) return;

    authService.currentPractice.value = fetchedPractice;
  }

  Future<void> submitName({required String newName}) async {
    if (isLoading.value || isInitializing.value) return;

    if (authService.currentDoctor.value == null) {
      if (!Get.isSnackbarOpen) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: TrKeys.common.authenticationError.tr,
            message: TrKeys.common.authErrorReLogin.tr,
          ),
        );
      }
      return;
    }

    final Doctor? currentDoctor = authService.currentDoctor.value;
    if (currentDoctor == null) return;

    if (newName.trim() == currentDoctor.name) {
      updateNameController(name: currentDoctor.name);
      return;
    }

    if (newName.trim().isEmpty) {
      updateNameController(name: currentDoctor.name);
      return;
    }

    isLoading.value = true;

    try {
      final Doctor? fetchedDoctor = await doctorDbService.changeDoctorName(
        doctorId: currentDoctor.id,
        newName: newName.trim(),
      );

      if (fetchedDoctor != null) {
        authService.currentDoctor.value = fetchedDoctor;
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check_circle,
              title: TrKeys.doctor.updatedName.tr,
              message: TrKeys.doctor.nameChangedSuccess.tr,
            ),
          );
        }
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: TrKeys.doctor.updateNameFailed.tr,
              message:
                  TrKeys.auth.changeEmailFailedMsg
                      .tr,
            ),
          );
        }
      }
    } finally {
      updateNameController(name: authService.currentDoctor.value?.name ?? '');
      isLoading.value = false;
    }
  }

  Future<void> leaveCurrentPractice() async {
    if (isLoading.value || isInitializing.value) return;

    if (authService.currentDoctor.value == null) return;

    final String? doctorId = authService.currentUser.value?.id;

    if (doctorId == null) {
      if (!Get.isSnackbarOpen) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: TrKeys.common.authenticationError.tr,
            message: TrKeys.common.authErrorReLogin.tr,
          ),
        );
      }
      return;
    }

    isLoading.value = true;

    final Doctor? currentDoctor = authService.currentDoctor.value;
    if (currentDoctor == null) return;

    try {
      final bool success = await practiceDbService.leaveCurrentPractice(
        doctorId: currentDoctor.id,
      );
      if (success) {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check,
              title: TrKeys.practice.practiceLeft.tr,
              message:
                  TrKeys.practice.practiceLeftMsg.tr,
            ),
          );
        }
        await authService.evaluateRouteAndNavigate();
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: TrKeys.practice.errorLeavingPractice.tr,
              message:
                  TrKeys.practice.couldNotLeavePracticeMsg
                      .tr,
            ),
          );
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> showLeavePracticeDialog() async {
    if (isLoading.value || isInitializing.value) return;

    await CustomDialogHelper.show(
      routeName: 'leave-practice-dialog',

      title: TrKeys.practice.leavePracticeQuestion.tr,

      subtitle: TrKeys.practice.leavePracticeConfirm.tr,

      isDismissable: true,

      submitText: TrKeys.common.leave.tr,

      onSubmit: isLoading.value || isInitializing.value
          ? null
          : (_) async {
              await leaveCurrentPractice();
            },
    );
  }

  void updateNameController({required String name}) {
    nameController.text = name;
  }

  Future<void> openDocumentationScreen() async {
    if (isLoading.value || isInitializing.value) return;

    await Get.toNamed('/help/documentation');
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

    await CustomDialogHelper.show(
      routeName: 'logout-dialog',

      title: TrKeys.common.logoutQuestion.tr,

      subtitle: TrKeys.common.logoutConfirm.tr,

      isDismissable: true,

      submitText: TrKeys.common.logout.tr,

      onSubmit: (_) async {
        await authService.signOut();
      },
    );
  }
}
