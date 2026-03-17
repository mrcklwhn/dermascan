import 'dart:async';

import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class AssignedDoctorsController extends GetxController {
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
      await loadDoctorsAssignedToPractice();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Error while loading doctors assigned to practice [${authService.currentUser.value?.id}] : $e',
        );
      }
    } finally {
      isInitializing.value = false;
    }
  }

  Future<void> loadDoctorsAssignedToPractice() async {
    final String? practiceId = authService.currentUser.value?.id;

    if (practiceId == null) {
      return;
    }

    final List<Doctor> assignedDoctors = await dbService.fetchDoctors(
      practiceId: practiceId,
    );
    doctors.assignAll(assignedDoctors);
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
      },
    );
  }

  void showAvailableDoctors() {
    Get.toNamed('/practice/available-doctors');
  }

  void showPendingInvitations() {
    Get.toNamed('/practice/pending-invitations');
  }
}
