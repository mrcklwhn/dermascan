import 'dart:typed_data';

import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/app/enums.dart';
import 'package:dermascan/core/models/diagnosis.dart';
import 'package:dermascan/core/widgets/custom_bottom_sheets/diagnosis_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDiagnosisSheet extends StatelessWidget {
  final Diagnosis diagnosis;
  final DiagnosisController controller;

  const CustomDiagnosisSheet({
    super.key,
    required this.diagnosis,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final double size =
        (MediaQuery.of(context).size.width -
            AppTheme.spaceMedium * 2 -
            AppTheme.spaceSmall * 3) /
        2;

    return ListView(
      padding: AppTheme.scaffoldPadding,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    'Diagnosis',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Date: ${DateFormat.yMMMd().format(diagnosis.date)} at ${DateFormat.Hm().format(diagnosis.date)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Doctor: ${diagnosis.doctorName}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (diagnosis.analyzedImages != null &&
            diagnosis.analyzedImages!.entries
                .where((MapEntry<String, Uint8List?> e) => e.key != 'original')
                .isNotEmpty) ...<Widget>[
          const SizedBox(height: AppTheme.spaceLarge),
          _buildScoreIndicator(
            context,
            title: 'Prediction: ${diagnosis.prediction?.name}',
            score: diagnosis.confidence ?? 0.0,
            color: diagnosis.prediction == LesionType.nevi
                ? Colors.green
                : Colors.red,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          ExpansionTile(
            collapsedBackgroundColor: AppTheme.scaffoldBg,
            backgroundColor: AppTheme.scaffoldBg,
            initiallyExpanded: false,
            title: Text(
              'Analysis Insights',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: diagnosis.analyzedImages!.entries
                    .where(
                      (MapEntry<String, Uint8List?> e) => e.key != 'original',
                    )
                    .map((MapEntry<String, Uint8List?> entry) {
                      return Column(
                        children: <Widget>[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
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
                          const SizedBox(height: AppTheme.spaceSmall),
                          Text(
                            entry.key,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      );
                    })
                    .toList(),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppTheme.spaceLarge),
        _buildScoreIndicator(
          context,
          title: 'Asymmetry',
          score: diagnosis.aScore ?? 0.0,
          textLeft: 'Symmetric',
          textRight: 'Asymmetric',
        ),
        const SizedBox(height: AppTheme.spaceLarge),
        _buildScoreIndicator(
          context,
          title: 'Border',
          score: diagnosis.bScore ?? 0.0,
          textLeft: 'Circular',
          textRight: 'Irregular',
        ),
        const SizedBox(height: AppTheme.spaceLarge),
        _buildScoreIndicator(
          context,
          title: 'Color Uniformity',
          score: diagnosis.cScore ?? 0.0,
          textLeft: 'Uniform',
          textRight: 'Variegated',
        ),

        const SizedBox(height: AppTheme.spaceLarge),
        OutlinedButton.icon(
          onPressed: controller.isLoading.value
              ? null
              : () =>
                    controller.showDeleteDiagnosisDialog(diagnosis: diagnosis),
          icon: const Icon(Icons.delete),
          label: const Text('Delete'),
        ),
      ],
    );
  }

  Widget _buildScoreIndicator(
    BuildContext context, {
    required String title,
    required double score,
    String? textLeft,
    String? textRight,
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        LinearProgressIndicator(
          value: score,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
          backgroundColor: AppTheme.scaffoldBg,
          color: color ?? Theme.of(context).primaryColor,
        ),
        const SizedBox(height: AppTheme.spaceSmall),

        Row(
          children: <Widget>[
            if (textLeft != null)
              Text(textLeft, style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            if (textRight != null)
              Text(textRight, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}
