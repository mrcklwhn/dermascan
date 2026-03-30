import 'package:dermascan/app/enums.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterController extends GetxController {
  ScrollController scrollController = ScrollController();

  Rx<AuthOption> currentSelectedAuthOption = AuthOption.doctor.obs;

  RxBool isLoading = false.obs;

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void changeCurrentSelectedAuthOption({required AuthOption newAuthOption}) {
    if (currentSelectedAuthOption.value != newAuthOption) {
      currentSelectedAuthOption.value = newAuthOption;
    }
  }

  Future<void> navigateBackToLogin() async {
    if (isLoading.value) return;

    await Get.toNamed('/auth/login');
  }
}
