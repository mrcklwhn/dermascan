import 'dart:async';
import 'dart:io';

import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/models/diagnosis.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service/lesion_db_service.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:dermascan/core/widgets/diagnosis_bottom_sheet/diagnosis_bottom_sheet.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class CaptureController extends GetxController {
  final DiagnosisMainController mainController;
  AuthService authService = Get.find<AuthService>();
  LesionDbService lesionDbService = Get.find<LesionDbService>();

  final ImagePicker picker = ImagePicker();
  final RxBool isLoading = false.obs;
  final Uuid uuid = const Uuid();

  CaptureController({required this.mainController});

  Future<void> selectImage(ImageSource source) async {
    try {
      final XFile? image = await picker.pickImage(source: source);
      if (image == null) return;

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: <PlatformUiSettings>[
          AndroidUiSettings(
            toolbarTitle: TrKeys.lesion.cropLesion.tr,
            initAspectRatio: CropAspectRatioPreset.square,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: TrKeys.lesion.cropLesion.tr,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );

      if (croppedFile == null) return;

      final Uint8List bytes = await croppedFile.readAsBytes();

      isLoading.value = true;

      final String? practiceId = authService.currentDoctor.value?.practiceId;

      if (practiceId == null) {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: TrKeys.practice.noPracticeAssigned.tr,
              message: TrKeys.practice.notAssignedToPracticeMsg.tr,
            ),
          );
        }
        return;
      }

      final String currentDiagnosisId = uuid.v4();
      final String storagePath =
          '$practiceId/${mainController.patient.id}/$currentDiagnosisId.jpg';

      final String? imagePath = await lesionDbService.uploadFile(
        bucket: 'lesion_images',
        storagePath: storagePath,
        file: File(croppedFile.path),
        mimeType: 'image/jpg',
      );

      if (imagePath == null) {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: TrKeys.lesion.uploadFailed.tr,
              message: TrKeys.lesion.imageUploadFailed.tr,
            ),
          );
        }
        return;
      }

      await startDiagnosisPipeline(
        id: currentDiagnosisId,
        imagePath: imagePath,
        image: bytes,
      );
    } catch (e) {
      if (!Get.isSnackbarOpen) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: TrKeys.lesion.imageError.tr,
            message: TrKeys.lesion.couldNotSelectImage.tr,
          ),
        );
      }
      return;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> startDiagnosisPipeline({
    required String id,
    required String imagePath,
    required Uint8List image,
  }) async {
    try {
      final Diagnosis diagnosis = Diagnosis(
        id: id,
        notes: '',
        date: DateTime.now(),
        imagePath: imagePath,
        lesionId: mainController.lesion.id,
        doctorId: authService.currentDoctor.value!.id,
        image: image,
        doctorName: authService.currentDoctor.value!.name,
      );

      final Diagnosis? uploadedDiagnosis = await uploadDiagnosis(
        diagnosis: diagnosis,
      );

      if (uploadedDiagnosis == null) return;
      mainController.registerChildControllers(diagnosis: diagnosis);
      mainController.lesion.diagnoses.insert(0, diagnosis);
      mainController.animateToPage(1);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: Could not finish diagnosis pipeline.');
      }
    }
  }

  Future<Diagnosis?> uploadDiagnosis({required Diagnosis diagnosis}) async {
    final Diagnosis? newDiagnosis = await lesionDbService.createDiagnosis(
      diagnosis: diagnosis,
    );

    if (newDiagnosis == null) {
      final String? practiceId = authService.currentDoctor.value?.practiceId;

      if (practiceId == null) {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: TrKeys.practice.noPracticeAssigned.tr,
              message: TrKeys.practice.notAssignedToPracticeMsg.tr,
            ),
          );
        }
        return null;
      }

      final String storagePath =
          '$practiceId/${mainController.patient.id}/${diagnosis.id}.jpg';

      await lesionDbService.deleteFile(
        bucket: 'lesion_images',
        storagePath: storagePath,
      );
      if (!Get.isSnackbarOpen) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: TrKeys.diagnosis.diagnosisFailed.tr,
            message: TrKeys.diagnosis.diagnosisCreationFailedMsg.tr,
          ),
        );
      }
      return null;
    }

    return newDiagnosis;
  }
}

class CustomCaptureSheet extends StatelessWidget {
  final DiagnosisMainController mainController;

  const CustomCaptureSheet({super.key, required this.mainController});

  @override
  Widget build(BuildContext context) {
    final CaptureController controller = Get.find<CaptureController>();

    return Obx(() {
      if (mainController.isLoading.value || controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator.adaptive());
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceLarge),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _buildActionButton(
              context: context,
              icon: Icons.camera_enhance,
              label: TrKeys.lesion.camera.tr,
              onPressed: () => controller.selectImage(ImageSource.camera),
            ),
            _buildActionButton(
              context: context,
              icon: Icons.photo_library,
              label: TrKeys.lesion.gallery.tr,
              onPressed: () => controller.selectImage(ImageSource.gallery),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final double size =
        (MediaQuery.of(context).size.width - AppTheme.spaceMedium * 3) / 2;
    return FilledButton(
      style: FilledButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        fixedSize: Size(size, size),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            icon,
            size: size / 3,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
