import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service/practice_db_service.dart';
import 'package:dermascan/core/services/encryption_service.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:dermascan/features/auth/controller/register/register_controller.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PracticeRegisterController extends GetxController {
  PracticeDbService practiceDbService = Get.find<PracticeDbService>();
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
    emailFocusNode.requestFocus();
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
            title: TrKeys.common.missingInformation.tr,
            message: TrKeys.common.fillRequiredFields.tr,
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
            title: TrKeys.auth.invalidEmail.tr,
            message: TrKeys.auth.emailFormatErrorMsg.tr,
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
            title: TrKeys.auth.passwordInsecure.tr,
            message: TrKeys.auth.passwordsRequirementsMsg.tr,
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
              title: TrKeys.auth.registrationFailed.tr,
              message:
                  TrKeys.auth.regFailedMsg
                      .tr,
            ),
          );
        }
        return;
      }

      // Generate E2EE key for the new practice
      final EncryptionService encryptionService = Get.find<EncryptionService>();
      final String practiceKey = encryptionService.generateKey();
      
      // Generate keyVerifier using EncryptionService
      final String keyVerifier = encryptionService.generateKeyVerifier(base64Key: practiceKey);

      final bool profileCreated = await practiceDbService.createPracticeProfile(
        name: nameController.text.trim(),
        keyVerifier: keyVerifier,
      );

      if (profileCreated) {
        // Save the key locally
        final User? user = authService.supabaseClient.auth.currentUser;
        if (user != null) {
          await encryptionService.savePracticeKey(practiceId: user.id, base64Key: practiceKey);
        }

        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check_circle,
              title: TrKeys.auth.registrationSuccessful.tr,
              message: TrKeys.auth.accountCreatedMsg.tr,
            ),
          );
        }
        await authService.evaluateRouteAndNavigate();
      } else {
        await authService.supabaseClient.rpc('delete_account_without_profile');
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: TrKeys.auth.profileCreationError.tr,
              message: TrKeys.auth.profileSetupErrorMsg.tr,
            ),
          );
        }
      }
    } finally {
      registerController.isLoading.value = false;
    }
  }
}
