import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/models/diagnosis.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service/lesion_db_service.dart';
import 'package:dermascan/core/widgets/custom_dialog.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:dermascan/core/widgets/custom_text_field.dart';
import 'package:dermascan/core/widgets/diagnosis_bottom_sheet/diagnosis_bottom_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DiagnosisDetailController extends GetxController {
  final Diagnosis diagnosis;
  final DiagnosisMainController mainController;
  final AuthService authService = Get.find<AuthService>();
  final LesionDbService lesionDbService = Get.find<LesionDbService>();

  final TextEditingController notesController = TextEditingController();
  final FocusNode notesFocusNode = FocusNode();
  final RxBool isLoading = false.obs;
  final RxBool isDrawingOverlays = false.obs;
  final RxString currentNotesText = ''.obs;

  DiagnosisDetailController({
    required this.diagnosis,
    required this.mainController,
  });

  @override
  void onInit() {
    super.onInit();
    notesController.text = diagnosis.notes;
    currentNotesText.value = diagnosis.notes;
    notesController.addListener(() {
      currentNotesText.value = notesController.text;
    });
  }

  @override
  void onClose() {
    notesController.dispose();
    notesFocusNode.dispose();
    super.onClose();
  }

  bool get hasNotesChanged => currentNotesText.value != diagnosis.notes;

  Future<void> drawOverlays() async {
    if (isDrawingOverlays.value) return;

    final Map<String, Uint8List?>? images = diagnosis.analyzedImages;
    if (images == null || images['original'] == null) return;
    if (images.containsKey('contour') && images.containsKey('concavity')) return;

    isDrawingOverlays.value = true;

    await Future<void>.delayed(const Duration(milliseconds: 100));
    try {
      await mainController.drawOverlaysForDiagnosis(diagnosis);
    } finally {
      isDrawingOverlays.value = false;
    }
  }

  Future<void> submittedNotes() async {
    if (isLoading.value) return;
    notesFocusNode.unfocus();

    if (!hasNotesChanged) return;

    final String diagnosisId = diagnosis.id;

    isLoading.value = true;

    try {
      final bool success = await lesionDbService.updateDiagnosis(
        diagnosisId: diagnosisId,
        notes: currentNotesText.value.trim(),
      );

      if (success) {
        diagnosis.notes = currentNotesText.value.trim();
        currentNotesText.value = diagnosis.notes;
        notesController.text = diagnosis.notes;

        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check,
              title: 'Notes Updated'.tr,
              message: 'Diagnosis notes saved successfully.'.tr,
            ),
          );
        }
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'Error Saving Notes'.tr,
              message: 'Could not save updates. Please try again.'.tr,
            ),
          );
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> shareDiagnosis() async {
    final Map<String, Uint8List?>? images = diagnosis.analyzedImages;
    final Uint8List? imageBytes = images?['original'];

    if (imageBytes == null) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Error'.tr,
          message: 'No image available to share.'.tr,
        ),
      );
      return;
    }

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final File file = await File('${tempDir.path}/lesions_${diagnosis.id}.png').create();
      await file.writeAsBytes(imageBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(file.path)],
          text: 'Lesion Report\nPatient: ${mainController.patient.name}\nDate:${diagnosis.date}\nPosition: ${mainController.lesion.position}\nNotes: ${diagnosis.notes}',
        ),
      );
    } catch (e) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: 'Sharing Failed'.tr,
          message: 'Could not share image. Please try again.'.tr,
        ),
      );
    }
  }

  Future<void> deleteDiagnosis() async {
    if (isLoading.value) return;
    if (authService.currentDoctor.value == null) return;

    final String? doctorId = authService.currentUser.value?.id;
    if (doctorId == null) {
      if (!Get.isSnackbarOpen) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Authentication Error'.tr,
            message: 'Authentication error. Please log in again.'.tr,
          ),
        );
      }
      return;
    }

    final String diagnosisId = diagnosis.id;

    isLoading.value = true;

    try {
      final bool success = await lesionDbService.deleteDiagnosis(
        diagnosisId: diagnosisId,
      );

      if (success) {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check,
              title: 'Diagnosis Deleted'.tr,
              message: 'The Diagnosis and its image have been deleted.'.tr,
            ),
          );
        }
        mainController.animateToPage(mainController.currentPage.value - 1);
        mainController.lesion.diagnoses.removeWhere(
          (Diagnosis d) => d.id == diagnosisId,
        );
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'Error Deleting Diagnosis'.tr,
              message: 'The Diagnosis could not be deleted.'.tr,
            ),
          );
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> showDeleteDiagnosisDialog() async {
    if (isLoading.value) return;

    await CustomDialogHelper.show(
      routeName: 'delete-diagnosis-dialog',
      title: 'Delete Diagnosis?'.tr,
      subtitle:
          'Delete this diagnosis? All associated data and images will be permanently removed.'
              .tr,
      isDismissable: !isLoading.value,
      submitText: 'Delete'.tr,
      onSubmit: (_) async {
              await deleteDiagnosis();
            },
    );
  }
}

class CustomDiagnosisSheet extends StatelessWidget {
  final Diagnosis diagnosis;
  final DiagnosisMainController mainController;

  const CustomDiagnosisSheet({
    super.key,
    required this.diagnosis,
    required this.mainController,
  });

