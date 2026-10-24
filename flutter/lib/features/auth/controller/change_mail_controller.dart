import 'package:dermascan/core/services/auth_service.dart';

import 'package:dermascan/core/widgets/custom_dialog.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangeEmailController extends GetxController {

  AuthService authService = Get.find<AuthService>();

  ScrollController scrollController = ScrollController();

  TextEditingController newEmailController = TextEditingController();
  TextEditingController confirmNewEmailController = TextEditingController();

  FocusNode newEmailFocusNode = FocusNode();
  FocusNode confirmNewEmailFocusNode = FocusNode();

  RxBool isLoading = false.obs;
  RxBool isValidEmail = false.obs;
  RxBool emailsMatch = false.obs;

  @override
  void onClose() {
    scrollController.dispose();
    newEmailController.dispose();
    confirmNewEmailController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    newEmailController.addListener(() {
      final String newEmail = newEmailController.text;
      final String confirmNewEmail = confirmNewEmailController.text;
      isValidEmail.value = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
      ).hasMatch(newEmail);
      emailsMatch.value = newEmail == confirmNewEmail;
    });
    confirmNewEmailController.addListener(() {
      final String newMail = newEmailController.text;
      final String confirmNewMail = confirmNewEmailController.text;
      emailsMatch.value = newMail == confirmNewMail;
    });
  }

  void submitNewPassword() {
    confirmNewEmailFocusNode.requestFocus();
  }

  Future<void> submitChangedEmail() async {
    if (isLoading.value) return;

    if (newEmailController.text.trim().isEmpty ||
        confirmNewEmailController.text.trim().isEmpty) {
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

    if (!emailsMatch.value) {
      if (!Get.isSnackbarOpen) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Different E-Mails'.tr,
            message: 'E-mails do not match. Please check and try again.'.tr,
          ),
        );
      }
      return;
    }

    if (authService.currentUser.value == null) {
      if (!Get.isSnackbarOpen) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Authentication Error'.tr,
            message: 'Authentication error. Please log in again.'.tr,
          ),
        );
      }
      return;
    }

    isLoading.value = true;

    try {
      final UserResponse? response = await authService.changeEmail(
        newEmail: newEmailController.text.trimRight(),
      );

      if (response?.user == null) {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'Change Failed'.tr,
              message:
                  'Could not change E-Mail. The email might already be in use or the connection failed.'
                      .tr,
            ),
          );
        }
      } else {
        Get.back(result: true);
        await CustomDialogHelper.show(
          routeName: 'confirm-email-dialog',

          title: 'Almost there!'.tr,

          subtitle:
              'Confirmation link sent. Please log out, verify your new email, and log back in.'
                  .tr,

          isDismissable: true,

          submitText: 'Logout',

          onSubmit: (_) async {
            await authService.signOut();
          },
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}
