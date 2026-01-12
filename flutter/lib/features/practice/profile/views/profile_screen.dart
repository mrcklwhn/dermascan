import 'package:dermascan/features/practice/profile/controller/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PracticeProfileScreen extends StatelessWidget {
  PracticeProfileScreen({super.key});

  final PracticeProfileController practiceProfileController =
      Get.find<PracticeProfileController>();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: practiceProfileController.authService.signOut,
      icon: const Icon(Icons.exit_to_app),
    );
  }
}
