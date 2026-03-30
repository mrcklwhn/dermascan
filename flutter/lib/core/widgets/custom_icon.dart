import 'package:dermascan/app/app_theme.dart';
import 'package:flutter/material.dart';

class CustomIcon extends StatelessWidget {
  final IconData iconData;

  const CustomIcon({super.key, required this.iconData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, size: 55),
    );
  }
}
