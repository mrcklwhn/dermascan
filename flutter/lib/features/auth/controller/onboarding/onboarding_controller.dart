import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingController extends GetxController {
  void openRoleSelection({required bool isPractice}) {
    Get.bottomSheet(
      _RoleSelectionSheet(
        isPractice: isPractice,
        controller: this,
      ),
    );
  }

  void navigateToLogin() {
    if (Get.isBottomSheetOpen ?? false) {
      Get.back();
    }
    Get.toNamed('/auth/login');
  }

  void navigateToRegister({required bool isPractice}) {
    if (Get.isBottomSheetOpen ?? false) {
      Get.back();
    }
    Get.toNamed(
      '/auth/register',
      arguments: <String, int>{'initialTabIndex': isPractice ? 0 : 1},
    );
  }
}

class _RoleSelectionSheet extends StatelessWidget {
  final bool isPractice;
  final OnboardingController controller;

  const _RoleSelectionSheet({
    required this.isPractice,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            isPractice ? 'practice_options'.tr : 'doctor_options'.tr,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.login),
            onPressed: controller.navigateToLogin,
            label: Text('Login'.tr),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.app_registration),
            onPressed: () => controller.navigateToRegister(isPractice: isPractice),
            label: Text('Register'.tr),
          ),
        ],
      ),
    );
  }
}
