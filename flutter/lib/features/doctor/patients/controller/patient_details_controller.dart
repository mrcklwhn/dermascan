import 'dart:async';

import 'package:dermascan/core/models/body_lesion.dart';
import 'package:dermascan/core/models/patient.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/widgets/custom_bottom_sheets/diagnosis_bottom_sheet.dart';
import 'package:dermascan/core/widgets/custom_bottom_sheets/patient_info_bottom_sheet.dart';
import 'package:dermascan/core/widgets/custom_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PatientDetailsController extends GetxController {
  final AuthService authService = Get.find<AuthService>();
  final DBService dbService = Get.find<DBService>();

  final GlobalKey bodySelectorKey = GlobalKey();

  final RxBool isInitializing = true.obs;
  final RxBool isLoading = false.obs;

  late Patient patient;
  late final void Function({required Patient patient})? editPatient;

  final RxList<BodyLesion> lesions = <BodyLesion>[].obs;
  final Rxn<BodyLesion> selectedLesion = Rxn<BodyLesion>();
  final RxnString selectedPosition = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadValuesFromRoute();
    unawaited(_initializeData());
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
    editPatient = args['editPatient'];
  }

  Future<void> loadLesions() async {
    final String? doctorId = authService.currentUser.value?.id;
    if (doctorId == null) return;

    final List<BodyLesion> fetchedLesions = await dbService.fetchLesions(
      patientId: patient.id,
    );

    lesions.assignAll(fetchedLesions);
  }

  Future<void> openDiagnosisDialogFromInfo({
    required String position,
    String? diagnosisId,
  }) async {
    final BodyLesion lesion = lesions.firstWhere(
      (BodyLesion l) => l.position == position,
    );
    await openDiagnosisDialog(lesion: lesion, diagnosisId: diagnosisId);
  }

  Future<void> openDiagnosisDialog({
    required BodyLesion lesion,
    String? diagnosisId,
  }) async {
    selectedPosition.value = lesion.position;

    Future<void> showDiagnosisSheet() async {
      if (selectedLesion.value != null) {
        await Get.bottomSheet(
          DiagnosisBottomSheet(
            lesion: selectedLesion.value!,
            selectedDiagnosisId: diagnosisId,
            openEditLesionPage: openEditLesionPage,
            patient: patient,
          ),
          barrierColor: Colors.transparent,
          isScrollControlled: true,
          // Important for close diagnosis-bottom-sheet in Edit-Lesion-Controller (Delete)
          settings: const RouteSettings(name: 'diagnosis-bottom-sheet'),
        );

        selectedLesion.refresh();
        selectedLesion.value = null;
      }
      selectedPosition.value = null;
    }

    final BodyLesion? existingLesion = lesions.firstWhereOrNull(
      (BodyLesion l) => l.position == lesion.position,
    );

    if (existingLesion == null) {
      bool isSubmitting = false;

      await CustomDialogHelper.show<bool>(
        routeName: 'create-lesion-dialog',
        title: 'Create Lesion',
        subtitle:
            'No lesions have been recorded for this part of the body yet. '
            'Would you like to record a new one?',
        isDismissable: true,
        submitText: 'Record',
        onSubmit: () async {
          isSubmitting = true;

          final BodyLesion? created = await dbService.createLesion(
            patientId: patient.id,
            position: lesion.position,
            normal: lesion.normal,
          );

          if (created != null) {
            lesions.add(created);
            selectedLesion.value = created;

            await showDiagnosisSheet();
          } else {
            selectedPosition.value = null;
          }
        },
      );

      if (!isSubmitting) {
        selectedPosition.value = null;
      }
    } else {
      selectedLesion.value = existingLesion;
      await showDiagnosisSheet();
    }
  }

  void updateLesions({required BodyLesion lesion, required bool delete}) {
    if (delete) {
      selectedLesion.value = null;
      selectedPosition.value = null;

      lesions.removeWhere((BodyLesion l) => l.position == lesion.position);

      lesions.refresh();
    } else {
      final int index = lesions.indexWhere(
        (BodyLesion l) => l.position == lesion.position,
      );

      if (index != -1) {
        lesions[index] = lesion;

        if (selectedPosition.value == lesion.position) {
          selectedLesion.value = lesion;
        }
      }
    }
  }

  Future<void> openEditLesionPage() async {
    if (selectedLesion.value == null) return;

    await Get.toNamed(
      '/doctor/edit-lesion',
      preventDuplicates: false,
      arguments: <String, dynamic>{
        'lesion': selectedLesion.value,
        'updateLesions': updateLesions,
      },
    );
  }

  Future<void> openEditPatientPage() async {
    void editPatient({required Patient patient}) {
      this.editPatient?.call(patient: patient);
      this.patient = patient;
    }

    await Get.toNamed(
      '/doctor/edit-patient',
      preventDuplicates: false,
      arguments: <String, dynamic>{
        'patient': patient,
        'editPatient': editPatient,
      },
    );
  }

  Future<void> openPatientInfoDialog() async {
    selectedLesion.value = null;
    await Get.bottomSheet(
      PatientInfoBottomSheet(
        lesions: lesions,
        patient: patient,
        openEditPatientPage: openEditPatientPage,
        openDiagnosisDialog: openDiagnosisDialogFromInfo,
      ),
      barrierColor: Colors.transparent,
      isScrollControlled: true,
    );
  }
}
