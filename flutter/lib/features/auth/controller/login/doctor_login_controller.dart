import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:dermascan/features/auth/controller/login/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorLoginController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  DBService dbService = Get.find<DBService>();

  LoginController loginController;

  DoctorLoginController(this.loginController);

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
            title: 'Information Missing',
            message: 'Please fill in all required fields to log in.',
          ),
        );
      }
      return;
    }

    loginController.isLoading.value = true;

    try {
      final bool isDoctor = await dbService.checkDoctorEmail(
        emailController.text,
      );

      if (!isDoctor) {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.block,
              title: 'Access Denied',
              message:
                  'This account is not registered as a doctor. Please use the practice login instead.',
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
              title: 'Login Successful',
              message: 'Your Login was successful. You are now logged in.',
            ),
          );
        }
        await authService.evaluateRouteAndNavigate();
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'Login Failed',
              message:
                  'Invalid email or password. Please check your credentials and try again.',
            ),
          );
        }
      }
    } finally {
      loginController.isLoading.value = false;
    }
  }
}
