import 'package:dermascan/features/auth/controller/change_mail_controller.dart';
import 'package:dermascan/features/auth/controller/change_password_controller.dart';
import 'package:dermascan/features/auth/controller/login/login_controller.dart';
import 'package:dermascan/features/auth/controller/onboarding/onboarding_controller.dart';
import 'package:dermascan/features/auth/controller/register/doctor_register_controller.dart';
import 'package:dermascan/features/auth/controller/register/practice_register_controller.dart';
import 'package:dermascan/features/auth/controller/register/register_controller.dart';
import 'package:get/get.dart';

class AuthBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => OnboardingController());
    Get.lazyPut(() => LoginController());

    Get.lazyPut(() => RegisterController());
    Get.lazyPut(() => DoctorRegisterController(Get.find<RegisterController>()));
    Get.lazyPut(
      () => PracticeRegisterController(Get.find<RegisterController>()),
    );

    Get.lazyPut(() => ChangeEmailController());
    Get.lazyPut(() => ChangePasswordController());
  }
}
