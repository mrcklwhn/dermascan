import 'package:dermascan/features/doctor/init/controller/init_controller.dart';
import 'package:dermascan/features/doctor/init/controller/invitations_controller.dart';
import 'package:dermascan/features/doctor/init/controller/key_import_controller.dart';
import 'package:dermascan/features/doctor/init/controller/key_lock_controller.dart';
import 'package:get/get.dart';

class DoctorInitBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DoctorInitController());
    Get.lazyPut(() => InvitationsController());
    Get.lazyPut(() => KeyImportController());
    Get.lazyPut(() => KeyLockController());
  }
}
