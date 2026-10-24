import 'dart:async';

import 'package:dermascan/core/models/patient.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service/doctor_db_service.dart';
import 'package:dermascan/core/services/db_service/patient_db_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PatientsController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  DoctorDbService doctorDbService = Get.find<DoctorDbService>();
  PatientDbService patientDbService = Get.find<PatientDbService>();

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

  void _sortLists() {
    patients.sort(
      (Patient a, Patient b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    visiblePatients.sort(
      (Patient a, Patient b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
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
    final Practice? practiceOfDoctor = await doctorDbService.checkDoctorHasPractice();

    if (practiceOfDoctor == null) return;

    final List<Patient> fetchedPatients = await patientDbService.fetchPatients(
      practiceId: practiceOfDoctor.id,
    );

    patients.assignAll(fetchedPatients);
    visiblePatients.assignAll(fetchedPatients);
    _sortLists();
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
    _sortLists();
  }

  void unfocusSearchBar() {
    searchBarFocusNode.unfocus();
  }

  void clearSearchBar() {
    searchBarController.clear();
    filterPatients(query: '');
  }

  void addNewPatient({required Patient newPatient}) {
    patients.add(newPatient);
    visiblePatients.add(newPatient);
    _sortLists();
  }

  void editPatient({required Patient patient, required bool deleted}) {
    if (deleted) {
      patients.removeWhere((Patient p) => p.id == patient.id);
      visiblePatients.removeWhere((Patient p) => p.id == patient.id);
    } else {
      final int index = patients.indexWhere((Patient p) => p.id == patient.id);
      if (index != -1) {
        patients[index] = patient;
      }
      final int visibleIndex = visiblePatients.indexWhere(
        (Patient p) => p.id == patient.id,
      );
      if (visibleIndex != -1) {
        visiblePatients[visibleIndex] = patient;
      }
    }
    _sortLists();
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
      arguments: <String, dynamic>{
        'patient': selectedPatient,
        'editPatient': editPatient,
      },
    );
  }
}
