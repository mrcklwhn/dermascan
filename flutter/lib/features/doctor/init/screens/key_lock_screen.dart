import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/features/doctor/init/controller/key_lock_controller.dart';
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
                  'Missing Encryption Key'.tr,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                Text(
                  'You have joined a practice, but this device does not have the encryption key required to view patient data. Please import the key by scanning the QR code from the practice administrator.'.tr,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                FilledButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: controller.scanQRCode,
                  label: Text('Scan QR Code'.tr),
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout),
                  onPressed: controller.logout,
                  label: Text('Logout'.tr),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}