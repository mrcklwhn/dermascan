import 'dart:async';

import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service/practice_db_service.dart';
import 'package:dermascan/core/widgets/custom_dialog.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorDetailsController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  PracticeDbService practiceDbService = Get.find<PracticeDbService>();

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
            title: TrKeys.common.authenticationError.tr,
            message: TrKeys.common.authErrorReLogin.tr,
          ),
        );
      }
      return;
    }

    isLoading.value = true;

    try {
      final bool success = await practiceDbService.inviteDoctorToPractice(
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
              title: TrKeys.practice.invitationSent.tr,
              message: TrKeys.practice.invitationSentMsg.tr,
            ),
          );
        }
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: TrKeys.practice.invitationSentError.tr,
              message: TrKeys.practice.alreadyInvitedMsg.tr,
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

      title: TrKeys.practice.inviteDoctorQuestion.tr,

      subtitle: TrKeys.practice.inviteDoctorConfirmMsg.tr,

      isDismissable: true,

      submitText: TrKeys.practice.invite.tr,

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
            title: TrKeys.common.authenticationError.tr,
            message: TrKeys.common.authErrorReLogin.tr,
          ),
        );
      }
      return;
    }

    isLoading.value = true;

    try {
      final bool success = await practiceDbService.revokePracticeInvitation(
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
              title: TrKeys.practice.invitationRevoked.tr,
              message: TrKeys.practice.invitationRevokedMsg.tr,
            ),
          );
        }
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: TrKeys.practice.revokingFailed.tr,
              message: TrKeys.practice.revokingFailedMsg.tr,
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

      title: TrKeys.practice.revokeInvitationQuestion.tr,

      subtitle: TrKeys.practice.revokeConfirmMsg.tr,

      isDismissable: true,

      submitText: TrKeys.common.revoke.tr,

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
            title: TrKeys.common.authenticationError.tr,
            message: TrKeys.common.authErrorReLogin.tr,
          ),
        );
      }
      return;
    }

    isLoading.value = true;

    try {
      final bool success = await practiceDbService.leaveCurrentPractice(
        doctorId: doctor.id,
      );

      if (success) {
        removeFromList?.call(doctorId: doctor.id);
        isAssignedToCurrentPractice.value = false;
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check,
              title: TrKeys.practice.removedDoctor.tr,
              message: TrKeys.practice.doctorRemovedSuccessMsg.tr,
            ),
          );
        }
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: TrKeys.practice.removingDoctorFailed.tr,
              message: TrKeys.practice.alreadyRemovedMsg.tr,
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

      title: TrKeys.practice.removeDoctorQuestion.tr,

      subtitle: TrKeys.practice.removeDoctorConfirmMsg.tr,

      isDismissable: true,

      submitText: TrKeys.common.remove.tr,

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
