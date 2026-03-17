import 'dart:async';

import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class PracticeProfileController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  DBService dbService = Get.find<DBService>();

  RxList<Doctor> assignedDoctors = <Doctor>[].obs;

  late Practice currentPractice;

  Rx<bool> isInitializing = true.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_initializeData());
  }

  Future<void> _initializeData() async {
    try {
      await loadPracticeData();
      await loadAssignedDoctors();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error while loading practice data: $e');
      }
    } finally {
      isInitializing.value = false;
    }
  }

  Future<void> loadPracticeData() async {
    final String? practiceId = authService.currentUser.value?.id;

    if (practiceId == null) {
      return;
    }

    final Practice? fetchedPractice = await dbService.fetchPractice(
      id: practiceId,
    );

    if (fetchedPractice == null) {
      throw Exception('No Practice was found with id: $practiceId');
    }

    currentPractice = fetchedPractice;
  }

  Future<void> loadAssignedDoctors() async {
    final String? practiceId = authService.currentUser.value?.id;

    if (practiceId == null) {
      return;
    }

    final List<Doctor> fetchedDoctors = await dbService.fetchDoctors(
      practiceId: practiceId,
    );

    assignedDoctors.assignAll(fetchedDoctors);
  }
}
