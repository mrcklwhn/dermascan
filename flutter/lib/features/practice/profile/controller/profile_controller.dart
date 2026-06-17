import 'dart:async';

import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/widgets/custom_dialog.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PracticeProfileController extends GetxController {
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
      await loadPracticeData();
      updateNameController(name: authService.currentPractice.value!.name);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error while loading practice data: $e');
      }
    } finally {
      isInitializing.value = false;
    }
  }

  Future<void> loadPracticeData() async {
    if (authService.currentPractice.value == null) return;

    final String? practiceId = authService.currentPractice.value?.id;

    if (practiceId == null) return;

    final Practice? fetchedPractice = await dbService.fetchPractice(
      id: practiceId,
    );

    if (fetchedPractice == null) return;

    authService.currentPractice.value = fetchedPractice;
  }

  Future<void> submitName({required String newName}) async {
    if (isLoading.value || isInitializing.value) return;

    if (authService.currentPractice.value == null) {
      if (!Get.isSnackbarOpen) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Authentication Error'.tr,
            message: 'You are not signed in correctly. Please log in again.'.tr,
          ),
        );
      }
      return;
    }

    if (newName.trim() == authService.currentPractice.value!.name) {
      updateNameController(name: authService.currentPractice.value!.name);
      return;
    }

    if (newName.trim().isEmpty) {
      updateNameController(name: authService.currentPractice.value!.name);
      return;
    }

    isLoading.value = true;

    try {
      final Practice? fetchedPractice = await dbService.changePracticeName(
        newName: newName.trim(),
      );

      if (fetchedPractice != null) {
        authService.currentPractice.value = fetchedPractice;
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check_circle,
              title: 'Updated Name'.tr,
              message:
                  "${'Your name was successfully changed to'.tr} '${newName.trim()}'.",
            ),
          );
        }
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'Update Name Failed'.tr,
              message:
                  'Your name could not be changed. Please check the data or try again later.'
                      .tr,
            ),
          );
        }
      }
    } finally {
      updateNameController(name: authService.currentPractice.value!.name);
      isLoading.value = false;
    }
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

    await CustomDialogHelper.show(
      routeName: 'logout-dialog',

      title: 'Logout?'.tr,

      subtitle:
          'You are about to log out of your account. Are you sure you want to proceed?'
              .tr,

      isDismissable: true,

      submitText: 'Logout'.tr,

      onSubmit: (_) async {
        await authService.signOut();
      },
    );
  }
}
