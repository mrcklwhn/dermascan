import 'dart:async';
import 'dart:convert';

import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service/practice_db_service.dart';
import 'package:dermascan/core/services/encryption_service.dart';
import 'package:dermascan/core/widgets/custom_dialog.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PracticeProfileController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  PracticeDbService practiceDbService = Get.find<PracticeDbService>();

  TextEditingController nameController = TextEditingController();

  FocusNode nameFocusNode = FocusNode();

  RxBool isLoading = false.obs;
  RxBool isInitializing = true.obs;

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_initializeData());
  }

  Future<void> _initializeData() async {
    try {
      await loadPracticeData();
      updateNameController(name: authService.currentPractice.value!.name);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error while loading practice data: $e');
      }
    } finally {
      isInitializing.value = false;
    }
  }

  Future<void> loadPracticeData() async {
    if (authService.currentPractice.value == null) return;

    final String? practiceId = authService.currentPractice.value?.id;

    if (practiceId == null) return;

    final Practice? fetchedPractice = await practiceDbService.fetchPractice(
      id: practiceId,
    );

    if (fetchedPractice == null) return;

    authService.currentPractice.value = fetchedPractice;
  }

  Future<void> submitName({required String newName}) async {
    if (isLoading.value || isInitializing.value) return;

    if (authService.currentPractice.value == null) {
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

    if (newName.trim() == authService.currentPractice.value!.name) {
      updateNameController(name: authService.currentPractice.value!.name);
      return;
    }

    if (newName.trim().isEmpty) {
      updateNameController(name: authService.currentPractice.value!.name);
      return;
    }

    isLoading.value = true;

    try {
      final Practice? fetchedPractice = await practiceDbService.changePracticeName(
        practiceId: authService.currentPractice.value!.id,
        newName: newName.trim(),
      );

      if (fetchedPractice != null) {
        authService.currentPractice.value = fetchedPractice;
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check_circle,
              title: TrKeys.doctor.updatedName.tr,
              message: TrKeys.doctor.nameChangedSuccess.tr,
            ),
          );
        }
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: TrKeys.doctor.updateNameFailed.tr,
              message:
                  TrKeys.auth.changeEmailFailedMsg
                      .tr,
            ),
          );
        }
      }
    } finally {
      updateNameController(name: authService.currentPractice.value!.name);
      isLoading.value = false;
    }
  }

  void updateNameController({required String name}) {
    nameController.text = name;
  }

  Future<void> openDocumentationScreen() async {
    if (isLoading.value || isInitializing.value) return;

    await Get.toNamed('/help/documentation');
  }

  Future<void> openChangeEmailScreen() async {
    if (isLoading.value || isInitializing.value) return;

    await Get.toNamed('/auth/change-mail');
  }

  Future<void> openChangePasswordScreen() async {
    if (isLoading.value || isInitializing.value) return;

    await Get.toNamed('/auth/change-password');
  }

  Future<void> openKeyExportDialog() async {
    final EncryptionService encryptionService = Get.find<EncryptionService>();
    final String? practiceId = authService.currentPractice.value?.id;
    final String? practiceKey = await encryptionService.getPracticeKey(practiceId: practiceId ?? '');

    if (practiceKey == null || practiceId == null) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: TrKeys.common.error.tr,
          message: TrKeys.practice.couldNotLoadPracticeKey.tr,
        ),
      );
      return;
    }

    final String qrData = jsonEncode(<String, String>{
      'practice_id': practiceId,
      'key': practiceKey,
    });

    await Get.dialog(
      Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                TrKeys.practice.exportEncryptionKey.tr,
                style: Get.textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Text(
                TrKeys.practice.showQrCodeDesc.tr,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceLarge),
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
              ),
              const SizedBox(height: AppTheme.spaceLarge),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: Text(TrKeys.common.close.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showLogoutDialog() async {
    if (isLoading.value || isInitializing.value) return;

    await CustomDialogHelper.show(
      routeName: 'logout-dialog',

      title: TrKeys.common.logoutQuestion.tr,

      subtitle: TrKeys.common.logoutConfirm.tr,

      isDismissable: true,

      submitText: TrKeys.common.logout.tr,

      onSubmit: (_) async {
        await authService.signOut();
      },
    );
  }
}
