import 'dart:async';

import 'package:dermascan/core/models/invitation.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service/practice_db_service.dart';
import 'package:dermascan/core/widgets/custom_dialog.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InvitationsController extends GetxController {
  PracticeDbService practiceDbService = Get.find<PracticeDbService>();
  AuthService authService = Get.find<AuthService>();

  ScrollController listScrollController = ScrollController();

  TextEditingController searchBarController = TextEditingController();

  FocusNode searchBarFocusNode = FocusNode();

  RxList<PracticeInvitation> pendingInvitations = <PracticeInvitation>[].obs;
  RxList<PracticeInvitation> visiblePendingInvitations =
      <PracticeInvitation>[].obs;

  RxBool isInitializing = true.obs;
  RxBool isLoading = false.obs;

  @override
  void onClose() {
    listScrollController.dispose();
    searchBarController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_initializeData());
  }

  Future<void> _initializeData() async {
    try {
      await loadPendingInvitations();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error while loading pending invitations: $e');
      }
    } finally {
      isInitializing.value = false;
    }
  }

  Future<void> loadPendingInvitations() async {
    final String? doctorId = authService.currentUser.value?.id;

    if (doctorId == null) {
      return;
    }

    final List<PracticeInvitation> fetchedInvitations = await practiceDbService
        .fetchInvitingPractices(doctorId: doctorId);

    pendingInvitations.assignAll(fetchedInvitations);
    visiblePendingInvitations.assignAll(fetchedInvitations);
  }

  void clearSearchBar() {
    searchBarController.clear();
    filterPractices(query: searchBarController.value.text);
  }

  void unfocusSearchBar() {
    searchBarFocusNode.unfocus();
  }

  Future<void> reloadInvitations() async {
    if (isInitializing.value || isLoading.value) return;

    isInitializing.value = true;
    unawaited(_initializeData());
  }

  void filterPractices({required String query}) {
    if (query.isEmpty) {
      visiblePendingInvitations.assignAll(pendingInvitations);
    } else {
      final Iterable<PracticeInvitation> filtered = pendingInvitations.where(
        (PracticeInvitation invitation) => invitation.practice.name
            .toLowerCase()
            .contains(query.toLowerCase()),
      );
      visiblePendingInvitations.assignAll(filtered);
    }
  }

  Future<void> acceptPracticeInvitation({required Practice practice}) async {
    if (isInitializing.value || isLoading.value) return;

    final String? doctorId = authService.currentUser.value?.id;

    if (doctorId == null) {
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
      final bool success = await practiceDbService.acceptPracticeInvitation(
        practiceId: practice.id,
      );
      if (success) {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check,
              title: 'Invitation Accepted'.tr,
              message: 'You have successfully joined the practice.'.tr,
            ),
          );
        }
        await authService.evaluateRouteAndNavigate();
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'Error Accepting Invitation'.tr,
              message:
                  'Acceptance failed. Invitation invalid or you are already assigned.'
                      .tr,
            ),
          );
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> showPracticeJoinDialog({required String practiceId}) async {
    if (isLoading.value || isInitializing.value) return;

    final PracticeInvitation selectedInvitation = pendingInvitations.firstWhere(
      (PracticeInvitation invitation) => invitation.practice.id == practiceId,
    );

    await CustomDialogHelper.show(
      routeName: 'accept-practice-invitation-dialog',

      title: 'Accept invitation?'.tr,

      subtitle:
          'Accepting grants access to practice data and shares your professional profile with the owner.'
              .tr,

      isDismissable: true,

      submitText: 'Accept'.tr,

      onSubmit: (_) async {
              await acceptPracticeInvitation(
                practice: selectedInvitation.practice,
              );
            },
    );
  }
}
