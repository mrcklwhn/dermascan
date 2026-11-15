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
import 'package:dermascan/translations/tr_keys.dart';
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
              title: TrKeys.diagnosis.notesUpdated.tr,
              message: TrKeys.diagnosis.notesSavedMsg.tr,
            ),
          );
        }
      } else {
        if (!Get.isSnackbarOpen) {
          Get.showSnackbar(
            CustomSnackBar(
              icon: Icons.error,
              title: TrKeys.diagnosis.errorSavingNotes.tr,
              message: TrKeys.diagnosis.couldNotSaveUpdates.tr,
            ),
          );
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> shareDiagnosis() async {
    final Uint8List? imageBytes = diagnosis.image;

    if (imageBytes == null) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: TrKeys.common.error.tr,
          message: TrKeys.common.noImageToShare.tr,
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
          text: 'Lesion Report\nPatient: ${mainController.patient.name}\nDate:${DateFormat('dd.MM.yyyy').format(diagnosis.date)}\nPosition: ${mainController.lesion.locationName}${diagnosis.notes.isNotEmpty ? '\nNotes: ${diagnosis.notes}' : ''}',
        ),
      );
    } catch (e) {
      Get.showSnackbar(
        CustomSnackBar(
          icon: Icons.error,
          title: TrKeys.common.sharingFailed.tr,
          message: TrKeys.common.couldNotShareImage.tr,
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
            title: TrKeys.common.authenticationError.tr,
            message: TrKeys.common.authErrorReLogin.tr,
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
              title: TrKeys.diagnosis.diagnosisDeleted.tr,
              message: TrKeys.diagnosis.diagnosisDeletedMsg.tr,
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
              title: TrKeys.diagnosis.errorDeletingDiagnosis.tr,
              message: TrKeys.diagnosis.diagnosisCouldNotBeDeleted.tr,
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
      title: TrKeys.diagnosis.deleteDiagnosisQuestion.tr,
      subtitle:
          TrKeys.diagnosis.deleteDiagnosisConfirmMsg
              .tr,
      isDismissable: !isLoading.value,
      submitText: TrKeys.common.delete.tr,
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
              if (diagnosis.image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  child: Image.memory(
                    diagnosis.image!,
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
                      '${TrKeys.diagnosis.diagnosis.tr} ${mainController.lesion.diagnoses.length - mainController.currentPage.value + 1}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppTheme.spaceSmall),
                    Text(
                      '${TrKeys.common.date.tr}: ${DateFormat('dd.MM.yyyy').format(diagnosis.date)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${TrKeys.doctor.doctor.tr}: ${diagnosis.doctorName!}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: TrKeys.common.share.tr,
                onPressed: controller.shareDiagnosis,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          CustomTextField(
            textEditingController: controller.notesController,
            focusNode: controller.notesFocusNode,
            backgroundColor: Theme.of(context).colorScheme.surface,
            onSubmitted: (_) => controller.submittedNotes(),
            labelText: TrKeys.common.notes.tr,
            prefixIcon: Icons.description,
            textInputType: TextInputType.multiline,
            minLines: 1,
            maxLines: 10,
          ),
          Obx(() {
            if (controller.hasNotesChanged) {
              return Padding(
                padding: const EdgeInsets.only(
                  top: AppTheme.spaceMedium,
                ),
                child: FilledButton.icon(
                  onPressed: () => controller.submittedNotes(),
                  icon: const Icon(Icons.save),
                  label: Text(TrKeys.common.save.tr),
                ),
              );
            }
            return const Center();
          }),
          const SizedBox(height: AppTheme.spaceLarge),
          OutlinedButton.icon(
            onPressed: () => controller.showDeleteDiagnosisDialog(),
            icon: const Icon(Icons.delete),
            label: Text(TrKeys.common.delete.tr),
          ),
        ],
      );
    });
  }
}
