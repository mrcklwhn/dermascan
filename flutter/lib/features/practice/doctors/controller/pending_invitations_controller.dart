import 'dart:async';

import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/models/invitation.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class PendingInvitationsController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  DBService dbService = Get.find<DBService>();

  RxList<Doctor> pendingInvitations = <Doctor>[].obs;

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
    final String? practiceId = authService.currentUser.value?.id;

    if (practiceId == null) {
      return;
    }

    final List<PracticeInvitation> invitations = await dbService
        .fetchInvitedDoctors(practiceId: practiceId);

    final List<Doctor> invitedDoctors = invitations
        .map((PracticeInvitation invitation) => invitation.doctor)
        .toList();

    pendingInvitations.assignAll(invitedDoctors);
  }

  void showDoctorProfile({required String doctorId}) {
    final Doctor selectedDoctor = pendingInvitations.firstWhere(
      (Doctor doc) => doc.id == doctorId,
    );

    Get.toNamed(
      '/practice/doctor-details',
      arguments: <String, Object>{
        'doctor': selectedDoctor,
        'assignedToPractice': true,
      },
    );
  }
}
