import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/translations/tr_keys.dart';
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            isPractice ? TrKeys.onboarding.practiceOptions.tr : TrKeys.onboarding.doctorOptions.tr,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          ElevatedButton.icon(
            icon: const Icon(Icons.login),
            onPressed: controller.navigateToLogin,
            label: Text(TrKeys.auth.login.tr),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          FilledButton.icon(
            icon: const Icon(Icons.app_registration),
            onPressed: () => controller.navigateToRegister(isPractice: isPractice),
            label: Text(TrKeys.auth.register.tr),
          ),
        ],
      ),
    );
  }
}