  @override
  Widget build(BuildContext context) {
    final DiagnosisDetailController controller =
        Get.find<DiagnosisDetailController>(tag: diagnosis.id);

    final double size =
        (MediaQuery.of(context).size.width -
            AppTheme.spaceMedium * 2 -
            AppTheme.spaceSmall * 3) /
        2;

    return Obx(() {
      if (mainController.isLoading.value || controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator.adaptive());
      }

      return ListView(
        padding: AppTheme.scaffoldPadding,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              if (diagnosis.analyzedImages != null &&
                  diagnosis.analyzedImages!['original'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  child: Image.memory(
                    diagnosis.analyzedImages!['original']!,
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(width: AppTheme.spaceMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${'Diagnosis'.tr} ${mainController.lesion.diagnoses.length - mainController.currentPage.value + 1}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppTheme.spaceSmall),
                    Text(
                      '${'Date'.tr}: ${DateFormat('dd.MM.yyyy').format(diagnosis.date)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${'Doctor'.tr}: ${diagnosis.doctorName!}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Share'.tr,
                onPressed: controller.shareDiagnosis,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          Text(
            'ABC - Scores'.tr,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          _buildScoreIndicator(
            context,
            title: 'Asymmetry'.tr,
            score: diagnosis.aScore,
            textLeft: 'Symmetric'.tr,
            textRight: 'Asymmetric'.tr,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          _buildScoreIndicator(
            context,
            title: 'Border'.tr,
            score: diagnosis.bScore,
            textLeft: 'Circular'.tr,
            textRight: 'Irregular'.tr,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          _buildScoreIndicator(
            context,
            title: 'Color Uniformity'.tr,
            score: diagnosis.cScore,
            textLeft: 'Uniform'.tr,
            textRight: 'Variegated'.tr,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Additional Info'.tr,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          CustomTextField(
            textEditingController: controller.notesController,
            focusNode: controller.notesFocusNode,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            onSubmitted: (_) => controller.submittedNotes(),
            labelText: 'Notes'.tr,
            prefixIcon: Icons.description,
            textInputType: TextInputType.multiline,
            minLines: 1,
            maxLines: 5,
          ),
          Obx(() {
            if (!controller.hasNotesChanged) {
              return const SizedBox(height: AppTheme.spaceLarge);
            }
            return Padding(
              padding: const EdgeInsets.only(
                top: AppTheme.spaceLarge,
                bottom: AppTheme.spaceMedium,
              ),
              child: FilledButton.icon(
                onPressed: () => controller.submittedNotes(),
                icon: const Icon(Icons.save),
                label: Text('Save'.tr),
              ),
            );
          }),
          if (diagnosis.analyzedImages != null &&
              diagnosis.analyzedImages!['original'] != null) ...<Widget>[
            const SizedBox(height: AppTheme.spaceMedium),
            ExpansionTile(
              collapsedBackgroundColor: AppTheme.scaffoldBg,
              backgroundColor: AppTheme.scaffoldBg,
              initiallyExpanded: false,
              onExpansionChanged: (bool expanded) {
                if (expanded) {
                  controller.drawOverlays();
                }
              },
              title: Text(
                'Analysis Insights'.tr,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              children: <Widget>[
                Obx(() {
                  if (controller.isDrawingOverlays.value) {
                    return SizedBox(
                      height: size,
                      child: const Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                    );
                  }

                  final List<MapEntry<String, Uint8List?>> overlayImages =
                      diagnosis.analyzedImages!.entries
                          .where(
                            (MapEntry<String, Uint8List?> e) =>
                                e.key != 'original' && e.value != null,
                          )
                          .toList();

                  if (overlayImages.isEmpty) {
                    return SizedBox(height: size);
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:
                        overlayImages.map((MapEntry<String, Uint8List?> entry) {
                          return Column(
                            children: <Widget>[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSmall + 2,
                                ),
                                child: Image(
                                  image: MemoryImage(entry.value!),
                                  height: size,
                                  width: size,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                  errorBuilder:
                                      (
                                        BuildContext context,
                                        Object error,
                                        StackTrace? stackTrace,
                                      ) => const Icon(Icons.broken_image),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  );
                }),
              ],
            ),
          ],
          const SizedBox(height: AppTheme.spaceLarge),
          OutlinedButton.icon(
            onPressed: () => controller.showDeleteDiagnosisDialog(),
            icon: const Icon(Icons.delete),
            label: Text('Delete'.tr),
          ),
        ],
      );
    });
  }

  Widget _buildScoreIndicator(
    BuildContext context, {
    required double score,
    String? title,
    required String textLeft,
    required String textRight,
    Color? color,
  }) {
    return Card(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: EdgeInsets.only(
          top: title == null ? AppTheme.spaceMedium : AppTheme.spaceSmall,
          bottom: AppTheme.spaceMedium,
          right: AppTheme.spaceMedium,
          left: AppTheme.spaceMedium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (title != null) ...<Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSmall),
            ],

            LinearProgressIndicator(
              value: score,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: Theme.of(context).highlightColor,
              color: color ?? Theme.of(context).primaryColor,
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Row(
              children: <Widget>[
                Text(textLeft, style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                Text(
                  '${(score * 100).toStringAsFixed(2)} %',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.left,
                ),
                const Spacer(),
                Text(textRight, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
