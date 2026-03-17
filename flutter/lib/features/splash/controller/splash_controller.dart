import 'package:dermascan/core/services/auth_service.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  AuthService authService = Get.find<AuthService>();

  @override
  Future<void> onReady() async {
    super.onReady();
    await authService.evaluateRouteAndNavigate();
  }
}
