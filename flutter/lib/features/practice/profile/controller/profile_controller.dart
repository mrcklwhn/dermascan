import 'dart:async';
import 'dart:convert';

import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service/practice_db_service.dart';
import 'package:dermascan/core/services/encryption_service.dart';
import 'package:dermascan/core/widgets/custom_dialog.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
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
            title: 'Authentication Error'.tr,
            message: 'Authentication error. Please log in again.'.tr,
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
              title: 'Updated Name'.tr,
              message: 'Your name was successfully changed.'.tr,
            ),
          );
        }
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'Update Name Failed'.tr,
              message:
                  'Name update failed. Please verify your data and try again.'
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
          title: 'Error'.tr,
          message: 'Could not load practice key.'.tr,
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
                'Export Practice Key'.tr,
                style: Get.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Show this QR code to new doctors to allow them to decrypt patient data.'.tr,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: Text('Close'.tr),
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

      title: 'Logout?'.tr,

      subtitle: 'Are you sure you want to log out?'.tr,

      isDismissable: true,

      submitText: 'Logout'.tr,

      onSubmit: (_) async {
        await authService.signOut();
      },
    );
  }
}
