import 'package:dermascan/features/doctor/home/controller/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorHomeScreen extends GetView<DoctorHomeController> {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Obx(
        () => NavigationBar(
          onDestinationSelected: (int index) =>
              controller.currentScreenIndex.value = index,
          selectedIndex: controller.currentScreenIndex.value,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group),
              label: 'Patients',
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
        child: Obx(
          () => IndexedStack(
            index: controller.currentScreenIndex.value,
            children: controller.screens,
          ),
        ),
      ),
    );
  }
}
