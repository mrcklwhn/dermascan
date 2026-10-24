import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/features/doctor/init/controller/key_lock_controller.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class KeyLockScreen extends GetView<KeyLockController> {
  const KeyLockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isChecking.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SafeArea(
          child: Padding(
            padding: AppTheme.scaffoldPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Spacer(),
                const CustomIcon(
                  iconData: Icons.lock,
                ),
                const SizedBox(height: AppTheme.spaceLarge),
                Text(
                  TrKeys.practice.missingEncryptionKey.tr,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                Text(
                  TrKeys.practice.missingKeyMsg.tr,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                FilledButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: controller.scanQRCode,
                  label: Text(TrKeys.practice.scanQrCode.tr),
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout),
                  onPressed: controller.logout,
                  label: Text(TrKeys.common.logout.tr),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
