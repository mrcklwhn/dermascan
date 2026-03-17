import 'dart:async';

import 'package:dermascan/core/models/patient.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class PatientsController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  DBService dbService = Get.find<DBService>();

  RxList<Patient> patients = <Patient>[].obs;

  Rx<bool> isInitializing = true.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_initializeData());
  }

  Future<void> _initializeData() async {
    try {
      await loadPatients();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error while loading available patients: $e');
      }
    } finally {
      isInitializing.value = false;
    }
  }

  Future<void> loadPatients() async {
    final Practice? practiceOfDoctor = await dbService.checkDoctorHasPractice();

    if (practiceOfDoctor == null) {
      return;
    }

    final List<Patient> patients = await dbService.fetchPatients(
      practiceId: practiceOfDoctor.id,
    );

    this.patients.assignAll(patients);
  }

  void addCreatedPatient({required Patient createdPatient}) {
    patients.add(createdPatient);
  }

  void removePatient({required String patientId}) {
    patients.removeWhere((Patient part) => part.id == patientId);
  }

  Future<void> openCreateNewPatientScreen() async {
    final dynamic createdPatient = await Get.toNamed(
      '/doctor/create-new-patient',
    );
    if (createdPatient != null && createdPatient is Patient) {
      addCreatedPatient(createdPatient: createdPatient);
    }
  }

  void showPatientProfile({required String patientId}) {
    final Patient selectedPatient = patients.firstWhere(
      (Patient pat) => pat.id == patientId,
    );

    Get.toNamed(
      '/doctor/patient-details',
      arguments: <String, Object>{
        'patient': selectedPatient,
        'removePatient': removePatient,
      },
    );
  }
}
