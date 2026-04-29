import 'package:dermascan/app/enums.dart';
import 'package:dermascan/core/models/patient.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AddPatientController extends GetxController {
  DBService dbService = Get.find<DBService>();
  AuthService authService = Get.find<AuthService>();

  ScrollController scrollController = ScrollController();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();

  final FocusNode nameFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();

  RxBool isLoading = false.obs;
  RxBool isValidEmail = false.obs;

  DateTime? dateOfBirth;

  Gender? selectedGender;

  List<Gender> get genderOptions => Gender.values;

  @override
  void onClose() {
    scrollController.dispose();
    nameController.dispose();
    emailController.dispose();
    birthdayController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    emailController.addListener(() {
      isValidEmail.value = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
      ).hasMatch(emailController.text);
    });
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

  Future<void> submitPatientData() async {
    if (isLoading.value) return;

    if (selectedGender == null ||
        nameController.text.trim().isEmpty ||
        dateOfBirth == null ||
        emailController.text.trim().isEmpty) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Missing Information',
          message:
              'Please fill in all required fields to create a patient profile.',
        ),
      );
      return;
    }

    if (!isValidEmail.value) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Invalid E-Mail',
          message: 'Your e-mail is not formatted correctly.',
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
                'You must be assigned to a practice to create new patient profiles.',
          ),
        );
        return;
      }

      final Patient? createdPatient = await dbService.createPatientProfile(
        name: nameController.text.trim(),
        gender: selectedGender!.name,
        dateOfBirth: dateOfBirth,
        email: emailController.text.trim(),
        practiceId: practiceOfDoctor.id,
      );

      if (createdPatient != null) {
        Get.back(result: createdPatient);
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.check_circle,
            title: 'Patient Created',
            message:
                'The profile was successfully created and added to your Practice.',
          ),
        );
      } else {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Patient Creation Failed',
            message:
                'The profile could not be created. Please check the data or try again later.',
          ),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}
