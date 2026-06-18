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
      final bool success = await dbService.inviteDoctorToPractice(
        practiceId: practiceId,
        doctorId: doctor.id,
      );

      if (success) {
        if (invitationAlreadySentOnInit) {
          addToList?.call(doctor: doctor);
        } else {
          removeFromList?.call(doctorId: doctor.id);
        }
        invitationSent.value = true;
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check,
              title: 'Invitation Sent'.tr,
              message: 'An invitation has been sent.'.tr,
            ),
          );
        }
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'Invitation Sent Error'.tr,
              message:
                  'An error occurred. They may already have been invited.'.tr,
            ),
          );
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> showInviteDialog() async {
    if (isLoading.value || isInitializing.value || invitationSent.value) return;

    await CustomDialogHelper.show(
      routeName: 'invite-doctor-dialog',

      title: 'Invite Doctor?'.tr,

      subtitle: 'Invited members will gain full access to practice data.'.tr,

      isDismissable: true,

      submitText: 'Invite'.tr,

      onSubmit: isLoading.value || isInitializing.value || invitationSent.value
          ? null
          : (_) async {
              await inviteDoctorToCurrentPractice();
            },
    );
  }

  Future<void> revokeInvitationOfCurrentPractice() async {
    if (isLoading.value || isInitializing.value || !invitationSent.value) {
      return;
    }

    final String? practiceId = authService.currentUser.value?.id;

    if (practiceId == null) {
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
      final bool success = await dbService.revokePracticeInvitation(
        practiceId: practiceId,
        doctorId: doctor.id,
      );

      if (success) {
        if (invitationAlreadySentOnInit) {
          removeFromList?.call(doctorId: doctor.id);
        } else {
          addToList?.call(doctor: doctor);
        }
        invitationSent.value = false;
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check,
              title: 'Invitation Revoked'.tr,
              message: 'The invitation has been successfully revoked!'.tr,
            ),
          );
        }
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'Revoking Invitation Failed'.tr,
              message:
                  'Revocation failed. The invitation may already be revoked.'
                      .tr,
            ),
          );
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> showRevokeDialog() async {
    if (isLoading.value || isInitializing.value || !invitationSent.value) {
      return;
    }

    await CustomDialogHelper.show(
      routeName: 'revoke-invitation-dialog',

      title: 'Revoke Invitation?'.tr,

      subtitle: 'You are about to revoke your invitation.'.tr,

      isDismissable: true,

      submitText: 'Revoke'.tr,

      onSubmit: isLoading.value || isInitializing.value || !invitationSent.value
          ? null
          : (_) async {
              await revokeInvitationOfCurrentPractice();
            },
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
      final bool success = await dbService.leaveCurrentPractice(
        doctorId: doctor.id,
      );

      if (success) {
        removeFromList?.call(doctorId: doctor.id);
        isAssignedToCurrentPractice.value = false;
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check,
              title: 'Removed Doctor'.tr,
              message:
                  'The doctor has been successfully removed from your practice!'
                      .tr,
            ),
          );
        }
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'Removing Doctor Failed'.tr,
              message:
                  'An error occurred. They may have already been removed.'.tr,
            ),
          );
        }
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

    await CustomDialogHelper.show(
      routeName: 'remove-doctor-dialog',

      title: 'Remove Doctor?'.tr,

      subtitle: 'Remove doctor? They will lose access to all shared data.'.tr,

      isDismissable: true,

      submitText: 'Remove'.tr,

      onSubmit:
          isLoading.value ||
              isInitializing.value ||
              !isAssignedToCurrentPractice.value
          ? null
          : (_) async {
              await removeDoctorFromCurrentPractice();
            },
    );
  }
}
