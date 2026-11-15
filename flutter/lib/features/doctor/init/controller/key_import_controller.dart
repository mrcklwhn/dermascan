import 'dart:convert';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/encryption_service.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class KeyImportController extends GetxController {
  final MobileScannerController scannerController = MobileScannerController();
  final AuthService authService = Get.find<AuthService>();
  final EncryptionService encryptionService = Get.find<EncryptionService>();
  
  final RxBool isProcessing = false.obs;

  @override
  void onClose() {
    scannerController.dispose();
    super.onClose();
  }

  Future<void> onDetect(BarcodeCapture capture) async {
    if (isProcessing.value) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final Barcode barcode in barcodes) {
      if (barcode.rawValue != null) {
        isProcessing.value = true;
        await processKeyData(data: barcode.rawValue!);
        isProcessing.value = false;
      }
    }
  }

  Future<void> processKeyData({required String data}) async {
    try {
      final Map<String, dynamic> json = jsonDecode(data);
      final String? practiceId = json['practice_id'];
      final String? key = json['key'];

      if (practiceId == null || key == null) {
        _showError(message: TrKeys.practice.invalidQrFormat.tr);
        return;
      }

      final Practice? currentPractice = authService.currentPractice.value;
      if (currentPractice == null || currentPractice.id != practiceId) {
        _showError(message: TrKeys.practice.keyBelongsToDifferentPractice.tr);
        return;
      }

      if (!encryptionService.isValidKeyFormat(base64Key: key)) {
        _showError(message: TrKeys.practice.scannedKeyNotValid.tr);
        return;
      }

      if (!encryptionService.verifyKey(keyVerifier: currentPractice.keyVerifier, base64Key: key)) {
        _showError(message: TrKeys.practice.scannedKeyMismatch.tr);
        return;
      }

      await encryptionService.savePracticeKey(practiceId: practiceId, base64Key: key);
      Get.back(result: true); 
    } catch (e) {
      _showError(message: TrKeys.practice.couldNotProcessQrCode.tr);
    }
  }

  void _showError({required String message}) {
    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        TrKeys.common.error.tr,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Theme.of(Get.context!).colorScheme.error,
        colorText: Theme.of(Get.context!).colorScheme.onError,
      );
    }
    Future<void>.delayed(const Duration(seconds: 3), () {
      isProcessing.value = false;
    });
  }
}
