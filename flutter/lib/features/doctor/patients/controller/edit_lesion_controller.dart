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

  final FocusNode locationNameFocusNode = FocusNode();

  RxBool isLoading = false.obs;

  RxBool isSuspicious = false.obs;

  late BodyLesion lesion;
  late final void Function({required BodyLesion lesion, required bool delete})?
  updateLesions;

  @override
  void onClose() {
    scrollController.dispose();
    locationNameController.dispose();
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

    if (lesion.locationName != null) {
      locationNameController.text = lesion.locationName!;
    }

    isSuspicious.value = lesion.isSuspicious.value;
  }

  void submittedLocationName() {
    locationNameFocusNode.unfocus();
  }

  Future<void> updateLesion() async {
    if (isLoading.value) return;

    if (locationNameController.text.trim().isEmpty) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Missing Information',
          message: 'Please fill in all required fields to update a lesion.',
        ),
      );
      return;
    }

    final String? doctorId = authService.currentUser.value?.id;

    if (doctorId == null) {
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
      final bool successful = await dbService.updateLesion(
        lesionId: lesion.id,
        locationName: locationNameController.text.trim(),
        suspicious: isSuspicious.value,
      );

      if (successful) {
        lesion.locationName = locationNameController.text.trim();
        lesion.isSuspicious.value = isSuspicious.value;

        updateLesions?.call(lesion: lesion, delete: false);
        Get.back();

        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.check,
            title: 'Updated Lesion',
            message: isSuspicious.value
                ? 'The Lesion has been marked as suspicious.'
                : 'The Lesion has been marked as not suspicious.',
          ),
        );
      } else {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Error Updating Lesion',
            message: 'The Lesion could not be updated.',
          ),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> showDeleteLesionDialog() async {
    if (isLoading.value) return;

    await CustomDialogHelper.show(
      routeName: 'delete-lesion-dialog',

      title: 'Delete Lesion?',

      subtitle:
          'You are about to delete this lesion. '
          'All associated diagnoses must be deleted first.',

      isDismissable: true,

      submitText: 'Delete',

      onSubmit: isLoading.value
          ? null
          : () async {
              await deleteLesion(lesion: lesion);
            },
    );
  }

  Future<void> deleteLesion({required BodyLesion lesion}) async {
    if (isLoading.value) return;

    if (authService.currentDoctor.value == null) return;

    final String? doctorId = authService.currentUser.value?.id;

    if (doctorId == null) {
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

        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.check,
            title: 'Lesion Deleted',
            message: 'The Lesion has been deleted.',
          ),
        );
      } else {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Error Deleting Lesion',
            message:
                'The lesion could not be deleted. There may be diagnoses linked to it.',
          ),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}
