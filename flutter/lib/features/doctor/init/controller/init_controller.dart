import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/widgets/custom_dialog.dart';
import 'package:get/get.dart';

class DoctorInitController extends GetxController {
  AuthService authService = Get.find<AuthService>();

  Future<void> openInvitationsScreen() async {
    await Get.toNamed('/doctor/invitations');
  }

  Future<void> showLogoutDialog() async {
    await CustomDialogHelper.show(
      routeName: 'logout-dialog',

      title: 'Logout?',

      subtitle:
          'You are about to log out of your account. Are you sure you want to proceed?',

      isDismissable: true,

      submitText: 'Logout',

      onSubmit: (_) async {
        await authService.signOut();
      },
    );
  }
}
