import 'package:dermascan/core/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final AuthService authService = Get.find<AuthService>();

    if (kDebugMode) {
      print('[DOCTOR_MIDDLEWARE] Route Destination: $route');
      print(
        '[DOCTOR_MIDDLEWARE] AuthService status (userLoggedIn): ${authService.isLoggedIn}',
      );
    }
    if (!authService.isLoggedIn) {
      if (route != '/auth/login') {
        if (kDebugMode) {
          print('[DOCTOR_MIDDLEWARE] Forbidden route! Redirecting to /auth');
        }
        return const RouteSettings(name: '/auth/login');
      }
    }
    if (!authService.hasPractice.value) {
      if (route != '/doctor/init' &&
          route != '/doctor/invitations' &&
          route != '/doctor/practice-details') {
        if (kDebugMode) {
          print(
            '[DOCTOR_MIDDLEWARE] Forbidden route! Redirecting to /doctor/init',
          );
        }
        return const RouteSettings(name: '/doctor/init');
      }
    }

    return null;
  }
}
