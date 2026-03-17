import 'dart:async';

import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class DoctorProfileController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  DBService dbService = Get.find<DBService>();

  late Doctor currentDoctor;
  late Practice currentPractice;

  RxList<Doctor> colleagues = <Doctor>[].obs;

  Rx<bool> isInitializing = true.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_initializeData());
  }

  Future<void> _initializeData() async {
    try {
      await loadDoctorData();
      await loadPracticeData();
      await loadColleagues();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error while loading practice data: $e');
      }
    } finally {
      isInitializing.value = false;
    }
  }

  Future<void> loadDoctorData() async {
    final String? doctorId = authService.currentUser.value?.id;

    if (doctorId == null) {
      return;
    }

    final Doctor? fetchedDoctor = await dbService.fetchDoctor(id: doctorId);

    if (fetchedDoctor == null) {
      return;
    }

    currentDoctor = fetchedDoctor;
  }

  Future<void> loadPracticeData() async {
    final String? practiceId = currentDoctor.practiceId;

    if (practiceId == null) {
      return;
    }

    final Practice? fetchedPractice = await dbService.fetchPractice(
      id: practiceId,
    );

    if (fetchedPractice == null) {
      return;
    }

    currentPractice = fetchedPractice;
  }

  Future<void> loadColleagues() async {
    final String? practiceId = currentDoctor.practiceId;

    if (practiceId == null) {
      return;
    }

    final List<Doctor> fetchedDoctors = await dbService.fetchDoctors(
      practiceId: currentDoctor.practiceId!,
    );

    // Filter out the current doctor so they don't see themselves as a colleague
    colleagues.assignAll(
      fetchedDoctors.where((Doctor d) => d.id != currentDoctor.id).toList(),
    );
  }
}
