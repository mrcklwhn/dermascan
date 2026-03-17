import 'package:dermascan/app/enums.dart';
import 'package:dermascan/features/auth/screens/register/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  ScrollController scrollController = ScrollController();

  Rx<AuthOption> currentSelectedAuthOption = AuthOption.doctor.obs;

  Rx<bool> isLoading = false.obs;

  void changeCurrentSelectedAuthOption({required AuthOption newAuthOption}) {
    if (currentSelectedAuthOption.value != newAuthOption) {
      currentSelectedAuthOption.value = newAuthOption;
    }
  }

  Future<void> navigateToRegister() async {
    await Get.to(() => RegisterScreen());
  }
}
