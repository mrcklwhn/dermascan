import 'dart:async';

import 'package:dermascan/app/enums.dart';
import 'package:dermascan/core/models/body_lesion.dart';
import 'package:dermascan/core/models/patient.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/widgets/custom_bottom_sheets/diagnosis_bottom_sheet.dart';
import 'package:dermascan/core/widgets/custom_bottom_sheets/patient_info_bottom_sheet.dart';
import 'package:dermascan/core/widgets/custom_dialog.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:dermascan/core/widgets/human_body_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PatientDetailsController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  DBService dbService = Get.find<DBService>();

  ScrollController scrollController = ScrollController();

  Rx<HumanBodySide> currentSelectedBodySide = HumanBodySide.front.obs;

  GlobalKey<SelectableSvgState> bodySelectorKey =
      GlobalKey<SelectableSvgState>();

  RxBool isInitializing = true.obs;
  RxBool isLoading = false.obs;

  RxList<BodyLesion> lesions = <BodyLesion>[].obs;
  RxMap<String, ({int count, bool isSuspicious})> lesionDiagnosisCountMap =
      <String, ({int count, bool isSuspicious})>{}.obs;

  Rxn<BodyLesion> selectedLesion = Rxn<BodyLesion>();

  late Patient patient;

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

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
  }

  void updateLesionMap() {
    final Map<String, ({int count, bool isSuspicious})> newValues =
        <String, ({int count, bool isSuspicious})>{};

    for (final BodyLesion lesion in lesions) {
      final bool suspicious = lesion.isSuspicious.value;

      if (newValues.containsKey(lesion.location)) {
        final ({int count, bool isSuspicious}) current =
            newValues[lesion.location]!;
        newValues[lesion.location] = (
          count: current.count + lesion.diagnoses.length,
          isSuspicious: current.isSuspicious || suspicious,
        );
      } else {
        newValues[lesion.location] = (
          count: lesion.diagnoses.length,
          isSuspicious: suspicious,
        );
      }
    }
    lesionDiagnosisCountMap.assignAll(newValues);
  }

  Future<void> loadLesions() async {
    final String? doctorId = authService.currentUser.value?.id;

    if (doctorId == null) {
      return;
    }

    final List<BodyLesion> fetchedLesions = await dbService.fetchLesions(
      patientId: patient.id,
    );
    lesions.addAll(fetchedLesions);
    updateLesionMap();
  }

  void changeCurrentSelectedBodySide({HumanBodySide? bodySide}) {
    if (bodySide == null) {
      if (currentSelectedBodySide.value == HumanBodySide.front) {
        currentSelectedBodySide.value = HumanBodySide.back;
      } else {
        currentSelectedBodySide.value = HumanBodySide.front;
      }
    } else {
      currentSelectedBodySide.value = bodySide;
    }
  }

  String getBodyMap({required Gender gender, required HumanBodySide bodySide}) {
    if (gender == Gender.male ||
        gender == Gender.undefined ||
        gender == Gender.divers) {
      if (bodySide == HumanBodySide.front) {
        return BodySelectorMaps.maleFront;
      } else {
        return BodySelectorMaps.maleBack;
      }
    } else {
      if (bodySide == HumanBodySide.front) {
        return BodySelectorMaps.femaleFront;
      } else {
        return BodySelectorMaps.femaleBack;
      }
    }
  }

  Future<void> openEditPatientPage() async {
    final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;

    final dynamic editedPatient = await Get.toNamed(
      '/doctor/edit-patient',
      arguments: <String, Object>{
        'patient': patient,
        'editPatient': args['editPatient'],
      },
    );

    if (editedPatient != null && editedPatient is Patient) {
      patient = editedPatient;
    }
  }

  Future<void> openPatientInfoDialog() async {
    selectedLesion.value = null;
    bodySelectorKey.currentState?.clearSelection();
    await Get.bottomSheet(
      PatientInfoBottomSheet(
        lesions: lesions,
        patient: patient,
        openEditPatientPage: openEditPatientPage,
        openDiagnosisDialog: openDiagnosisDialog,
      ),
      barrierColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  Future<void> openDiagnosisDialog({
    required String bodyPartId,
    bool? fromInfoSheet,
  }) async {
    if (fromInfoSheet != null && fromInfoSheet) {
      if (bodyPartId.startsWith('bck')) {
        changeCurrentSelectedBodySide(bodySide: HumanBodySide.back);
      } else {
        changeCurrentSelectedBodySide(bodySide: HumanBodySide.front);
      }

      Future<void>.delayed(const Duration(milliseconds: 100), () {
        bodySelectorKey.currentState?.selectPartById(bodyPartId);
      });
    }

    selectedLesion.value = lesions.firstWhereOrNull(
      (BodyLesion lesion) => lesion.location == bodyPartId,
    );

    if (selectedLesion.value == null) {
      final bool? didRecord = await Get.dialog<bool>(
        CustomDialog(
          title: 'Create Lesion',
          subtitle:
              'No lesions have been recorded for this part of the body yet. Would you like to record a new one?',
          isDismissable: true,
          submitText: 'Record',
          onSubmit: () async {
            final BodyLesion? createdLesion = await dbService.createLesion(
              location: bodyPartId,
              patientId: patient.id,
            );
            if (createdLesion != null) {
              selectedLesion.value = createdLesion;
              lesions.add(selectedLesion.value!);
              Get.back(result: true);
            } else {
              Get.back(result: false);
            }
          },
        ),
      );

      if (didRecord != true) {
        bodySelectorKey.currentState?.clearSelection();
        return;
      }
    }

    if (selectedLesion.value == null) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Lesion Error',
          message:
              'There is no existing Lesion, neither one could be created. Try again later.',
        ),
      );
      return;
    }

    await Get.bottomSheet(
      DiagnosisBottomSheet(lesion: selectedLesion.value!, patient: patient),
      barrierColor: Colors.transparent,
      isScrollControlled: true,
    );
    updateLesionMap();
    selectedLesion.value = null;
    bodySelectorKey.currentState?.clearSelection();
  }
}
