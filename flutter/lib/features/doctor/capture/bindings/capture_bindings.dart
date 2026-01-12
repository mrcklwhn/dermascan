import 'package:dermascan/features/doctor/capture/controller/capture_controller.dart';
import 'package:get/get.dart';

class CaptureBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CaptureController());
  }
}
