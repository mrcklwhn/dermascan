import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/widgets/custom_bottom_sheets/diagnosis_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class CustomCaptureSheet extends StatelessWidget {
  final DiagnosisController controller;

  const CustomCaptureSheet({super.key, required this.controller});

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
            _buildActionButton(
              context: context,
              icon: Icons.camera_enhance,
              label: 'Capture',
              onPressed: () => controller.selectImage(ImageSource.camera),
            ),
            _buildActionButton(
              context: context,
              icon: Icons.photo_library,
              label: 'Select',
              onPressed: () => controller.selectImage(ImageSource.gallery),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: size / 3, color: AppTheme.primary),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
