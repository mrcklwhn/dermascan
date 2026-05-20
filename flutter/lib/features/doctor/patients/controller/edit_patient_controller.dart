import 'dart:async';

import 'package:dermascan/app/enums.dart';
import 'package:dermascan/core/models/country.dart';
import 'package:dermascan/core/models/patient.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/widgets/custom_bottom_sheets/country_selector_bottom_sheet.dart';
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

  String? currentCountry;
  String? birthCountry;

  DateTime? dateOfBirth;

  Gender? selectedGender;

  List<Gender> get genderOptions => Gender.values;

  late Patient patient;
  late final void Function({required Patient patient})? editPatient;

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
    birthdayController.text = DateFormat.yMMMd().format(patient.dateOfBirth);
    selectedGender = patient.gender;
    previousSunburns.value = patient.previousSunburns;
    previousSkinSurgeries.value = patient.previousSkinSurgeries;
    tanningBedExposure.value = patient.tanningBedExposure;
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
      birthdayController.text = DateFormat.yMMMd().format(picked);
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

  Future<void> submitPatientData() async {
    if (isLoading.value) return;

    if (selectedGender == null ||
        nameController.text.trim().isEmpty ||
        dateOfBirth == null ||
        birthCountry == null ||
        currentCountry == null) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Missing Information',
          message:
              'Please fill in all required fields to update a patient profile.',
        ),
      );
      return;
    }

    final String? doctorId = authService.currentUser.value?.id;

    if (doctorId == null) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Authentication Error',
          message: 'You are not signed in correctly. Please log in again.',
        ),
      );
      return;
    }

    isLoading.value = true;

    try {
      final Practice? practiceOfDoctor = await dbService
          .checkDoctorHasPractice();

      if (practiceOfDoctor == null) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'No Practice Assigned',
            message:
                'You must be assigned to a practice to update patient profiles.',
          ),
        );
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
      );

      if (updatedPatient != null) {
        editPatient?.call(patient: updatedPatient);
        Get.back(closeOverlays: true);

        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.check_circle,
            title: 'Patient Updated',
            message: 'The profile was successfully updated.',
          ),
        );
      } else {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Patient Creation Failed',
            message:
                'The profile could not be updated. Please check the data or try again later.',
          ),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}
