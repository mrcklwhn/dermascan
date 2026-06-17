import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/core/widgets/diagnosis_bottom_sheet/diagnosis_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RemovedLesionSheet extends StatelessWidget {
  final DiagnosisMainController mainController;

  const RemovedLesionSheet({super.key, required this.mainController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (mainController.isLoading.value) {
        return const Center(child: CircularProgressIndicator.adaptive());
      }
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const CustomIcon(
            iconData: Icons.delete_sweep_outlined,
            color: Colors.grey,
          ),

          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Lesion Excised'.tr,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Lesion excised.\nDiagnoses remain accessible.'.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    });
  }
}
