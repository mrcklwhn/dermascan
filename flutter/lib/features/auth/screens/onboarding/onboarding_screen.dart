import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/features/auth/controller/onboarding/onboarding_controller.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppTheme.scaffoldPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Spacer(flex: 2),
              const CustomIcon(iconData:
                Icons.health_and_safety,
              ),
              const SizedBox(height: AppTheme.spaceLarge),
              Text(
                TrKeys.onboarding.title.tr,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Text(
                TrKeys.onboarding.subtitle.tr,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              _buildRoleCard(
                context: context,
                title: TrKeys.onboarding.iAmDoctor.tr,
                description: TrKeys.onboarding.doctorDesc.tr,
                icon: Icons.person,
                onTap: () => controller.openRoleSelection(isPractice: false),
                isPrimary: true,
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              _buildRoleCard(
                context: context,
                title: TrKeys.onboarding.iAmPractice.tr,
                description: TrKeys.onboarding.practiceDesc.tr,
                icon: Icons.local_hospital,
                onTap: () => controller.openRoleSelection(isPractice: true),
                isPrimary: false,
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    final Color bgColor = isPrimary
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surface;
    final Color iconColor = isPrimary
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: <Widget>[
            CustomIcon(iconData: icon,color: iconColor, size: 32,),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isPrimary ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isPrimary
                          ? Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isPrimary
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
