import 'dart:async';

import 'package:dermascan/core/models/body_lesion.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/widgets/custom_dialog.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditLesionController extends GetxController {
  DBService dbService = Get.find<DBService>();
  AuthService authService = Get.find<AuthService>();

  ScrollController scrollController = ScrollController();

  final TextEditingController locationNameController = TextEditingController();
  final TextEditingController testResultController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final FocusNode notesFocusNode = FocusNode();
  final FocusNode locationNameFocusNode = FocusNode();
  final FocusNode testResultFocusNode = FocusNode();

  RxBool isLoading = false.obs;
  RxBool isSuspicious = false.obs;
  RxBool wasRemoved = false.obs;

  late BodyLesion lesion;
  late final void Function({required BodyLesion lesion, required bool delete})?
  updateLesions;

  @override
  void onClose() {
    scrollController.dispose();
    locationNameController.dispose();
    testResultController.dispose();
    locationNameFocusNode.dispose();
    testResultFocusNode.dispose();
    notesController.dispose();
    notesFocusNode.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    loadValuesFromRoute();
  }

  void loadValuesFromRoute() {
    final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;
    lesion = args['lesion'];
    updateLesions = args['updateLesions'];
    locationNameController.text = lesion.locationName;
    testResultController.text = lesion.testResult;
    notesController.text = lesion.notes;
    isSuspicious.value = lesion.isSuspicious.value;
    wasRemoved.value = lesion.wasRemoved.value;
  }

  void submittedLocationName() {
    locationNameFocusNode.unfocus();
  }

  void submittedTestResult() {
    testResultFocusNode.unfocus();
  }

  void submittedNotes() {
    notesFocusNode.unfocus();
  }

  Future<void> updateLesion() async {
    if (isLoading.value) return;

    if (locationNameController.text.trim().isEmpty) {
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

    final String? doctorId = authService.currentUser.value?.id;

    if (doctorId == null) {
      if (!Get.isSnackbarOpen) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Authentication Error'.tr,
            message: 'You are not signed in correctly. Please log in again.'.tr,
          ),
        );
      }
      return;
    }

    isLoading.value = true;

    try {
      final bool successful = await dbService.updateLesion(
        lesionId: lesion.id,
        locationName: locationNameController.text.trim(),
        suspicious: isSuspicious.value,
        wasRemoved: wasRemoved.value,
        testResult: testResultController.text.trim(),
        notes: notesController.text.trim(),
      );

      if (successful) {
        lesion.locationName = locationNameController.text.trim();
        lesion.isSuspicious.value = isSuspicious.value;
        lesion.wasRemoved.value = wasRemoved.value;
        lesion.testResult = testResultController.text.trim();
        lesion.notes = notesController.text.trim();

        updateLesions?.call(lesion: lesion, delete: false);
        Get.back();
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check,
              title: 'Updated Lesion'.tr,
              message: 'The Lesion has been successfully updated.'.tr,
            ),
          );
        }
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'Error Updating Lesion'.tr,
              message: 'The Lesion could not be updated.'.tr,
            ),
          );
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> showDeleteLesionDialog() async {
    if (isLoading.value) return;

    await CustomDialogHelper.show(
      routeName: 'delete-lesion-dialog',
      title: 'Delete Lesion?'.tr,
      subtitle:
          'You are about to delete this lesion. All associated diagnoses must be deleted first.'
              .tr,
      isDismissable: true,
      submitText: 'Delete'.tr,
      onSubmit: isLoading.value
          ? null
          : (_) async {
              await deleteLesion(lesion: lesion);
            },
    );
  }

  Future<void> deleteLesion({required BodyLesion lesion}) async {
    if (isLoading.value) return;

    if (authService.currentDoctor.value == null) return;

    final String? doctorId = authService.currentUser.value?.id;

    if (doctorId == null) {
      if (!Get.isSnackbarOpen) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Authentication Error'.tr,
            message: 'You are not signed in correctly. Please log in again.'.tr,
          ),
        );
      }
      return;
    }

    isLoading.value = true;

    try {
      final bool successDiagnosis = await dbService.deleteLesion(
        lesionId: lesion.id,
      );

      if (successDiagnosis) {
        updateLesions?.call(lesion: lesion, delete: true);

        // Close Edit-Lesion-Page AND diagnosis-bottom-sheet
        final BuildContext? context = Get.context;
        if (context != null && context.mounted) {
          Navigator.of(context).popUntil((Route<dynamic> route) {
            final String? name = route.settings.name;
            if (name == '/doctor/edit-lesion' || // Current Page
                name == 'diagnosis-bottom-sheet') {
              return false;
            }
            return true;
          });
        }
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check,
              title: 'Lesion Deleted'.tr,
              message: 'The Lesion has been deleted.'.tr,
            ),
          );
        }
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'Error Deleting Lesion'.tr,
              message:
                  'The lesion could not be deleted. There may be diagnoses linked to it.'
                      .tr,
            ),
          );
        }
      }
    } finally {
      isLoading.value = false;
    }
  }
}
