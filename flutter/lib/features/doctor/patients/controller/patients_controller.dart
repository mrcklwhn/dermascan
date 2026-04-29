import 'dart:async';

import 'package:dermascan/core/models/patient.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PatientsController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  DBService dbService = Get.find<DBService>();

  ScrollController listScrollController = ScrollController();

  TextEditingController searchBarController = TextEditingController();

  FocusNode searchBarFocusNode = FocusNode();

  RxBool isInitializing = true.obs;

  RxList<Patient> patients = <Patient>[].obs;
  RxList<Patient> visiblePatients = <Patient>[].obs;

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
    final List<Patient> fetchedPatients = await dbService.fetchPatients(
      practiceId: practiceOfDoctor.id,
    );

    patients.assignAll(fetchedPatients);
    visiblePatients.assignAll(fetchedPatients);
  }

  void filterPatients({required String query}) {
    if (query.isEmpty) {
      visiblePatients.assignAll(patients);
    } else {
      final Iterable<Patient> filtered = patients.where(
        (Patient p) => p.name.toLowerCase().contains(query.toLowerCase()),
      );
      visiblePatients.assignAll(filtered);
    }
  }

  void unfocusSearchBar() {
    searchBarFocusNode.unfocus();
  }

  void clearSearchBar() {
    searchBarController.clear();
    filterPatients(query: searchBarController.value.text);
  }

  void addNewPatient({required Patient newPatient}) {
    patients.add(newPatient);
    visiblePatients.add(newPatient);
  }

  void removePatient({required String patientId}) {
    patients.removeWhere((Patient part) => part.id == patientId);
    visiblePatients.removeWhere((Patient part) => part.id == patientId);
  }

  Future<void> openAddNewPatientScreen() async {
    if (isInitializing.value) return;

    final dynamic newPatient = await Get.toNamed('/doctor/add-new-patient');
    if (newPatient != null && newPatient is Patient) {
      addNewPatient(newPatient: newPatient);
    }
  }

  void openPatientProfile({required String patientId}) {
    if (isInitializing.value) return;

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
