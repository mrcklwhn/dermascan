import 'package:dermascan/app/enums.dart';
import 'package:dermascan/core/models/country.dart';
import 'package:dermascan/core/models/patient.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/widgets/country_selector_bottom_sheet.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AddPatientController extends GetxController {
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

  @override
  void onClose() {
    scrollController.dispose();
    nameController.dispose();
    birthdayController.dispose();
    currentCountryTextController.dispose();
    birthCountryTextController.dispose();
    super.onClose();
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

      final Patient? createdPatient = await dbService.createPatientProfile(
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

      if (createdPatient != null) {
        Get.back(result: createdPatient);
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check_circle,
              title: 'Patient Created'.tr,
              message: 'Profile successfully created and added to practice.'.tr,
            ),
          );
        }
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'Patient Creation Failed'.tr,
              message: 'Profile creation failed. Please check your data.'.tr,
            ),
          );
        }
      }
    } finally {
      isLoading.value = false;
    }
  }
}
