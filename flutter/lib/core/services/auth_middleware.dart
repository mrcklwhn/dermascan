import 'package:dermascan/core/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final AuthService authService = Get.find<AuthService>();

    if (kDebugMode) {
      print('Route Destination: $route');
      print('AuthService status (userLoggedIn): ${authService.isLoggedIn}');
    }

    if (!authService.isLoggedIn) {
      if (kDebugMode) {
        print('Forbidden route! Redirecting to /auth');
      }
      return const RouteSettings(name: '/auth');
    }

    return null;
  }
}
