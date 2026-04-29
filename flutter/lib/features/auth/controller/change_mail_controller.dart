import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/widgets/custom_dialog.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangeEmailController extends GetxController {
  DBService dbService = Get.find<DBService>();
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
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Information Missing',
          message: 'Please fill in all required fields to change your E-Mail.',
        ),
      );
      return;
    }

    if (!isValidEmail.value) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Invalid E-Mail',
          message: 'Your e-mail is not formatted correctly.',
        ),
      );
      return;
    }

    if (!emailsMatch.value) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Different E-Mails',
          message: "Your e-mails don't match. Please check and try again.",
        ),
      );
      return;
    }

    if (authService.currentUser.value == null) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Authentication Error',
          message: 'You are not signed in correctly. Please log in again.',
        ),
      );
      return;
    }

    isLoading.value = true;

    try {
      final UserResponse? response = await authService.changeEmail(
        newEmail: newEmailController.text.trimRight(),
      );

      if (response?.user == null) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Change Failed',
            message:
                'Could not change E-Mail. The email might already be in use or the connection failed.',
          ),
        );
      } else {
        Get.back(result: true);
        await Get.dialog(
          CustomDialog(
            title: 'Almost there!',
            subtitle:
                'We have sent a confirmation link to your new email address. It is highly recommended to log out now, click the link in your email, and then log back in with your new credentials.',
            isDismissable: true,
            onSubmit: () => authService.signOut(),
            submitText: 'Logout',
          ),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}
