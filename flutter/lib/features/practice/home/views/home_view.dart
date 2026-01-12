import 'package:dermascan/features/practice/home/controller/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PracticeHomeScreen extends StatelessWidget {
  PracticeHomeScreen({super.key});

  final PracticeHomeController practiceHomeController =
      Get.find<PracticeHomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Obx(
        () => NavigationBar(
          onDestinationSelected: (int index) =>
              practiceHomeController.currentScreenIndex.value = index,
          selectedIndex: practiceHomeController.currentScreenIndex.value,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group),
              label: 'Doctors',
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
