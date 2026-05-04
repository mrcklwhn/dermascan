import 'dart:async';
import 'dart:io';

import 'package:dartcv4/dartcv.dart' as cv;
import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/app/enums.dart';
import 'package:dermascan/core/models/body_lesion.dart';
import 'package:dermascan/core/models/diagnosis.dart';
import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/models/patient.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/utils/lesion_analysis.dart';
import 'package:dermascan/core/widgets/custom_bottom_sheets/custom_capture_sheet.dart';
import 'package:dermascan/core/widgets/custom_bottom_sheets/custom_cutout_sheet.dart';
import 'package:dermascan/core/widgets/custom_bottom_sheets/custom_diagnosis_sheet.dart';
import 'package:dermascan/core/widgets/custom_dialog.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class DiagnosisController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  DBService dbService = Get.find<DBService>();

  final BodyLesion lesion;
  final Patient patient;

  DiagnosisController({required this.lesion, required this.patient});

  final Uuid uuid = const Uuid();
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;
  final ImagePicker picker = ImagePicker();
  final RxBool isLoading = true.obs;

  final Rx<DiagnosisProcessState> processState = DiagnosisProcessState.idle.obs;

  @override
  void onClose() {
    currentPage.value = 0;
    pageController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_initializeData());
  }

  Future<void> _initializeData() async {
    try {
      await drawOverlays();
      await fetchDoctorNames();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error while drawing overlays: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> drawOverlays() async {
    for (final Diagnosis diagnosis in lesion.diagnoses) {
      final Uint8List bytes = diagnosis.analyzedImages!['original']!;
      final cv.Mat mat = cv.imdecode(bytes, cv.IMREAD_COLOR);

      final LesionAnalysis lesion = LesionAnalysis(mat);
      await lesion.runLesionAnalysis(
        useNeuralModel: diagnosis.cutoutType == CutoutType.ml ? true : false,
      );

      diagnosis.analyzedImages?.addAll(<String, Uint8List>{
        'contour': cv.imencode('.png', lesion.getLesionContourOverlay()).$2,
        'concavity': cv.imencode('.png', lesion.getConcavityOverlay()).$2,
      });
    }
  }

  Future<void> fetchDoctorNames() async {
    for (final Diagnosis diagnosis in lesion.diagnoses) {
      final Doctor? doctor = await dbService.fetchDoctor(
        id: diagnosis.doctorId,
      );
      if (doctor == null) return;
      diagnosis.doctorName = doctor.name;
    }
  }

  Uint8List? cutoutML;
  Uint8List? cutoutAlgo;

  Diagnosis? draftDiagnosis;

  Future<void> selectImage(ImageSource source) async {
    try {
      final XFile? image = await picker.pickImage(source: source);
      if (image == null) return;

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),

        uiSettings: <PlatformUiSettings>[
          AndroidUiSettings(
            toolbarTitle: 'Crop Lesion',
            initAspectRatio: CropAspectRatioPreset.square,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: 'Crop Lesion',
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
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'No Practice Assigned',
            message:
                'You must be assigned to a practice to create a diagnosis.',
          ),
        );
        return;
      }

      final String currentDiagnosisId = uuid.v4();
      final String storagePath =
          '$practiceId/${patient.id}/$currentDiagnosisId.jpg';

      final String? imagePath = await dbService.uploadFile(
        bucket: 'lesion_images',
        storagePath: storagePath,
        file: File(croppedFile.path),
        mimeType: 'image/jpg',
      );

      if (imagePath == null) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Upload Failed',
            message:
                'Could not upload your Image. Please check your connection and try again.',
          ),
        );
        return;
      }

      draftDiagnosis = Diagnosis(
        doctorId: authService.currentDoctor.value!.id,
        doctorName: authService.currentDoctor.value!.name,
        lesionId: lesion.id,
        id: currentDiagnosisId,
        date: DateTime.now(),
        imagePath: imagePath,
        analyzedImages: <String, Uint8List?>{'original': bytes},
      );

      await generateCutouts(diagnosis: draftDiagnosis!);
    } catch (e) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Image Error',
          message: 'Could not select image. Please try again later.',
        ),
      );
      return;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> generateCutouts({required Diagnosis diagnosis}) async {
    try {
      isLoading.value = true;

      final Uint8List bytes = diagnosis.analyzedImages!['original']!;
      final cv.Mat mat = cv.imdecode(bytes, cv.IMREAD_COLOR);

      final LesionAnalysis lesionML = LesionAnalysis(mat);
      final LesionAnalysis lesionAlgo = LesionAnalysis(mat);
      await lesionML.runLesionAnalysis(useNeuralModel: true);
      await lesionAlgo.runLesionAnalysis(useNeuralModel: false);

      cutoutML = cv.imencode('.png', lesionML.getLesionContourOverlay()).$2;
      cutoutAlgo = cv.imencode('.png', lesionAlgo.getLesionContourOverlay()).$2;

      processState.value = DiagnosisProcessState.drafting;

      await pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: Could not create lesion cutout.');
      }
      return;
    } finally {
      isLoading.value = false;
    }
  }

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

      draftDiagnosis = null;
      processState.value = DiagnosisProcessState.idle;
      lesion.diagnoses.insert(0, diagnosis);

      await pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
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
      modelType: 'Gabor',
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
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'No Practice Assigned',
            message:
                'You must be assigned to a practice to create new patient profiles.',
          ),
        );
        return null;
      }

      final String storagePath =
          '$practiceId/${patient.id}/${diagnosis.id}.jpg';

      await dbService.deleteFile(
        bucket: 'lesion_images',
        storagePath: storagePath,
      );
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Diagnosis Failed',
          message:
              'Could not create Diagnosis, you may be not assigned to a practice.',
        ),
      );
      return null;
    }

    return newDiagnosis;
  }

  Future<void> deleteDiagnosis({required Diagnosis diagnosis}) async {
    if (isLoading.value) return;

    if (authService.currentDoctor.value == null) return;

    final String? doctorId = authService.currentUser.value?.id;

    if (doctorId == null) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Authentication Error',
          message: 'You are not signed in correctly. Please log in again.',
        ),
      );
      return;
    }

    final String? diagnosisId = diagnosis.id;

    if (diagnosisId == null) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Diagnosis Error',
          message: 'No diagnosis is currently selected. Please try again.',
        ),
      );
      return;
    }

    isLoading.value = true;

    try {
      final bool successDiagnosis = await dbService.deleteDiagnosis(
        diagnosisId: diagnosisId,
      );

      if (Get.isDialogOpen ?? false) Get.back();
      if (successDiagnosis) {
        final List<String> segments = diagnosis.imagePath.split('/');
        final String bucket = segments[0];
        final String storagePath = segments.sublist(1).join('/');
        final bool successImage = await dbService.deleteFile(
          bucket: bucket,
          storagePath: storagePath,
        );
        if (successImage) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check,
              title: 'Diagnosis Deleted',
              message: 'The Diagnosis has been deleted.',
            ),
          );
          await pageController.animateToPage(
            currentPage.value - 1,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );

          lesion.diagnoses.removeWhere(
            (Diagnosis diagnosis) => diagnosis.id == diagnosisId,
          );
        } else {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'Error Deleting Image',
              message:
                  'The Image could not be deleted. It may already be deleted.',
            ),
          );
        }
      } else {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Error Deleting Diagnosis',
            message:
                'The Diagnosis could not be deleted. It may already be deleted.',
          ),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> showDeleteDiagnosisDialog({required Diagnosis diagnosis}) async {
    if (isLoading.value) return;

    await Get.dialog(
      Obx(
        () => CustomDialog(
          title: 'Delete Diagnosis?',
          subtitle:
              'You are about to delete this diagnosis. This will delete all Information including the images. Do you want to continue?',
          isDismissable: true,
          onSubmit: isLoading.value
              ? null
              : () async => await deleteDiagnosis(diagnosis: diagnosis),
          submitText: 'Delete',
        ),
      ),
    );
  }

  Future<void> changeLesionState({
    required BodyLesion lesion,
    required bool suspicious,
  }) async {
    if (isLoading.value) return;

    if (authService.currentDoctor.value == null) return;

    final String? doctorId = authService.currentUser.value?.id;

    if (doctorId == null) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Authentication Error',
          message: 'You are not signed in correctly. Please log in again.',
        ),
      );
      return;
    }

    isLoading.value = true;
    try {
      final bool successful = await dbService.updateLesion(
        lesionId: lesion.id,
        suspicious: suspicious,
      );

      if (successful) {
        lesion.isSuspicious.value = suspicious;
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.check,
            title: 'Updated Lesion',
            message: suspicious
                ? 'The Lesion has been marked as suspicious.'
                : 'The Lesion has been marked as not suspicious.',
          ),
        );
      } else {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Error Updating Lesion',
            message: 'The Lesion could not be updated.',
          ),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}

