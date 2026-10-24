import 'package:dermascan/features/doctor/init/controller/key_import_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class KeyImportScreen extends GetView<KeyImportController> {
  const KeyImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Import Practice Key'.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(result: false),
        ),
      ),
      body: Stack(
        children: <Widget>[
          MobileScanner(
            controller: controller.scannerController,
            onDetect: controller.onDetect,
          ),
          Obx(() => controller.isProcessing.value
              ? const ColoredBox(
                  color: Colors.black54,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : const SizedBox.shrink()),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Scan the QR Code provided by the practice administrator to access patient data.'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          )
        ],
      ),
    );
  }
}
