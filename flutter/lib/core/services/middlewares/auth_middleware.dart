import 'package:dermascan/core/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final AuthService authService = Get.find<AuthService>();

    if (kDebugMode) {
      debugPrint('[AUTH_MIDDLEWARE] Route Destination: $route');
      debugPrint(
        '[AUTH_MIDDLEWARE] AuthService status (userLoggedIn): ${authService.isLoggedIn}',
      );
    }

    if (!authService.isLoggedIn) {
      if (route != '/auth/login') {
        if (kDebugMode) {
          debugPrint('[AUTH_MIDDLEWARE] Forbidden route! Redirecting to /auth');
        }
        return const RouteSettings(name: '/auth/login');
      }
    }

    if (!authService.isInitialDataLoaded.value) {
      if (route != '/splash') {
        if (kDebugMode) {
          debugPrint(
            '[AUTH_MIDDLEWARE] Initial Data not loaded yet! Redirecting to /splash',
          );
        }
        return const RouteSettings(name: '/splash');
      }
    }

    return null;
  }
}
