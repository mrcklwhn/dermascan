import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/encryption_service.dart';
import 'package:get/get.dart';

class KeyLockController extends GetxController {
  final AuthService authService = Get.find<AuthService>();
  final EncryptionService encryptionService = Get.find<EncryptionService>();

  final RxBool isChecking = true.obs;

  @override
  void onInit() {
    super.onInit();
    checkKey();
  }

  Future<void> checkKey() async {
    isChecking.value = true;
    final Practice? practice = authService.currentPractice.value;
    if (practice != null) {
      final String? key = await encryptionService.getPracticeKey(practiceId: practice.id);
      if (key != null && encryptionService.isValidKeyFormat(base64Key: key)) {
        await Get.offAllNamed('/doctor/home');
        return;
      }
    }
    isChecking.value = false;
  }
  
  void logout() {
    authService.supabaseClient.auth.signOut();
  }

  Future<void> scanQRCode() async {
    final dynamic result = await Get.toNamed('/doctor/key-import');
    if (result == true) {
      await checkKey(); 
    }
  }
}