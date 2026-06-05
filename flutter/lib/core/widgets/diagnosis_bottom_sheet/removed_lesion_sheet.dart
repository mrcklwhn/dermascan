import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:flutter/material.dart';

class RemovedLesionSheet extends StatelessWidget {
  const RemovedLesionSheet({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Lesion Excised',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        Text(
          'This lesion has been excised.\nAll diagnoses are still accessible.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