class DiagnosisBottomSheet extends StatelessWidget {
  final Patient patient;
  final BodyLesion lesion;

  const DiagnosisBottomSheet({
    super.key,
    required this.lesion,
    required this.patient,
  });

  @override
  Widget build(BuildContext context) {
    final DiagnosisController controller = Get.put<DiagnosisController>(
      DiagnosisController(lesion: lesion, patient: patient),
      tag: lesion.id,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Obx(() {
          if (controller.lesion.diagnoses.isNotEmpty) {
            return Padding(
              padding: AppTheme.scaffoldPadding,
              child: Card(
                child: ListTile(
                  title: const Text('Suspicious Lesion'),
                  trailing: controller.isLoading.value
                      ? const CircularProgressIndicator.adaptive()
                      : Checkbox(
                          value: controller.lesion.isSuspicious.value,
                          onChanged: controller.isLoading.value
                              ? null
                              : (bool? value) {
                                  if (value != null) {
                                    controller.changeLesionState(
                                      lesion: controller.lesion,
                                      suspicious: value,
                                    );
                                  }
                                },
                        ),
                ),
              ),
            );
          }
          return const Center();
        }),
        Obx(() {
          final DiagnosisProcessState currentState =
              controller.processState.value;
          final int pageCount =
              (currentState == DiagnosisProcessState.drafting ? 2 : 1) +
              controller.lesion.diagnoses.length;

          double currentHeight() {
            if (controller.currentPage.value == 0) {
              return 250.0;
            }
            if (currentState == DiagnosisProcessState.drafting &&
                controller.currentPage.value == 1) {
              return 250.0;
            }
            return MediaQuery.sizeOf(context).height * 0.70;
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: currentHeight(),
            decoration: const BoxDecoration(
              color: AppTheme.highlightColor,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLarge),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: AppTheme.spaceMedium,
                  ),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSecondaryFixedVariant
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: controller.pageController,
                    onPageChanged: (int index) =>
                        controller.currentPage.value = index,
                    itemCount: pageCount,
                    itemBuilder: (BuildContext context, int index) {
                      if (index == 0) {
                        return CustomCaptureSheet(controller: controller);
                      }

                      if (currentState == DiagnosisProcessState.drafting) {
                        if (index == 1) {
                          return CustomCutoutSheet(
                            controller: controller,
                            diagnosis: controller.draftDiagnosis!,
                          );
                        }
                        return CustomDiagnosisSheet(
                          diagnosis: controller.lesion.diagnoses[index - 2],
                          controller: controller,
                        );
                      } else {
                        return CustomDiagnosisSheet(
                          diagnosis: controller.lesion.diagnoses[index - 1],
                          controller: controller,
                        );
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spaceMedium,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(pageCount, (int index) {
                      return AnimatedContainer(
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceSmall / 2,
                        ),
                        duration: const Duration(milliseconds: 200),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: controller.currentPage.value == index
                              ? AppTheme.primary
                              : AppTheme.scaffoldBg,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
