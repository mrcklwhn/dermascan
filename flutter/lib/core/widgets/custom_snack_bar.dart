import 'package:dermascan/app/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomSnackBar extends GetSnackBar {
  CustomSnackBar({
    Key? key,
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
    BuildContext? context,
  }) : this._(
    key: key,
    title: title,
    message: message,
    duration: duration,
    icon: icon,
    theme: Theme.of(context ?? Get.context!),
  );

  CustomSnackBar._({
    super.key,
    required String title,
    required String message,
    required super.duration,
    required ThemeData theme,
    IconData? icon,
  }) : super(
    snackPosition: SnackPosition.TOP,
    margin: const EdgeInsets.all(AppTheme.spaceSmall),
    padding: const EdgeInsets.all(AppTheme.spaceMedium),
    titleText: Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.onSecondary,
      ),
    ),
    messageText: Text(
      message,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSecondary,
      ),
    ),
    borderRadius: AppTheme.radiusMedium,
    backgroundColor: theme.colorScheme.secondary,
    overlayColor: theme.colorScheme.onSecondary.withValues(alpha: 0.2),
    icon: Icon(
      icon ?? Icons.info,
      color: theme.colorScheme.onSecondary,
    ),
  );
}
