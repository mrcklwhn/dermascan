import 'dart:async';

import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/app/enums.dart';
import 'package:dermascan/core/models/diagnosis.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/widgets/custom_dialog.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:dermascan/core/widgets/custom_text_field.dart';
import 'package:dermascan/core/widgets/diagnosis_bottom_sheet/diagnosis_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DiagnosisDetailController extends GetxController {
  final Diagnosis diagnosis;
  final DiagnosisMainController mainController;
  final AuthService authService = Get.find<AuthService>();
  final DBService dbService = Get.find<DBService>();

  final TextEditingController notesController = TextEditingController();
  final FocusNode notesFocusNode = FocusNode();
  final RxBool isLoading = false.obs;
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

  Future<void> submittedNotes() async {
    if (isLoading.value) return;
    notesFocusNode.unfocus();

    if (!hasNotesChanged) return;

    final String diagnosisId = diagnosis.id;

    isLoading.value = true;

    try {
      final bool success = await dbService.updateDiagnosis(
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
              title: 'Notes Updated',
              message: 'The diagnosis notes have been successfully saved.',
            ),
          );
        }
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: 'Error Saving Notes',
              message: 'The updates could not be saved. Please try again.',
            ),
          );
        }
      }
    } finally {
      isLoading.value = false;
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
            title: 'Authentication Error',
            message: 'You are not signed in correctly. Please log in again.',
          ),
        );
      }
      return;
    }

    final String diagnosisId = diagnosis.id;

    isLoading.value = true;

    try {
      final bool success = await dbService.deleteDiagnosis(
        diagnosisId: diagnosisId,
      );

      if (success) {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.check,
              title: 'Diagnosis Deleted',
              message: 'The Diagnosis and its image have been deleted.',
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
              title: 'Error Deleting Diagnosis',
              message: 'The Diagnosis could not be deleted.',
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
      title: 'Delete Diagnosis?',
      subtitle:
          'You are about to delete this diagnosis. This will delete all information including the images. Do you want to continue?',
      isDismissable: !isLoading.value,
      submitText: 'Delete',
      onSubmit: isLoading.value
          ? null
          : (_) async {
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
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: Image.memory(
                  diagnosis.image,
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
                      'Diagnosis ${(mainController.lesion.diagnoses.length - mainController.currentPage.value) + 1}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppTheme.spaceSmall),
                    Text(
                      'Date: ${DateFormat.yMMMd().format(diagnosis.date)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Doctor: ${diagnosis.doctorName}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          Text('Prediction', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spaceSmall),
          _buildScoreIndicator(
            context,
            title: diagnosis.prediction.name.capitalizeFirst,
            textLeft: 'Uncertain',
            textRight: 'Confident',
            score: diagnosis.confidence,
            color: diagnosis.prediction == LesionType.nevi
                ? Colors.green
                : Colors.red,
          ),

          const SizedBox(height: AppTheme.spaceMedium),
          Text('ABC - Scores', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spaceSmall),
          _buildScoreIndicator(
            context,
            title: 'Asymmetry',
            score: diagnosis.aScore,
            textLeft: 'Symmetric',
            textRight: 'Asymmetric',
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          _buildScoreIndicator(
            context,
            title: 'Border',
            score: diagnosis.bScore,
            textLeft: 'Circular',
            textRight: 'Irregular',
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          _buildScoreIndicator(
            context,
            title: 'Color Uniformity',
            score: diagnosis.cScore,
            textLeft: 'Uniform',
            textRight: 'Variegated',
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Additional Info',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          CustomTextField(
            textEditingController: controller.notesController,
            focusNode: controller.notesFocusNode,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            onSubmitted: (_) => controller.submittedNotes(),
            labelText: 'Notes',
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
                onPressed: controller.isLoading.value
                    ? null
                    : () => controller.submittedNotes(),
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            );
          }),

          OutlinedButton.icon(
            onPressed: controller.isLoading.value
                ? null
                : () => controller.showDeleteDiagnosisDialog(),
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
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
