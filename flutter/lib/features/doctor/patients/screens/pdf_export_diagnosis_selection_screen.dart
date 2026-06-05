import 'dart:typed_data';

import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/app/enums.dart';
import 'package:dermascan/core/models/body_lesion.dart';
import 'package:dermascan/core/models/diagnosis.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/features/doctor/patients/controller/pdf_export_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PdfExportDiagnosisSelectionScreen extends GetView<PdfExportController> {
  final BodyLesion lesion;

  const PdfExportDiagnosisSelectionScreen({super.key, required this.lesion});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Export - Diagnosis Selection'),
        actions: <Widget>[
          Obx(() {
            if (controller.isLoading.value || controller.lesions.isEmpty) {
              return const SizedBox.shrink();
            }

            final bool allSelected = controller.allDraftDiagnosesSelected(
              lesion,
            );

            return IconButton(
              tooltip: allSelected
                  ? 'Clear all diagnoses'
                  : 'Select all diagnoses',
              icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
              onPressed: () =>
                  controller.toggleAllDraftDiagnosesSelection(lesion),
            );
          }),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (controller.lesions.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildDiagnosisExport();
        }),
      ),
      floatingActionButton: Obx(() {
        if (controller.isLoading.value || controller.lesions.isEmpty) {
          return const SizedBox.shrink();
        }

        return FilledButton.icon(
          icon: const Icon(Icons.done),
          onPressed: () {
            controller.commitDraftDiagnosisSelection();
            Get.back();
          },
          label: const Text('Finish selection'),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: AppTheme.scaffoldPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Spacer(),
          const CustomIcon(iconData: Icons.warning),
          const SizedBox(height: AppTheme.spaceLarge),
          Text(
            'No lesions found for this patient.',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
        ],
      ),
    );
  }

  Widget _buildDiagnosisExport() {
    final RxList<Diagnosis> diagnosisList = lesion.diagnoses;
    return Column(
      children: <Widget>[
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ExportableDiagnosisMetric.values.length,
          itemBuilder: (BuildContext context, int index) {
            final ExportableDiagnosisMetric metric =
                ExportableDiagnosisMetric.values[index];

            return SizedBox(
              height: 48,
              child: Obx(
                () => CheckboxListTile(
                  title: Text(metric.toString().split('.').last.toUpperCase()),
                  value: controller.isMetricSelected(lesion, metric),
                  onChanged: controller.isLoading.value
                      ? null
                      : (bool? value) {
                          controller.toggleDiagnosisMetricSelection(metric);
                        },
                ),
              ),
            );
          },
        ),

        const Divider(),

        Expanded(
          child: ListView.builder(
            itemCount: diagnosisList.length,
            itemBuilder: (BuildContext context, int index) {
              final Diagnosis diagnosis = diagnosisList[index];
              final Uint8List imageBytes = diagnosis.image;

              return ListTile(
                leading: AspectRatio(
                  aspectRatio: 1.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    child: Image(
                      image: MemoryImage(imageBytes),
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
                ),
                title: Text('Diagnosis ${index + 1}'),
                subtitle: Text(
                  'Date: ${DateFormat('dd.MM.yyyy').format(diagnosis.date)}',
                ),
                onTap: () {
                  controller.toggleDraftDiagnosisSelection(diagnosis);
                },
                trailing: SizedBox(
                  width: 48,
                  child: Center(
                    child: Obx(
                      () => Checkbox(
                        value: controller.isDraftDiagnosisSelected(
                          lesion,
                          diagnosis,
                        ),
                        onChanged: controller.isLoading.value
                            ? null
                            : (bool? value) {
                                controller.toggleDraftDiagnosisSelection(
                                  diagnosis,
                                );
                              },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
