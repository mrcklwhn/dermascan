import 'dart:typed_data';

import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/models/body_lesion.dart';
import 'package:dermascan/core/models/diagnosis.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/core/widgets/custom_toggle_card.dart';
import 'package:dermascan/features/doctor/patients/controller/pdf_export_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PdfExportLesionSelectionScreen extends GetView<PdfExportController> {
  const PdfExportLesionSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Export - Lesions')),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (controller.lesions.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildLesionList(context);
        }),
      ),
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

  Widget _buildLesionList(BuildContext context) {
    final Iterable<Widget> lesionTiles = controller.lesions.map(
      (BodyLesion lesion) {
        if (lesion.diagnoses.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSmall),
          child: Card(
            child: ExpansionTile(
              initiallyExpanded: false,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                lesion.locationName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              trailing: Checkbox(
                value: controller.areAllDiagnosesSelected(lesion),
                tristate: true,
                onChanged: controller.isLoading.value
                    ? null
                    : (bool? value) {
                        controller.toggleAllDiagnosesForLesion(lesion);
                      },
              ),
              children: <Widget>[
                  ...List<Widget>.generate(
                    lesion.diagnoses.length,
                    (int index) {
                      final Diagnosis diagnosis = lesion.diagnoses[index];
                      final Uint8List? imageBytes =
                          diagnosis.analyzedImages?['original'];

                      return Obx(
                        () => ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceSmall,
                            vertical: 4.0,
                          ),
                          leading: AspectRatio(
                            aspectRatio: 1.0,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSmall,
                              ),
                              child: imageBytes == null || imageBytes.isEmpty
                                  ? const ColoredBox(
                                      color: Colors.black12,
                                      child: Icon(Icons.image_not_supported),
                                    )
                                  : Image(
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
                            controller.toggleDiagnosisSelection(lesion, diagnosis);
                          },
                          trailing: Checkbox(
                            value: controller.isDiagnosisSelected(
                              lesion,
                              diagnosis,
                            ),
                            onChanged: controller.isLoading.value
                                ? null
                                : (bool? value) {
                                    controller.toggleDiagnosisSelection(
                                      lesion,
                                      diagnosis,
                                    );
                                  },
                          ),
                        ),
                      );
                    },
                  )
                ],
              )
          )
        );
      },
    );

    return ListView(
      controller: controller.scrollController,
      scrollDirection: Axis.vertical,
      padding: AppTheme.scaffoldPadding,
      children: <Widget>[
        const SizedBox(height: AppTheme.spaceMedium),
        const CustomIcon(iconData: Icons.picture_as_pdf),
        const SizedBox(height: AppTheme.spaceLarge),
        Text(
          'Export Properties',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        ToggleCard(
          title: 'AI Classification',
          subtitle: 'Export AI-based classification results for each lesion',
          value: controller.shouldExportMLClassification,
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        ToggleCard(
          title: 'ABC Scores',
          subtitle: 'Export ABC scores for each lesion',
          value: controller.shouldExportABCScores,
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        ToggleCard(
          title: 'Notes',
          subtitle: 'Export notes for each lesion',
          value: controller.shouldExportNotes,
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Text(
          'Lesions',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        ...lesionTiles,
        const SizedBox(height: AppTheme.spaceLarge),
        FilledButton.icon(
          icon: controller.isExporting.value
              ? const SizedBox(
                  width: 16.0,
                  height: 16.0,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                )
              : const Icon(Icons.picture_as_pdf),
          onPressed:
              (controller.isExporting.value ||
                  controller.isExportable() == false)
              ? null
              : controller.exportPDF,
          label: const Text('Export'),
        )
      ],
    );
  }
}
