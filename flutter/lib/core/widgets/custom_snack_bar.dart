import 'package:dermascan/app/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomSnackBar extends GetSnackBar {
  CustomSnackBar({
    super.key,
    required String title,
    required String message,
    Duration super.duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Color? overlayColor,
    IconData? icon,
  }) : super(
         snackPosition: SnackPosition.TOP,
         titleText: Text(
           title,
           style: const TextStyle(
             color: Colors.black,
             fontWeight: FontWeight.bold,
           ),
         ),
         messageText: Text(
           message,
           style: const TextStyle(color: Colors.black),
         ),
         backgroundColor: backgroundColor ?? AppTheme.secondary,
         overlayColor: overlayColor ?? Colors.black.withValues(alpha: 0.2),
         icon: icon != null
             ? Icon(icon, color: Colors.black)
             : const Icon(Icons.info, color: Colors.black),
       );
}
