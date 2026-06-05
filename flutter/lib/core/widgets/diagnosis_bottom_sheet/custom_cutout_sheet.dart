import 'dart:async';

import 'package:dartcv4/dartcv.dart' as cv;
import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/app/enums.dart';
import 'package:dermascan/core/models/diagnosis.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/utils/lesion_analysis.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:dermascan/core/widgets/diagnosis_bottom_sheet/diagnosis_bottom_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CutoutController extends GetxController {
  final DiagnosisMainController mainController;
  AuthService authService = Get.find<AuthService>();
  DBService dbService = Get.find<DBService>();

  final RxBool isLoading = false.obs;

  CutoutController({required this.mainController});

  Future<void> startDiagnosisPipeline({
    required Diagnosis diagnosis,
    required CutoutType type,
  }) async {
    try {
      isLoading.value = true;

      diagnosis = await calculateScoresAndDrawOverlay(
        diagnosis: diagnosis,
        type: type,
      );

      final Diagnosis? uploadedDiagnosis = await uploadDiagnosis(
        diagnosis: diagnosis,
      );

      if (uploadedDiagnosis == null) return;

      mainController.draftDiagnosis = null;
      mainController.processState.value = DiagnosisProcessState.idle;
      mainController.registerChildControllers(diagnosis: diagnosis);
      mainController.lesion.diagnoses.insert(0, diagnosis);
      mainController.animateToPage(1);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: Could not finish diagnosis pipeline.');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<Diagnosis> calculateScoresAndDrawOverlay({
    required Diagnosis diagnosis,
    required CutoutType type,
  }) async {
    final Uint8List bytes = diagnosis.analyzedImages!['original']!;
    final cv.Mat mat = cv.imdecode(bytes, cv.IMREAD_COLOR);

    final LesionAnalysis lesion = LesionAnalysis(mat);
    await lesion.runLesionAnalysis(
      useNeuralModel: type == CutoutType.ml ? true : false,
      onlyMask: false,
    );

    diagnosis.aScore = lesion.getAsymmetryScore();
    diagnosis.bScore = lesion.getBorderScore();
    diagnosis.cScore = lesion.getColorUniformityScore();
    diagnosis.cutoutType = type;

    diagnosis.analyzedImages?.addAll(<String, Uint8List>{
      'contour': cv.imencode('.png', lesion.getLesionContourOverlay()).$2,
      'concavity': cv.imencode('.png', lesion.getConcavityOverlay()).$2,
    });

    if (lesion.labelText != null) {
      diagnosis.confidence = lesion.labelConfidence?.toPrecision(2);
      diagnosis.prediction = LesionType.values[lesion.labelIdx!];
    }

    return diagnosis;
  }

  Future<Diagnosis?> uploadDiagnosis({required Diagnosis diagnosis}) async {
    final Diagnosis? newDiagnosis = await dbService.createDiagnosis(
      diagnosis: diagnosis,
    );

    if (newDiagnosis == null) {
      final String? practiceId = authService.currentDoctor.value?.practiceId;

      if (practiceId == null) {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'No Practice Assigned',
              message:
                  'You must be assigned to a practice to create new patient profiles.',
            ),
          );
        }
        return null;
      }

      final String storagePath =
          '$practiceId/${mainController.patient.id}/${diagnosis.id}.jpg';

      await dbService.deleteFile(
        bucket: 'lesion_images',
        storagePath: storagePath,
      );
      if (!Get.isSnackbarOpen) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Diagnosis Failed',
            message:
                'Could not create Diagnosis, you may be not assigned to a practice.',
          ),
        );
      }
      return null;
    }

    return newDiagnosis;
  }
}

class CustomCutoutSheet extends StatelessWidget {
  final Diagnosis diagnosis;
  final DiagnosisMainController mainController;

  const CustomCutoutSheet({
    super.key,
    required this.diagnosis,
    required this.mainController,
  });

  @override
  Widget build(BuildContext context) {
    final CutoutController controller = Get.find<CutoutController>();

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator.adaptive());
      }
      return Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            if (mainController.cutoutML != null)
              _buildSelectorButton(
                context: context,
                image: mainController.cutoutML!,
                onPressed: () async => controller.startDiagnosisPipeline(
                  diagnosis: diagnosis,
                  type: CutoutType.ml,
                ),
              ),
            if (mainController.cutoutAlgo != null)
              _buildSelectorButton(
                context: context,
                image: mainController.cutoutAlgo!,
                onPressed: () async => controller.startDiagnosisPipeline(
                  diagnosis: diagnosis,
                  type: CutoutType.algorithmic,
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildSelectorButton({
    required BuildContext context,
    required Uint8List image,
    required VoidCallback onPressed,
  }) {
    final double size =
        (MediaQuery.of(context).size.width - AppTheme.spaceMedium * 3) / 2;
    return FilledButton(
      style: FilledButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: AppTheme.scaffoldBg,
        foregroundColor: AppTheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        fixedSize: Size(size, size),
      ),
      onPressed: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Image.memory(
          image,
          height: size,
          width: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
