import 'package:dermascan/core/services/auth_service.dart';

import 'package:dermascan/core/widgets/custom_dialog.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:dermascan/translations/tr_keys.dart';
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

    if (!emailsMatch.value) {
      if (!Get.isSnackbarOpen) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: TrKeys.auth.differentEmails.tr,
            message: TrKeys.auth.emailsDoNotMatchMsg.tr,
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
            title: TrKeys.common.authenticationError.tr,
            message: TrKeys.common.authErrorReLogin.tr,
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
              title: TrKeys.auth.changeFailed.tr,
              message:
                  TrKeys.auth.changeEmailFailedMsg
                      .tr,
            ),
          );
        }
      } else {
        Get.back(result: true);
        await CustomDialogHelper.show(
          routeName: 'confirm-email-dialog',

          title: TrKeys.auth.almostThere.tr,

          subtitle:
              TrKeys.auth.verifyEmailMsg
                  .tr,

          isDismissable: true,

          submitText: TrKeys.common.logout.tr,

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
