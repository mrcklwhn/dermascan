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

  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  Rx<bool> passwordIsObscure = true.obs;

  void changePasswordObscurity() {
    passwordIsObscure.value = !passwordIsObscure.value;
  }

  Future<void> submitLoginData() async {
    if (loginController.isLoading.value) {
      return;
    }

    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      return;
    }

    loginController.isLoading.value = true;

    final bool isDoctor = await dbService.checkDoctorEmail(
      emailController.text.trim(),
    );

    if (!isDoctor) {
      loginController.isLoading.value = false;
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.block,
          title: 'Access denied',
          message: 'This e-mail is not assigned to a doctor account.',
        ),
      );
      return;
    }

    final bool success = await authService.signIn(
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    if (success) {
      await authService.evaluateRouteAndNavigate();
    } else {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Login failed!',
          message: 'Please check your access data and try again!',
        ),
      );
    }

    loginController.isLoading.value = false;
  }
}
