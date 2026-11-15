import 'package:dermascan/features/doctor/home/controller/home_controller.dart';
import 'package:dermascan/translations/tr_keys.dart';
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
          destinations: <NavigationDestination>[
            NavigationDestination(
              icon: const Icon(Icons.group_outlined),
              selectedIcon: const Icon(Icons.group),
              label: TrKeys.patient.patients.tr,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: TrKeys.doctor.profile.tr,
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
