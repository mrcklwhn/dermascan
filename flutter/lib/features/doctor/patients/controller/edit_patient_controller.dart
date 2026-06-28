import 'dart:async';

import 'package:dermascan/app/enums.dart';
import 'package:dermascan/core/models/country.dart';
import 'package:dermascan/core/models/patient.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/widgets/country_selector_bottom_sheet.dart';
import 'package:dermascan/core/widgets/custom_dialog.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class EditPatientController extends GetxController {
  DBService dbService = Get.find<DBService>();
  AuthService authService = Get.find<AuthService>();

  ScrollController scrollController = ScrollController();

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
    scrollController.dispose();
    nameController.dispose();
    birthdayController.dispose();
    currentCountryTextController.dispose();
    birthCountryTextController.dispose();
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
        allCountries
            .firstWhereOrNull((Country c) => c.isoCode == patient.birthCountry)
            ?.name ??
        '';
    currentCountry = patient.currentCountry;
    currentCountryTextController.text =
        allCountries
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
            title: 'Authentication Error'.tr,
            message: 'Authentication error. Please log in again.'.tr,
          ),
        );
      }
      return;
    }

    isLoading.value = true;

    try {
      final Practice? practiceOfDoctor = await dbService
          .checkDoctorHasPractice();

      if (practiceOfDoctor == null) {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'No Practice Assigned'.tr,
              message:
                  'You must be assigned to a practice to execute this operation.'
                      .tr,
            ),
          );
        }
        return;
      }

      final bool successful = await dbService.deletePatientProfile(
        patientId: patient.id,
      );
      if (successful) {
        editPatient?.call(patient: patient, deleted: true);
        Get.until((Route<dynamic> route) => Get.currentRoute == '/doctor/home');
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check_circle,
              title: 'Patient Deleted'.tr,
              message: 'Patient successfully deleted.'.tr,
            ),
          );
        }
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'Error Deleting Patient'.tr,
              message: 'Deletion failed. Ensure no lesions are linked.'.tr,
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

      title: 'Delete Patient?'.tr,

      subtitle: 'Delete patient? Associated lesions must be removed first.'.tr,

      isDismissable: true,

      submitText: 'Delete'.tr,

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
            title: 'Missing Information'.tr,
            message: 'Please fill in all required fields.'.tr,
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
            title: 'Authentication Error'.tr,
            message: 'Authentication error. Please log in again.'.tr,
          ),
        );
      }
      return;
    }

    isLoading.value = true;

    try {
      final Practice? practiceOfDoctor = await dbService
          .checkDoctorHasPractice();

      if (practiceOfDoctor == null) {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'No Practice Assigned'.tr,
              message:
                  'You must be assigned to a practice to execute this operation.'
                      .tr,
            ),
          );
        }
        return;
      }

      final Patient? updatedPatient = await dbService.updatePatientProfile(
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
              title: 'Patient Updated'.tr,
              message: 'Profile successfully updated.'.tr,
            ),
          );
        }
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'Patient Update Failed'.tr,
              message: 'Profile update failed. Please check your data.'.tr,
            ),
          );
        }
      }
    } finally {
      isLoading.value = false;
    }
  }
}
