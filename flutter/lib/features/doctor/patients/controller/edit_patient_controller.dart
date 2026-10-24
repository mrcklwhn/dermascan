import 'dart:async';

import 'package:dermascan/core/enums.dart';
import 'package:dermascan/core/models/country.dart';
import 'package:dermascan/core/models/patient.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service/doctor_db_service.dart';
import 'package:dermascan/core/services/db_service/patient_db_service.dart';
import 'package:dermascan/core/widgets/country_selector_bottom_sheet.dart';
import 'package:dermascan/core/widgets/custom_dialog.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class EditPatientController extends GetxController {
  DoctorDbService doctorDbService = Get.find<DoctorDbService>();
  PatientDbService patientDbService = Get.find<PatientDbService>();
  AuthService authService = Get.find<AuthService>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController currentCountryTextController =
      TextEditingController();
  final TextEditingController birthCountryTextController =
      TextEditingController();

  final FocusNode nameFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();

  RxBool isLoading = false.obs;
  RxBool tanningBedExposure = false.obs;
  RxBool previousSkinSurgeries = false.obs;
  RxBool previousSunburns = false.obs;
  RxBool sunscreenUse = false.obs;
  RxBool previousCancerSurgeries = false.obs;
  RxBool personalHistoryMelanoma = false.obs;
  RxBool familyHistoryMelanoma = false.obs;

  String? currentCountry;
  String? birthCountry;

  DateTime? dateOfBirth;

  Gender? selectedGender;

  List<Gender> get genderOptions => Gender.values;

  late Patient patient;
  late final void Function({required Patient patient, required bool deleted})?
  editPatient;

  @override
  void onClose() {
    nameController.dispose();
    birthdayController.dispose();
    currentCountryTextController.dispose();
    birthCountryTextController.dispose();
    nameFocusNode.dispose();
    emailFocusNode.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    loadValuesFromRoute();
  }

  void loadValuesFromRoute() {
    final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;
    patient = args['patient'];
    editPatient = args['editPatient'];

    nameController.text = patient.name;
    dateOfBirth = patient.dateOfBirth;
    birthdayController.text = DateFormat(
      'dd.MM.yyyy',
    ).format(patient.dateOfBirth);
    selectedGender = patient.gender;
    previousSunburns.value = patient.previousSunburns;
    previousSkinSurgeries.value = patient.previousSkinSurgeries;
    tanningBedExposure.value = patient.tanningBedExposure;
    previousCancerSurgeries.value = patient.previousCancerSurgeries;
    sunscreenUse.value = patient.sunscreenUse;
    personalHistoryMelanoma.value = patient.personalHistoryMelanoma;
    familyHistoryMelanoma.value = patient.familyHistoryMelanoma;

    birthCountry = patient.birthCountry;
    birthCountryTextController.text =
        countries
            .firstWhereOrNull((Country c) => c.isoCode == patient.birthCountry)
            ?.name ??
        '';
    currentCountry = patient.currentCountry;
    currentCountryTextController.text =
        countries
            .firstWhereOrNull(
              (Country c) => c.isoCode == patient.currentCountry,
            )
            ?.name ??
        '';
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != dateOfBirth) {
      dateOfBirth = picked;
      birthdayController.text = DateFormat('dd.MM.yyyy').format(picked);
    }
  }

  void submittedName() {
    nameFocusNode.unfocus();
  }

  Future<void> showCountryBottomSheet({
    required BuildContext context,
    required bool isBirthCountry,
  }) async {
    await Get.bottomSheet(
      CountrySelectorBottomSheet(
        onCountrySelected: (Country country) {
          if (isBirthCountry) {
            birthCountry = country.isoCode;
            birthCountryTextController.text = country.name;
          } else {
            currentCountry = country.isoCode;
            currentCountryTextController.text = country.name;
          }
        },
      ),
      isScrollControlled: true,
    );
  }

  Future<void> deletePatient() async {
    final String? doctorId = authService.currentUser.value?.id;

    if (doctorId == null) {
      if (!Get.isSnackbarOpen) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: TrKeys.common.authenticationError.tr,
            message: TrKeys.common.authErrorReLogin.tr,
          ),
        );
      }
      return;
    }

    isLoading.value = true;

    try {
      final Practice? practiceOfDoctor = await doctorDbService
          .checkDoctorHasPractice();

      if (practiceOfDoctor == null) {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: TrKeys.practice.noPracticeAssigned.tr,
              message:
                  TrKeys.practice.notAssignedToPracticeMsg
                      .tr,
            ),
          );
        }
        return;
      }

      final bool successful = await patientDbService.deletePatientProfile(
        patientId: patient.id,
      );
      if (successful) {
        editPatient?.call(patient: patient, deleted: true);
        Get.until((Route<dynamic> route) => Get.currentRoute == '/doctor/home');
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check_circle,
              title: TrKeys.patient.patientDeleted.tr,
              message: TrKeys.patient.patientDeletedMsg.tr,
            ),
          );
        }
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: TrKeys.patient.errorDeletingPatient.tr,
              message: TrKeys.patient.deletionFailedLesionsLinkedMsg.tr,
            ),
          );
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> showDeletePatientDialog() async {
    if (isLoading.value) return;

    await CustomDialogHelper.show(
      routeName: 'delete-patient-dialog',

      title: TrKeys.patient.deletePatientQuestion.tr,

      subtitle: TrKeys.patient.deletePatientConfirmMsg.tr,

      isDismissable: true,

      submitText: TrKeys.common.delete.tr,

      onSubmit: (_) async {
        await deletePatient();
      },
    );
  }

  Future<void> submitPatientData() async {
    if (isLoading.value) return;

    if (selectedGender == null ||
        nameController.text.trim().isEmpty ||
        dateOfBirth == null ||
        birthCountry == null ||
        currentCountry == null) {
      if (!Get.isSnackbarOpen) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: TrKeys.common.missingInformation.tr,
            message: TrKeys.common.fillRequiredFields.tr,
          ),
        );
      }
      return;
    }

    final String? doctorId = authService.currentUser.value?.id;

    if (doctorId == null) {
      if (!Get.isSnackbarOpen) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: TrKeys.common.authenticationError.tr,
            message: TrKeys.common.authErrorReLogin.tr,
          ),
        );
      }
      return;
    }

    isLoading.value = true;

    try {
      final Practice? practiceOfDoctor = await doctorDbService
          .checkDoctorHasPractice();

      if (practiceOfDoctor == null) {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: TrKeys.practice.noPracticeAssigned.tr,
              message:
                  TrKeys.practice.notAssignedToPracticeMsg
                      .tr,
            ),
          );
        }
        return;
      }

      final Patient? updatedPatient = await patientDbService.updatePatientProfile(
        patientId: patient.id,
        name: nameController.text.trim(),
        gender: selectedGender!.name,
        dateOfBirth: dateOfBirth!,
        birthCountry: birthCountry!,
        currentCountry: currentCountry!,
        practiceId: practiceOfDoctor.id,
        tanningBedExposure: tanningBedExposure.value,
        previousSkinSurgeries: previousSkinSurgeries.value,
        previousSunburns: previousSunburns.value,
        previousCancerSurgeries: previousSkinSurgeries.value
            ? previousCancerSurgeries.value
            : false,
        sunscreenUse: sunscreenUse.value,
        personalHistoryMelanoma: personalHistoryMelanoma.value,
        familyHistoryMelanoma: familyHistoryMelanoma.value,
      );

      if (updatedPatient != null) {
        editPatient?.call(patient: updatedPatient, deleted: false);
        Get.back(closeOverlays: true);
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check_circle,
              title: TrKeys.patient.patientUpdated.tr,
              message: TrKeys.patient.profileUpdatedMsg.tr,
            ),
          );
        }
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: TrKeys.patient.patientUpdateFailed.tr,
              message: TrKeys.patient.profileUpdateFailedMsg.tr,
            ),
          );
        }
      }
    } finally {
      isLoading.value = false;
    }
  }
}
