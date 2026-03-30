import 'dart:async';

import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/widgets/custom_dialog.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorDetailsController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  DBService dbService = Get.find<DBService>();

  ScrollController scrollController = ScrollController();

  RxBool isLoading = false.obs;
  RxBool isInitializing = true.obs;
  RxBool invitationSent = false.obs;
  RxBool isAssignedToCurrentPractice = false.obs;

  late Doctor doctor;
  late bool invitationAlreadySentOnInit;
  late void Function({required String doctorId})? removeFromList;
  late void Function({required Doctor doctor})? addToList;

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  void _initializeData() {
    try {
      loadValuesFromRoute();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error while loading doctor data from route: $e');
      }
    } finally {
      isInitializing.value = false;
    }
  }

  void loadValuesFromRoute() {
    final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;
    doctor = args['doctor'];
    removeFromList = args['removeFromList'];
    addToList = args['addToList'];
    invitationSent.value = args['invitationSent'];
    invitationAlreadySentOnInit = args['invitationSent'];
    isAssignedToCurrentPractice.value = args['assignedToCurrentPractice'];
  }

  Future<void> inviteDoctorToCurrentPractice() async {
    if (isLoading.value || isInitializing.value || invitationSent.value) return;

    final String? practiceId = authService.currentUser.value?.id;

    if (practiceId == null) {
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
      final bool success = await dbService.inviteDoctorToPractice(
        practiceId: practiceId,
        doctorId: doctor.id,
      );

      if (Get.isDialogOpen ?? false) Get.back();

      if (success) {
        if (invitationAlreadySentOnInit) {
          addToList?.call(doctor: doctor);
        } else {
          removeFromList?.call(doctorId: doctor.id);
        }
        invitationSent.value = true;
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.check,
            title: 'Invitation Sent',
            message: "An invitation has been sent to '${doctor.name}'!",
          ),
        );
      } else {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Invitation Sent Error',
            message:
                "An error occurred while inviting '${doctor.name}' to your practice. They may already have been invited.",
          ),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> showInviteDialog() async {
    if (isLoading.value || isInitializing.value || invitationSent.value) return;

    await Get.dialog(
      Obx(
        () => CustomDialog(
          title: 'Invite Doctor?',
          subtitle:
              "You are about to invite '${doctor.name}' to your practice. This allows access to all the practice data.",
          isDismissable: true,
          onSubmit:
              isLoading.value || isInitializing.value || invitationSent.value
              ? null
              : () async => await inviteDoctorToCurrentPractice(),
          submitText: 'Invite',
        ),
      ),
    );
  }

  Future<void> revokeInvitationOfCurrentPractice() async {
    if (isLoading.value || isInitializing.value || !invitationSent.value) {
      return;
    }

    final String? practiceId = authService.currentUser.value?.id;

    if (practiceId == null) {
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
      final bool success = await dbService.revokePracticeInvitation(
        practiceId: practiceId,
        doctorId: doctor.id,
      );

      if (Get.isDialogOpen ?? false) Get.back();

      if (success) {
        if (invitationAlreadySentOnInit) {
          removeFromList?.call(doctorId: doctor.id);
        } else {
          addToList?.call(doctor: doctor);
        }
        invitationSent.value = false;
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.check,
            title: 'Invitation Revoked',
            message:
                "The invitation for '${doctor.name}' has been successfully revoked!",
          ),
        );
      } else {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Revoking Invitation Failed',
            message:
                "An error occurred while revoking the invitation for '${doctor.name}'. It may have already been revoked.",
          ),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> showRevokeDialog() async {
    if (isLoading.value || isInitializing.value || !invitationSent.value) {
      return;
    }

    await Get.dialog(
      Obx(
        () => CustomDialog(
          title: 'Revoke Invitation?',
          subtitle:
              "You are about to revoke your invitation for '${doctor.name}'.",
          isDismissable: true,
          onSubmit:
              isLoading.value || isInitializing.value || !invitationSent.value
              ? null
              : () async => await revokeInvitationOfCurrentPractice(),
          submitText: 'Revoke',
        ),
      ),
    );
  }

  Future<void> removeDoctorFromCurrentPractice() async {
    if (isLoading.value ||
        isInitializing.value ||
        !isAssignedToCurrentPractice.value) {
      return;
    }

    final String? practiceId = authService.currentUser.value?.id;

    if (practiceId == null) {
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
      final bool success = await dbService.leaveCurrentPractice(
        doctorId: doctor.id,
      );

      if (Get.isDialogOpen ?? false) Get.back();

      if (success) {
        removeFromList?.call(doctorId: doctor.id);
        isAssignedToCurrentPractice.value = false;
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.check,
            title: 'Removed Doctor',
            message:
                "'${doctor.name}' has been successfully removed from your practice!",
          ),
        );
      } else {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Removing Doctor Failed',
            message:
                "An error occurred while removing '${doctor.name}' from your practice. They may have already been removed.",
          ),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> showRemoveDialog() async {
    if (isLoading.value ||
        isInitializing.value ||
        !isAssignedToCurrentPractice.value) {
      return;
    }

    await Get.dialog(
      Obx(
        () => CustomDialog(
          title: 'Remove Doctor?',
          subtitle:
              "You are about to remove '${doctor.name}' from your practice. This removes access to any shared data with it. Do you want to continue?",
          isDismissable: true,
          onSubmit:
              isLoading.value ||
                  isInitializing.value ||
                  !isAssignedToCurrentPractice.value
              ? null
              : () async => await removeDoctorFromCurrentPractice(),
          submitText: 'Remove',
        ),
      ),
    );
  }
}
