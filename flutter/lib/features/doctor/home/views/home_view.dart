import 'package:dermascan/features/doctor/home/controller/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorHomeScreen extends StatelessWidget {
  DoctorHomeScreen({super.key});

  final DoctorHomeController doctorHomeController =
      Get.find<DoctorHomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Obx(
        () => NavigationBar(
          onDestinationSelected: (int index) =>
              doctorHomeController.currentScreenIndex.value = index,
          selectedIndex: doctorHomeController.currentScreenIndex.value,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group),
              label: 'Patients',
            ),
            NavigationDestination(
              icon: Icon(Icons.camera_enhance_outlined),
              selectedIcon: Icon(Icons.camera_enhance),
              label: 'Capture',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          if (doctorHomeController.currentScreenIndex.value >=
              doctorHomeController.screens.length) {
            doctorHomeController.currentScreenIndex.value = 0;
          }
          return doctorHomeController.screens[doctorHomeController
              .currentScreenIndex
              .value];
        }),
      ),
    );
  }
}
