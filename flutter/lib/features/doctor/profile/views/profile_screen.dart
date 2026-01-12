import 'package:dermascan/features/doctor/profile/controller/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorProfileScreen extends StatelessWidget {
  DoctorProfileScreen({super.key});

  final DoctorProfileController doctorProfileController =
      Get.find<DoctorProfileController>();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: doctorProfileController.authService.signOut,
      icon: const Icon(Icons.exit_to_app),
    );
  }
}
