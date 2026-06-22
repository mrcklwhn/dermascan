import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:dermascan/features/auth/controller/login/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PracticeLoginController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  DBService dbService = Get.find<DBService>();

  LoginController loginController;

  PracticeLoginController(this.loginController);

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  FocusNode emailFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void submittedEmail() {
    passwordFocusNode.requestFocus();
  }

  Future<void> submitLoginData() async {
    if (loginController.isLoading.value) return;

    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
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

    loginController.isLoading.value = true;

    try {
      final bool isPractice = await dbService.checkPracticeEmail(
        emailController.text,
      );

      if (!isPractice) {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.block,
              title: 'Access Denied'.tr,
              message: 'Not a practice account. Please use doctor login.'.tr,
            ),
          );
        }
        return;
      }

      final bool success = await authService.signIn(
        email: emailController.text,
        password: passwordController.text,
      );

      if (success) {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check_circle,
              title: 'Login Successful'.tr,
              message: 'You are now logged in.'.tr,
            ),
          );
        }
        await authService.evaluateRouteAndNavigate();
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'Login Failed'.tr,
              message: 'Invalid email or password. Please try again.'.tr,
            ),
          );
        }
      }
    } finally {
      loginController.isLoading.value = false;
    }
  }
}
