import 'package:dermascan/app/enums.dart';
import 'package:get/get.dart';

class RegisterController extends GetxController {
  Rx<AuthOption> currentSelectedAuthOption = AuthOption.doctor.obs;

  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is Map) {
      final Map<dynamic, dynamic> args = Get.arguments as Map<dynamic, dynamic>;
      final int? initialTabIndex = args['initialTabIndex'] as int?;
      if (initialTabIndex == 0) {
        currentSelectedAuthOption.value = AuthOption.practice;
      } else if (initialTabIndex == 1) {
        currentSelectedAuthOption.value = AuthOption.doctor;
      }
    }
  }


}
