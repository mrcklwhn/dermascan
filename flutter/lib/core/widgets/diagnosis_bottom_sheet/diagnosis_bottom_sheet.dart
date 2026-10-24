import 'dart:async';

import 'package:dartcv4/dartcv.dart' as cv;
import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/enums.dart';
import 'package:dermascan/core/models/body_lesion.dart';
import 'package:dermascan/core/models/diagnosis.dart';
import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/models/patient.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service/doctor_db_service.dart';
import 'package:dermascan/core/utils/lesion_analysis.dart';
import 'package:dermascan/core/widgets/diagnosis_bottom_sheet/custom_capture_sheet.dart';
import 'package:dermascan/core/widgets/diagnosis_bottom_sheet/custom_cutout_sheet.dart';
import 'package:dermascan/core/widgets/diagnosis_bottom_sheet/custom_diagnosis_details_sheet.dart';
import 'package:dermascan/core/widgets/diagnosis_bottom_sheet/removed_lesion_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DiagnosisMainController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  DoctorDbService doctorDbService = Get.find<DoctorDbService>();

  final BodyLesion lesion;
  final Patient patient;
  final String? selectedDiagnosisId;

  DiagnosisMainController({
    required this.lesion,
    required this.patient,
    this.selectedDiagnosisId,
  });

  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;
  final RxBool isLoading = true.obs;
  final Rx<DiagnosisProcessState> processState = DiagnosisProcessState.idle.obs;

  //Draft Diagnosis values
  String? draftId;
  String? draftImagePath;
  CutoutType? draftCutoutType;
  double? draftAScore;
  double? draftBScore;
  double? draftCScore;
  Map<String, Uint8List?>? draftAnalyzedImages;

  Uint8List? cutoutML;
  Uint8List? cutoutAlgo;

  @override
  void onClose() {
    disposeChildControllers();
    currentPage.value = 0;
    pageController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    registerChildControllers(diagnosis: null);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeData();
      navigateToSelectedDiagnosis(selectedDiagnosisId);
    });
  }

  Future<void> _initializeData() async {
    try {
      await fetchDoctorNames();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error while initializing data: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  void disposeChildControllers() {
    Get.delete<CaptureController>();
    Get.delete<CutoutController>();
    for (final Diagnosis diagnosis in lesion.diagnoses) {
      Get.delete<DiagnosisDetailController>(tag: diagnosis.id);
    }
  }

  void registerChildControllers({required Diagnosis? diagnosis}) {
    if (diagnosis == null) {
      Get.put(CaptureController(mainController: this));
      Get.put(CutoutController(mainController: this));
      for (final Diagnosis diagnosis in lesion.diagnoses) {
        Get.put(
          DiagnosisDetailController(diagnosis: diagnosis, mainController: this),
          tag: diagnosis.id,
        );
      }
    } else if (!Get.isRegistered<DiagnosisDetailController>(
      tag: diagnosis.id,
    )) {
      Get.put(
        DiagnosisDetailController(diagnosis: diagnosis, mainController: this),
        tag: diagnosis.id,
      );
    }
  }

  void navigateToSelectedDiagnosis(String? selectedDiagnosisId) {
    if (selectedDiagnosisId == null) return;
    final Diagnosis? selectedDiagnosis = lesion.diagnoses.firstWhereOrNull(
      (Diagnosis diagnosis) => diagnosis.id == selectedDiagnosisId,
    );
    if (selectedDiagnosis == null) return;
    final int index = lesion.diagnoses.indexOf(selectedDiagnosis);
    pageController.animateToPage(
      index + 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void animateToPage(int index) {
    if (pageController.hasClients) {
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> drawOverlaysForDiagnosis(Diagnosis diagnosis) async {
    final Map<String, Uint8List?>? images = diagnosis.analyzedImages;
    if (images == null || images['original'] == null) {
      return;
    }

    if (images.containsKey('contour') && images.containsKey('concavity')) {
      return;
    }

    try {
      final Uint8List bytes = images['original']!;
      if (bytes.isEmpty) return;

      final cv.Mat mat = cv.imdecode(bytes, cv.IMREAD_COLOR);
      if (mat.isEmpty) return;

      final LesionAnalysis lesionAnalysis = LesionAnalysis(mat);
      await lesionAnalysis.runLesionAnalysis(
        useNeuralModel: diagnosis.cutoutType == CutoutType.ml
      );

      final Uint8List contour =
          cv.imencode('.png', lesionAnalysis.getLesionContourOverlay()).$2;
      final Uint8List concavity =
          cv.imencode('.png', lesionAnalysis.getConcavityOverlay()).$2;

      images['contour'] = contour;
      images['concavity'] = concavity;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error drawing overlay: $e');
      }
    }
    lesion.diagnoses.refresh();
  }

  Future<void> fetchDoctorNames() async {
    for (final Diagnosis diagnosis in lesion.diagnoses) {
      final Doctor? doctor = await doctorDbService.fetchDoctor(
        id: diagnosis.doctorId,
      );
      if (doctor == null) return;
      diagnosis.doctorName = doctor.name;
    }
    lesion.diagnoses.refresh();
  }
}

class DiagnosisBottomSheet extends StatelessWidget {
  final Patient patient;
  final BodyLesion lesion;
  final String? selectedDiagnosisId;
  final Function() openEditLesionPage;

  const DiagnosisBottomSheet({
    super.key,
    required this.lesion,
    required this.patient,
    this.selectedDiagnosisId,
    required this.openEditLesionPage,
  });

  @override
  Widget build(BuildContext context) {
    final DiagnosisMainController mainController =
        Get.put<DiagnosisMainController>(
          DiagnosisMainController(
            lesion: lesion,
            selectedDiagnosisId: selectedDiagnosisId,
            patient: patient,
          ),
          tag: lesion.id,
        );

    return Obx(() {
      final DiagnosisProcessState currentState =
          mainController.processState.value;
      final bool isRemoved = lesion.wasRemoved.value;
      final RxList<Diagnosis> diagnoses = mainController.lesion.diagnoses;
      final int currentPage = mainController.currentPage.value;

      int pageCount;
      if (isRemoved) {
        pageCount = 1 + diagnoses.length;
      } else if (currentState == DiagnosisProcessState.cutout) {
        pageCount = 2 + diagnoses.length;
      } else {
        pageCount = 1 + diagnoses.length;
      }

      final bool isDraftPreview =
          currentState == DiagnosisProcessState.cutout && currentPage == 1;
      final bool isCompactPage =
          (isRemoved && currentPage == 0) ||
          (!isRemoved && (currentPage == 0 || isDraftPreview));

      final double currentHeight = isCompactPage
          ? 250.0
          : MediaQuery.sizeOf(context).height * 0.70;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: currentHeight + 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(
              top: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
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
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondaryFixedVariant
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    Expanded(
                      child: PageView.builder(
                        controller: mainController.pageController,
                        onPageChanged: (int index) =>
                            mainController.currentPage.value = index,
                        itemCount: pageCount,
                        itemBuilder: (BuildContext context, int index) {
                          if (isRemoved) {
                            if (index == 0) {
                              return RemovedLesionSheet(
                                mainController: mainController,
                              );
                            }
                            return CustomDiagnosisSheet(
                              diagnosis: diagnoses[index - 1],
                              mainController: mainController,
                            );
                          }

                          if (index == 0) {
                            return CustomCaptureSheet(
                              mainController: mainController,
                            );
                          }

                          if (currentState == DiagnosisProcessState.cutout) {
                            if (index == 1) {
                              return CustomCutoutSheet(
                                mainController: mainController,
                              );
                            }
                            return CustomDiagnosisSheet(
                              diagnosis: diagnoses[index - 2],
                              mainController: mainController,
                            );
                          }

                          return CustomDiagnosisSheet(
                            diagnosis: diagnoses[index - 1],
                            mainController: mainController,
                          );
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
                              color: currentPage == index
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).scaffoldBackgroundColor,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -AppTheme.spaceSmall,
              right: AppTheme.spaceLarge,
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spaceSmall),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: AppTheme.radiusLarge * 2,
                  height: AppTheme.radiusLarge * 2,
                  child: FloatingActionButton(
                    heroTag: 'edit_lesion_fab_${lesion.id}',
                    elevation: 0,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    onPressed: openEditLesionPage,
                    child: const Icon(Icons.info),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
