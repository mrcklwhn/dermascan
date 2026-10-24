import 'dart:typed_data';

import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/models/body_lesion.dart';
import 'package:dermascan/core/models/diagnosis.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/core/widgets/custom_toggle_card.dart';
import 'package:dermascan/features/doctor/patients/controller/pdf_export_controller.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PdfExportLesionSelectionScreen extends GetView<PdfExportController> {
  const PdfExportLesionSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(TrKeys.pdf.exportPdf.tr)),
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
          const CustomIcon(iconData: Icons.person_add),
          const SizedBox(height: AppTheme.spaceLarge),
          Text(
            TrKeys.lesion.noLesions.tr,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            TrKeys.lesion.selectedPatientNoLesions
                .tr,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildLesionList(BuildContext context) {
    final List<Widget> lesionTiles = controller.lesions
        .where((BodyLesion lesion) => lesion.diagnoses.isNotEmpty)
        .map<Widget>((BodyLesion lesion) {
          return Card(
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
                onChanged: (bool? value) {
                        controller.toggleAllDiagnosesForLesion(lesion: lesion);
                      },
              ),
              children: <Widget>[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lesion.diagnoses.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: AppTheme.spaceSmall),
                  itemBuilder: (BuildContext context, int index) {
                    final Diagnosis diagnosis = lesion.diagnoses[index];
                    final Uint8List? imageBytes =
                        diagnosis.analyzedImages?['original'];

                    return Obx(
                      () => Card(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: ListTile(
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
                          title: Text('${TrKeys.diagnosis.diagnosis.tr} ${index + 1}'),
                          subtitle: Text(
                            '${TrKeys.common.date.tr}: ${DateFormat('dd.MM.yyyy').format(diagnosis.date)}',
                          ),
                          onTap: () {
                            controller.toggleDiagnosisSelection(
                              lesion: lesion,
                              diagnosis: diagnosis,
                            );
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
                                      lesion: lesion,
                                      diagnosis: diagnosis,
                                    );
                                  },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        })
        .toList();

    final List<Widget> separatedLesionTiles = <Widget>[
      for (int i = 0; i < lesionTiles.length; i++) ...<Widget>[
        lesionTiles[i],
        if (i < lesionTiles.length - 1)
          const SizedBox(height: AppTheme.spaceSmall),
      ],
    ];

    return ListView(
      controller: controller.scrollController,
      scrollDirection: Axis.vertical,
      padding: AppTheme.scaffoldPadding,
      children: <Widget>[
        const SizedBox(height: AppTheme.spaceMedium),
        const CustomIcon(iconData: Icons.picture_as_pdf),
        const SizedBox(height: AppTheme.spaceLarge),
        Text(
          TrKeys.pdf.exportProperties.tr,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        ToggleCard(
          title: TrKeys.pdf.abcScores.tr,
          subtitle: TrKeys.pdf.abcScoresDesc.tr,
          value: controller.shouldExportABCScores,
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        ToggleCard(
          title: TrKeys.common.notes.tr,
          subtitle: TrKeys.pdf.exportNotesDesc.tr,
          value: controller.shouldExportNotes,
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Text(TrKeys.pdf.lesions.tr, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppTheme.spaceSmall),
        ...separatedLesionTiles,
        const SizedBox(height: AppTheme.spaceLarge),
        FilledButton.icon(
          icon: const Icon(Icons.picture_as_pdf),
          onPressed: controller.exportPDF,
          label: Text(TrKeys.pdf.export.tr),
        ),
      ],
    );
  }
}
