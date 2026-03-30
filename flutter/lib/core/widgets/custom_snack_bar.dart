import 'package:dermascan/app/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomSnackBar extends GetSnackBar {
  CustomSnackBar({
    super.key,
    required String title,
    required String message,
    Duration super.duration = const Duration(seconds: 3),
    IconData? icon,
  }) : super(
         snackPosition: SnackPosition.TOP,
         margin: const EdgeInsets.all(AppTheme.spaceSmall),
         padding: const EdgeInsets.all(AppTheme.spaceMedium),
         titleText: Text(
           title,
           style: Theme.of(
             Get.context!,
           ).textTheme.titleSmall?.copyWith(color: AppTheme.white),
         ),
         messageText: Text(
           message,
           style: Theme.of(
             Get.context!,
           ).textTheme.bodySmall?.copyWith(color: AppTheme.white),
         ),
         borderRadius: AppTheme.radiusMedium,
         backgroundColor: AppTheme.secondary,
         overlayColor: AppTheme.white.withValues(alpha: 0.2),
         icon: icon != null
             ? Icon(icon, color: AppTheme.white)
             : const Icon(Icons.info, color: AppTheme.white),
       );
}
