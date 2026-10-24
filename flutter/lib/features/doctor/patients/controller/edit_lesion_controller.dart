import 'dart:async';

import 'package:dermascan/core/models/body_lesion.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service/lesion_db_service.dart';
import 'package:dermascan/core/widgets/custom_dialog.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditLesionController extends GetxController {
  LesionDbService lesionDbService = Get.find<LesionDbService>();
  AuthService authService = Get.find<AuthService>();

  final TextEditingController locationNameController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final FocusNode notesFocusNode = FocusNode();
  final FocusNode locationNameFocusNode = FocusNode();

  RxBool isLoading = false.obs;
  RxBool isSuspicious = false.obs;
  RxBool wasRemoved = false.obs;

  late BodyLesion lesion;
  late final void Function({required BodyLesion lesion, required bool delete})?
  updateLesions;

  @override
  void onClose() {
    locationNameController.dispose();
    locationNameFocusNode.dispose();
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
    notesController.text = lesion.notes;
    isSuspicious.value = lesion.isSuspicious.value;
    wasRemoved.value = lesion.wasRemoved.value;
  }

  void submittedLocationName() {
    locationNameFocusNode.unfocus();
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
            title: TrKeys.common.missingInformation.tr,
            message: TrKeys.common.fillRequiredFields.tr,
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
            title: TrKeys.common.authenticationError.tr,
            message: TrKeys.common.authErrorReLogin.tr,
          ),
        );
      }
      return;
    }

    isLoading.value = true;

    try {
      final bool successful = await lesionDbService.updateLesion(
        lesionId: lesion.id,
        locationName: locationNameController.text.trim(),
        suspicious: isSuspicious.value,
        wasRemoved: wasRemoved.value,
        notes: notesController.text.trim(),
      );

      if (successful) {
        lesion.locationName = locationNameController.text.trim();
        lesion.isSuspicious.value = isSuspicious.value;
        lesion.wasRemoved.value = wasRemoved.value;
        lesion.notes = notesController.text.trim();

        updateLesions?.call(lesion: lesion, delete: false);
        Get.back();
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check,
              title: TrKeys.lesion.updatedLesion.tr,
              message: TrKeys.lesion.lesionUpdatedMsg.tr,
            ),
          );
        }
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: TrKeys.lesion.errorUpdatingLesion.tr,
              message: TrKeys.lesion.lesionUpdateFailedMsg.tr,
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
      title: TrKeys.lesion.deleteLesionQuestion.tr,
      subtitle: TrKeys.lesion.deleteLesionConfirmMsg.tr,
      isDismissable: true,
      submitText: TrKeys.common.delete.tr,
      onSubmit: (_) async {
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
            title: TrKeys.common.authenticationError.tr,
            message: TrKeys.common.authErrorReLogin.tr,
          ),
        );
      }
      return;
    }

    isLoading.value = true;

    try {
      final bool successDiagnosis = await lesionDbService.deleteLesion(
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
              title: TrKeys.lesion.lesionDeleted.tr,
              message: TrKeys.lesion.lesionDeletedMsg.tr,
            ),
          );
        }
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: TrKeys.lesion.errorDeletingLesion.tr,
              message: TrKeys.lesion.deletionFailedDiagnosesLinked.tr,
            ),
          );
        }
      }
    } finally {
      isLoading.value = false;
    }
  }
}
