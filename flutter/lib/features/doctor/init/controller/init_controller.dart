import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/widgets/custom_dialog.dart';
import 'package:get/get.dart';

class DoctorInitController extends GetxController {
  AuthService authService = Get.find<AuthService>();

  Future<void> openInvitationsScreen() async {
    await Get.toNamed('/doctor/invitations');
  }

  Future<void> showLogoutDialog() async {
    await Get.dialog(const CustomLogoutDialog());
  }
}
