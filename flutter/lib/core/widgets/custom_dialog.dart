import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String submitText;
  final bool isDismissable;
  final VoidCallback? onSubmit;

  const CustomDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isDismissable,
    required this.onSubmit,
    required this.submitText,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.highlightColor,
      child: PopScope(
        canPop: isDismissable,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Center(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (isDismissable) ...<Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: Get.back,
                        child: const Text('Dismiss'),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMedium),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onSubmit,
                      child: Text(submitText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomLogoutDialog extends GetWidget<AuthService> {
  const CustomLogoutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.highlightColor,
      child: PopScope(
        canPop: true,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Center(
                child: Text(
                  'Logout?',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Text(
                'You are about to log out of your account. Are you sure you want to proceed?',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: Get.back,
                      child: const Text('Dismiss'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMedium),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => controller.signOut(),
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
