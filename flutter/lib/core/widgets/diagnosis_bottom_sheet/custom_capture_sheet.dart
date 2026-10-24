import 'dart:async';
import 'dart:io';

import 'package:dartcv4/dartcv.dart' as cv;
import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/enums.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service/lesion_db_service.dart';
import 'package:dermascan/core/utils/lesion_analysis.dart';
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
              message:
                  TrKeys.practice.notAssignedToPracticeMsg
                      .tr,
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

      mainController.draftId = currentDiagnosisId;
      mainController.draftImagePath = imagePath;
      mainController.draftAnalyzedImages = <String, Uint8List?>{
        'original': bytes,
      };

      await generateCutouts();
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

  Future<void> generateCutouts() async {
    try {
      isLoading.value = true;

      final Uint8List bytes = mainController.draftAnalyzedImages!['original']!;
      final cv.Mat mat = cv.imdecode(bytes, cv.IMREAD_COLOR);

      final LesionAnalysis lesionML = LesionAnalysis(mat);
      final LesionAnalysis lesionAlgo = LesionAnalysis(mat);
      await lesionML.runLesionAnalysis(useNeuralModel: true);
      await lesionAlgo.runLesionAnalysis(useNeuralModel: false);

      mainController.cutoutML = cv
          .imencode('.png', lesionML.getLesionContourOverlay())
          .$2;
      mainController.cutoutAlgo = cv
          .imencode('.png', lesionAlgo.getLesionContourOverlay())
          .$2;

      mainController.processState.value = DiagnosisProcessState.cutout;
      mainController.animateToPage(1);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: Could not create lesion cutout.');
      }
      return;
    } finally {
      isLoading.value = false;
    }
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

      return Center(
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          Icon(icon, size: size / 3, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
