import 'package:dermascan/features/practice/home/controller/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PracticeHomeScreen extends StatelessWidget {
  final PracticeHomeController practiceHomeController =
      Get.find<PracticeHomeController>();

  PracticeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Obx(
        () => NavigationBar(
          onDestinationSelected: (int index) =>
              practiceHomeController.currentScreenIndex.value = index,
          selectedIndex: practiceHomeController.currentScreenIndex.value,
          destinations: <NavigationDestination>[
            NavigationDestination(
              icon: const Icon(Icons.group_outlined),
              selectedIcon: const Icon(Icons.group),
              label: 'Doctors'.tr,
            ),
            NavigationDestination(
              icon: const Icon(Icons.local_hospital_outlined),
              selectedIcon: const Icon(Icons.local_hospital),
              label: 'Profile'.tr,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          if (practiceHomeController.currentScreenIndex.value >=
              practiceHomeController.screens.length) {
            practiceHomeController.currentScreenIndex.value = 0;
          }
          return practiceHomeController.screens[practiceHomeController
              .currentScreenIndex
              .value];
        }),
      ),
    );
  }
}
