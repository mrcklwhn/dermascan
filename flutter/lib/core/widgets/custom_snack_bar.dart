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
      style: Theme.of(Get.context!).textTheme.titleSmall?.copyWith(
        color: Theme.of(Get.context!).colorScheme.onSecondary,
      ),
    ),
    messageText: Text(
      message,
      style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
        color: Theme.of(Get.context!).colorScheme.onSecondary,
      ),
    ),
    borderRadius: AppTheme.radiusMedium,
    backgroundColor: Theme.of(Get.context!).colorScheme.secondary,
    overlayColor: Theme.of(Get.context!).colorScheme.onSecondary.withValues(alpha: 0.2),
    icon: Icon(
      icon ?? Icons.info,
      color: Theme.of(Get.context!).colorScheme.onSecondary,
    ),
  );
}
