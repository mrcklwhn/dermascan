import 'dart:async';

import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/models/invitation.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class AvailableDoctorsController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  DBService dbService = Get.find<DBService>();

  RxList<Doctor> doctors = <Doctor>[].obs;

  Rx<bool> isInitializing = true.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_initializeData());
  }

  Future<void> _initializeData() async {
    try {
      await loadAvailableDoctors();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error while loading available doctors: $e');
      }
    } finally {
      isInitializing.value = false;
    }
  }

  Future<void> loadAvailableDoctors() async {
    final List<Doctor> availableDoctors = await dbService.fetchDoctors(
      practiceId: null,
    );

    final List<Doctor> filteredDoctors = await removeInvitedDoctors(
      availableDoctors: availableDoctors,
    );

    doctors.assignAll(filteredDoctors);
  }

  Future<List<Doctor>> removeInvitedDoctors({
    required List<Doctor> availableDoctors,
  }) async {
    final String? practiceId = authService.currentUser.value?.id;

    if (practiceId == null) {
      return <Doctor>[];
    }

    final List<PracticeInvitation> invitations = await dbService
        .fetchInvitedDoctors(practiceId: practiceId);

    final Set<String> invitedDoctorIds = invitations
        .map((PracticeInvitation invitation) => invitation.doctor.id)
        .toSet();

    return availableDoctors
        .where((Doctor doctor) => !invitedDoctorIds.contains(doctor.id))
        .toList();
  }

  void removeInvitedDoctor({required String invitedDoctorId}) {
    doctors.removeWhere(((Doctor doctor) => doctor.id == invitedDoctorId));
  }

  void showDoctorProfile({required String doctorId}) {
    final Doctor selectedDoctor = doctors.firstWhere(
      (Doctor doc) => doc.id == doctorId,
    );

    Get.toNamed(
      '/practice/doctor-details',
      arguments: <String, Object>{
        'doctor': selectedDoctor,
        'assignedToPractice': selectedDoctor.practiceId != null,
        'removeInvitedDoctor': removeInvitedDoctor,
      },
    );
  }
}
