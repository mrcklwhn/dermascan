import 'dart:async';

import 'package:dermascan/core/models/invitation.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class InvitationsController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  DBService dbService = Get.find<DBService>();

  RxList<Practice> pendingInvitations = <Practice>[].obs;

  Rx<bool> isInitializing = true.obs;

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

    final List<PracticeInvitation> invitations = await dbService
        .fetchInvitingPractices(doctorId: doctorId);

    final List<Practice> invitingPractices = invitations
        .map((PracticeInvitation invitation) => invitation.practice)
        .toList();

    pendingInvitations.assignAll(invitingPractices);
  }

  void showPracticeProfile({required String practiceId}) {
    final Practice selectedPractice = pendingInvitations.firstWhere(
      (Practice practice) => practice.id == practiceId,
    );

    Get.toNamed(
      '/doctor/practice-details',
      arguments: <String, Object>{
        'practice': selectedPractice,
        'isPracticeOfCurrentDoctor': false,
      },
    );
  }
}
