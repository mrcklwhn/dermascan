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
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Information Missing',
          message: 'Please fill in all required fields to log in.',
        ),
      );
      return;
    }

    loginController.isLoading.value = true;

    try {
      final bool isPractice = await dbService.checkPracticeEmail(
        emailController.text,
      );

      if (!isPractice) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.block,
            title: 'Access Denied',
            message:
                'This account is not registered as a practice. Please use the doctor login instead.',
          ),
        );
        return;
      }

      final bool success = await authService.signIn(
        email: emailController.text,
        password: passwordController.text,
      );

      if (success) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.check_circle,
            title: 'Login Successful',
            message: 'Your Login was successful. You are now logged in.',
          ),
        );
        await authService.evaluateRouteAndNavigate();
      } else {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Login Failed',
            message:
                'Invalid email or password. Please check your credentials and try again.',
          ),
        );
      }
    } finally {
      loginController.isLoading.value = false;
    }
  }
}
