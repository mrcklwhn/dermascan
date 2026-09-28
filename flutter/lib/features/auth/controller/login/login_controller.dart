import 'package:dermascan/app/enums.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  ScrollController scrollController = ScrollController();

  Rx<AuthOption> currentSelectedAuthOption = AuthOption.doctor.obs;

  RxBool isLoading = false.obs;

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void changeCurrentSelectedAuthOption({required AuthOption newAuthOption}) {
    if (currentSelectedAuthOption.value != newAuthOption) {
      currentSelectedAuthOption.value = newAuthOption;
    }
  }

  Future<void> navigateToRegister() async {
    if (isLoading.value) return;

    await Get.toNamed('/auth/register');
  }

  AuthService authService = Get.find<AuthService>();
  DBService dbService = Get.find<DBService>();


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
    if (isLoading.value) return;

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

    isLoading.value = true;

    try {
     

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
      isLoading.value = false;
    }
  }
}
