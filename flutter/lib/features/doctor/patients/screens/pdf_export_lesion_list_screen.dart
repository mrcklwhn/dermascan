import 'dart:typed_data';
import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/models/body_lesion.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
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

          return _buildLesionList();
        }),
      ),
      floatingActionButton: Obx(() {
        if (controller.isLoading.value || controller.lesions.isEmpty) {
          return const SizedBox.shrink();
        }

        return FilledButton.icon(
          icon: controller.isExporting.value 
            ? const SizedBox(
                width: 16.0,
                height: 16.0,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              ) 
            : const Icon(Icons.picture_as_pdf),
          onPressed: (controller.isExporting.value || !controller.exportablePatientData.value.canExport.value)
            ? null 
            : controller.exportPDF,
          label: const Text('Export'),
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

  Widget _buildLesionList() {
    return ListView.builder(
      itemCount: controller.lesions.length,
      itemBuilder: (BuildContext context, int index) {
        final BodyLesion lesion = controller.lesions[index];

        if (lesion.diagnoses.isEmpty) {
          return const SizedBox.shrink();
        }

        final List<Uint8List> previewImages = (controller.lesionPreviewImages[lesion.id] ?? <Uint8List>[])
            .where((Uint8List bytes) => bytes.isNotEmpty)
            .take(3)
            .toList();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Card(
              color: AppTheme.scaffoldBg,
              child: ListTile(
                title: Text(lesion.locationName),
                leading: AspectRatio(
                  aspectRatio: 1.0,
                  child: Builder(builder: (BuildContext context) {
                    if (previewImages.isEmpty) {
                      return const Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child: Icon(Icons.image_not_supported, size: 40.0),
                          ),
                        ],
                      );
                    }

                    return Stack(
                      clipBehavior: Clip.none,
                      children: List<Widget>.generate(previewImages.length, (int index) {
                        final int imageIndex = previewImages.length - 1 - index;
                        final Uint8List bytes = previewImages[imageIndex];

                        final double offset = imageIndex * 4.0;

                        return Positioned(
                          top: offset,
                          left: offset,
                          right: 4.0 * (previewImages.length - 1) - offset,
                          bottom: 4.0 * (previewImages.length - 1) - offset,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            child: Image(
                              image: MemoryImage(bytes),
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) =>
                                  const Icon(Icons.broken_image),
                            ),
                          ),
                        );
                      }),
                    );
                  }),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Date: ${lesion.diagnoses.isNotEmpty ? DateFormat('dd.MM.yyyy').format(lesion.diagnoses[0].date) : 'Not specified'}',
                    ),
                    Text('Status: ${lesion.isSuspicious.value ? 'Suspicious' : 'Not Suspicious'}'),
                    Obx(() => Text('Selected: ${controller.getExportedRatioText(lesion)}')),
                  ],
                ),
                onTap: () {
                  controller.openLesionDetail(lesion);
                },
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    controller.openLesionDetail(lesion);
                  },
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
          ],
        );
      },
      );

  }
}
