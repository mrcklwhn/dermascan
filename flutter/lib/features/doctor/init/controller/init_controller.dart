import 'package:dermascan/core/services/auth_service.dart';
import 'package:get/get.dart';

class DoctorInitController extends GetxController {
  AuthService authService = Get.find<AuthService>();

  Future<void> showInvitations() async {
    await Get.toNamed('/doctor/invitations');
  }
}
