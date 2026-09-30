import 'package:dermascan/app/app_theme.dart';
import 'package:flutter/material.dart';

class CustomIcon extends StatelessWidget {
  final IconData iconData;
  final Color? color;
  final double? size;

  const CustomIcon({super.key, required this.iconData, this.color, this.size = 55});

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, size: size, color: effectiveColor),
    );
  }
}
