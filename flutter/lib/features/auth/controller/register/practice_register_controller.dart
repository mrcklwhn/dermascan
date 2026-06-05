import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:dermascan/features/auth/controller/register/register_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PracticeRegisterController extends GetxController {
  DBService dbService = Get.find<DBService>();
  AuthService authService = Get.find<AuthService>();

  RegisterController registerController;

  PracticeRegisterController(this.registerController);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final FocusNode nameFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode();

  RxBool hasMinLength = false.obs;
  RxBool hasUppercase = false.obs;
  RxBool hasLowercase = false.obs;
  RxBool hasDigits = false.obs;
  RxBool hasSpecialCharacters = false.obs;
  RxBool passwordsMatch = false.obs;
  RxBool isValidEmail = false.obs;

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    emailController.addListener(() {
      isValidEmail.value = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
      ).hasMatch(emailController.text);
    });
    passwordController.addListener(() {
      final String password = passwordController.text;
      hasMinLength.value = password.length >= 8;
      hasUppercase.value = password.contains(RegExp('[A-Z]'));
      hasLowercase.value = password.contains(RegExp('[a-z]'));
      hasDigits.value = password.contains(RegExp('[0-9]'));
      hasSpecialCharacters.value = password.contains(
        RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
      );
      passwordsMatch.value =
          passwordController.text == confirmPasswordController.text;
    });
    confirmPasswordController.addListener(() {
      passwordsMatch.value =
          passwordController.text == confirmPasswordController.text;
    });
  }

  void submittedName() {
    nameFocusNode.unfocus();
  }

  void submittedEmail() {
    passwordFocusNode.requestFocus();
  }

  void submittedPassword() {
    confirmPasswordFocusNode.requestFocus();
  }

  Future<void> submitRegisterData() async {
    if (registerController.isLoading.value) return;

    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty) {
      if (!Get.isSnackbarOpen) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Information Missing',
            message:
                'Please fill in all required fields to create your account.',
          ),
        );
      }
      return;
    }

    if (!isValidEmail.value) {
      if (!Get.isSnackbarOpen) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Invalid E-Mail',
            message: 'Your e-mail is not formatted correctly.',
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
            title: 'Password Insecure',
            message:
                'Your password does not meet the security requirements or the passwords do not match.',
          ),
        );
      }
      return;
    }

    registerController.isLoading.value = true;

    try {
      final bool successful = await authService.register(
        email: emailController.text.trimRight(),
        password: passwordController.text,
      );

      if (!successful) {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'Registration Failed',
              message:
                  'Could not create account. The email might already be in use or the connection failed.',
            ),
          );
        }
        return;
      }

      final bool profileCreated = await dbService.createPracticeProfile(
        name: nameController.text.trim(),
      );

      if (profileCreated) {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check_circle,
              title: 'Register Successful',
              message:
                  'Your Registration was successful. Yor account was created and you are now logged in.',
            ),
          );
        }
        await authService.evaluateRouteAndNavigate();
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'Profile Creation Error',
              message:
                  "Your account was created, but we couldn't set up the practice profile. Please contact support.",
            ),
          );
        }
      }
    } finally {
      registerController.isLoading.value = false;
    }
  }
}
