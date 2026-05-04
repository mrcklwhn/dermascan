import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/app/enums.dart';
import 'package:dermascan/core/models/diagnosis.dart';
import 'package:dermascan/core/widgets/custom_bottom_sheets/diagnosis_bottom_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomCutoutSheet extends StatelessWidget {
  final Diagnosis diagnosis;
  final DiagnosisController controller;

  const CustomCutoutSheet({
    super.key,
    required this.controller,
    required this.diagnosis,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator.adaptive());
      }
      return Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            if (controller.cutoutML != null)
              _buildSelectorButton(
                context: context,
                image: controller.cutoutML!,
                onPressed: () async => controller.startDiagnosisPipeline(
                  diagnosis: diagnosis,
                  type: CutoutType.ml,
                ),
              ),
            if (controller.cutoutAlgo != null)
              _buildSelectorButton(
                context: context,
                image: controller.cutoutAlgo!,
                onPressed: () async => controller.startDiagnosisPipeline(
                  diagnosis: diagnosis,
                  type: CutoutType.algorithmic,
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildSelectorButton({
    required BuildContext context,
    required Uint8List image,
    required VoidCallback onPressed,
  }) {
    final double size =
        (MediaQuery.of(context).size.width - AppTheme.spaceMedium * 3) / 2;
    return FilledButton(
      style: FilledButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: AppTheme.scaffoldBg,
        foregroundColor: AppTheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        fixedSize: Size(size, size),
      ),
      onPressed: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Image.memory(
          image,
          height: size,
          width: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
