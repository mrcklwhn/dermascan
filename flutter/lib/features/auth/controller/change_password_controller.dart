import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordController extends GetxController {
  DBService dbService = Get.find<DBService>();
  AuthService authService = Get.find<AuthService>();

  ScrollController scrollController = ScrollController();

  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmNewPasswordController = TextEditingController();

  FocusNode newPasswordFocusNode = FocusNode();
  FocusNode confirmNewPasswordFocusNode = FocusNode();

  RxBool isLoading = false.obs;
  RxBool hasMinLength = false.obs;
  RxBool hasUppercase = false.obs;
  RxBool hasLowercase = false.obs;
  RxBool hasDigits = false.obs;
  RxBool hasSpecialCharacters = false.obs;
  RxBool passwordsMatch = false.obs;

  @override
  void onClose() {
    scrollController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    newPasswordController.addListener(() {
      final String newPassword = newPasswordController.text;
      final String confirmNewPassword = confirmNewPasswordController.text;
      hasMinLength.value = newPassword.length >= 8;
      hasUppercase.value = newPassword.contains(RegExp('[A-Z]'));
      hasLowercase.value = newPassword.contains(RegExp('[a-z]'));
      hasDigits.value = newPassword.contains(RegExp('[0-9]'));
      hasSpecialCharacters.value = newPassword.contains(
        RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
      );
      passwordsMatch.value = newPassword == confirmNewPassword;
    });
    confirmNewPasswordController.addListener(() {
      final String newPassword = newPasswordController.text;
      final String confirmNewPassword = confirmNewPasswordController.text;
      passwordsMatch.value = newPassword == confirmNewPassword;
    });
  }

  void submitNewPassword() {
    confirmNewPasswordFocusNode.requestFocus();
  }

  Future<void> submitChangedPassword() async {
    if (isLoading.value) return;

    if (newPasswordController.text.trim().isEmpty ||
        confirmNewPasswordController.text.trim().isEmpty) {
      if (!Get.isSnackbarOpen) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Missing Information'.tr,
            message: 'Please fill in all required fields.'.tr,
          ),
        );
      }
      return;
    }

    if (!(hasMinLength.value &&
        hasUppercase.value &&
        hasLowercase.value &&
        hasDigits.value &&
        hasSpecialCharacters.value &&
        passwordsMatch.value)) {
      if (!Get.isSnackbarOpen) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Password Insecure'.tr,
            message: 'Passwords must match and meet security requirements.'.tr,
          ),
        );
      }
      return;
    }

    if (authService.currentUser.value == null) {
      if (!Get.isSnackbarOpen) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Authentication Error'.tr,
            message: 'Authentication error. Please log in again.'.tr,
          ),
        );
      }
      return;
    }

    isLoading.value = true;

    try {
      final UserResponse? response = await authService.changePassword(
        newPassword: newPasswordController.text,
      );

      if (response?.user == null) {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'Change Failed'.tr,
              message:
                  'Could not change Password. Maybe the connection failed.'.tr,
            ),
          );
        }
      } else {
        Get.back(result: true);
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check,
              title: 'Password Changed'.tr,
              message: 'Password changed successfully.'.tr,
            ),
          );
        }
        await authService.signOut();
      }
    } finally {
      isLoading.value = false;
    }
  }
}
