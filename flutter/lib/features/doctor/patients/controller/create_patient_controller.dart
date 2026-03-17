import 'package:dermascan/app/enums.dart';
import 'package:dermascan/core/models/patient.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreatePatientController extends GetxController {
  AuthService authService = Get.find<AuthService>();

  DBService dbService = Get.find<DBService>();

  Rx<bool> isLoading = false.obs;

  final ScrollController scrollController = ScrollController();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();

  final Rxn<Gender> selectedGender = Rxn<Gender>();

  List<Gender> get genderOptions => Gender.values;
  DateTime? dateOfBirth;

  Future<void> selectDate(BuildContext context) async {
    dateOfBirth = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (dateOfBirth != null) {
      birthdayController.text =
          '${dateOfBirth?.day}.${dateOfBirth?.month}.${dateOfBirth?.year}';
    }
  }

  Future<void> submitPatientData() async {
    if (selectedGender.value == null ||
        nameController.text.isEmpty ||
        dateOfBirth == null ||
        emailController.text.isEmpty) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Creation failed!',
          message: 'Please fill in all required fields!',
        ),
      );
      return;
    }

    isLoading.value = true;

    final Practice? practiceOfDoctor = await dbService.checkDoctorHasPractice();

    if (practiceOfDoctor == null) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Creation failed!',
          message: 'You are not assigned to a practice!',
        ),
      );
      isLoading.value = false;
      return;
    }

    final Patient? createdPatient = await dbService.createPatientProfile(
      name: nameController.text.trim(),
      gender: selectedGender.value!.name,
      dateOfBirth: dateOfBirth,
      email: emailController.text.trim(),
      practiceId: practiceOfDoctor.id,
    );

    if (createdPatient != null) {
      Get.back(result: createdPatient);
    } else {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Creation failed!',
          message: 'Please check the entered data and try again later!',
        ),
      );
    }

    isLoading.value = false;
  }
}
