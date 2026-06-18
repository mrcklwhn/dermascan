import 'package:dermascan/app/enums.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:dermascan/features/auth/controller/register/register_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DoctorRegisterController extends GetxController {
  DBService dbService = Get.find<DBService>();
  AuthService authService = Get.find<AuthService>();

  RegisterController registerController;

  DoctorRegisterController(this.registerController);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
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

  DateTime? dateOfBirth;

  Gender? selectedGender;

  List<Gender> get genderOptions => Gender.values;

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    birthdayController.dispose();
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

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != dateOfBirth) {
      dateOfBirth = picked;
      birthdayController.text = DateFormat('dd.MM.yyyy').format(picked);
    }
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

    if (selectedGender == null ||
        nameController.text.trim().isEmpty ||
        dateOfBirth == null ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty) {
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

    if (!isValidEmail.value) {
      if (!Get.isSnackbarOpen) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Invalid E-Mail'.tr,
            message: 'Your e-mail is not formatted correctly.'.tr,
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
              title: 'Registration Failed'.tr,
              message:
                  'Account creation failed. Email may be in use or connection lost.'
                      .tr,
            ),
          );
        }
        return;
      }

      final bool profileCreated = await dbService.createDoctorProfile(
        name: nameController.text.trim(),
        gender: selectedGender!.name,
        dateOfBirth: dateOfBirth,
      );

      if (profileCreated) {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check_circle,
              title: 'Registration Successful'.tr,
              message:
                  'Your account was created and you are now logged in.'.tr,
            ),
          );
        }
        await authService.evaluateRouteAndNavigate();
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'Profile Creation Error'.tr,
              message: 'Account created, but practice setup failed.'.tr,
            ),
          );
        }
      }
    } finally {
      registerController.isLoading.value = false;
    }
  }
}
