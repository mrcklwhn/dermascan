import 'package:dermascan/app/enums.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class RegisterController extends GetxController {
  ScrollController scrollController = ScrollController();

  Rx<AuthOption> currentSelectedAuthOption = AuthOption.doctor.obs;

  Rx<bool> isLoading = false.obs;

  void changeCurrentSelectedAuthOption({required AuthOption newAuthOption}) {
    if (currentSelectedAuthOption.value != newAuthOption) {
      currentSelectedAuthOption.value = newAuthOption;
    }
  }

  Future<void> navigateBackToLogin() async {
    await Get.offNamed('/auth');
  }
}
