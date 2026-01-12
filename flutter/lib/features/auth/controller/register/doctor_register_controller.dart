import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:dermascan/features/auth/controller/register/register_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorRegisterController extends GetxController {
  RegisterController registerController;

  DoctorRegisterController(this.registerController);

  AuthService authService = Get.find<AuthService>();

  DBService dbService = Get.find<DBService>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  Rx<bool> passwordIsObscure = true.obs;
  Rx<String> selectedGender = ''.obs;
  final List<String> genderOptions = <String>['Male', 'Female'];

  Rx<bool> hasMinLength = false.obs;
  Rx<bool> hasUppercase = false.obs;
  Rx<bool> hasLowercase = false.obs;
  Rx<bool> hasDigits = false.obs;
  Rx<bool> hasSpecialCharacters = false.obs;
  Rx<bool> passwordsMatch = false.obs;

  DateTime? dateOfBirth;

  @override
  void onInit() {
    super.onInit();
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

  void changePasswordObscurity() {
    passwordIsObscure.value = !passwordIsObscure.value;
  }

  Future<void> selectDate(BuildContext context) async {
    dateOfBirth = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (dateOfBirth != null) {
      birthdayController.text =
          '${dateOfBirth?.day}.${dateOfBirth?.month}.${dateOfBirth?.year}';
    }
  }

  Future<void> submitRegisterData() async {
    if (!(hasMinLength.value &&
        hasUppercase.value &&
        hasLowercase.value &&
        hasDigits.value &&
        hasSpecialCharacters.value &&
        passwordsMatch.value)) {
      return;
    }

    registerController.isLoading.value = true;

    final bool successful = await authService.register(
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    if (!successful) {
      registerController.isLoading.value = false;
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Registration failed!',
          message: 'Please check your data and try again!',
        ),
      );
      return;
    }

    final bool profileCreated = await dbService.createDoctorProfile(
      name: nameController.text.trim(),
      gender: selectedGender.value[0],
      dateOfBirth: dateOfBirth,
    );

    registerController.isLoading.value = false;

    if (profileCreated) {
      await Get.offAllNamed('/doctor/home');
    } else {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Registration failed!',
          message: 'Please check your data and try again later!',
        ),
      );
    }
  }
}
