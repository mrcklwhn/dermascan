import 'dart:async';

import 'package:dermascan/core/models/lesion.dart';
import 'package:dermascan/core/models/patient.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class PatientDetailsController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  DBService dbService = Get.find<DBService>();

  RxBool isInitializing = true.obs;
  RxBool isLoading = false.obs;

  RxList<Lesion> lesions = <Lesion>[].obs;

  late Patient patient;

  @override
  void onInit() {
    super.onInit();
    unawaited(_initializeData());
    loadValuesFromRoute();
  }

  Future<void> _initializeData() async {
    try {
      await loadLesions();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error while loading lesions: $e');
      }
    } finally {
      isInitializing.value = false;
    }
  }

  void loadValuesFromRoute() {
    final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;
    patient = args['patient'];
  }

  Future<void> loadLesions() async {
    final String? doctorId = authService.currentUser.value?.id;

    if (doctorId == null) {
      return;
    }
  }
}
