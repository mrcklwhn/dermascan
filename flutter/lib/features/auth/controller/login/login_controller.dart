import 'package:dermascan/core/enums.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final AuthService authService = Get.find<AuthService>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  Rx<AuthOption> currentSelectedAuthOption = AuthOption.doctor.obs;
  RxBool isLoading = false.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.onClose();
  }

  void submittedEmail() {
    passwordFocusNode.requestFocus();
  }

  Future<void> submitLoginData() async {
    if (isLoading.value) return;

    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      if (!Get.isSnackbarOpen) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: TrKeys.common.missingInformation.tr,
            message: TrKeys.common.fillRequiredFields.tr,
          ),
        );
      }
      return;
    }

    isLoading.value = true;

    try {
      final bool success = await authService.signIn(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (success) {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check_circle,
              title: TrKeys.auth.loginSuccess.tr,
              message: TrKeys.auth.loggedInMsg.tr,
            ),
          );
        }
        await authService.evaluateRouteAndNavigate();
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: TrKeys.auth.loginFailed.tr,
              message: TrKeys.auth.invalidCredentialsMsg.tr,
            ),
          );
        }
      }
    } finally {
      isLoading.value = false;
    }
  }
}
