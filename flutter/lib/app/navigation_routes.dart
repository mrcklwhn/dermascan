import 'package:dermascan/core/services/auth_middleware.dart';
import 'package:dermascan/features/auth/bindings/auth_bindings.dart';
import 'package:dermascan/features/auth/views/login/login_screen.dart';
import 'package:dermascan/features/doctor/home/bindings/home_bindings.dart';
import 'package:dermascan/features/doctor/home/views/home_view.dart';
import 'package:dermascan/features/practice/home/bindings/home_bindings.dart';
import 'package:dermascan/features/practice/home/views/home_view.dart';
import 'package:dermascan/features/splash/bindings/splash_bindings.dart';
import 'package:dermascan/features/splash/views/splash_screen.dart';
import 'package:get/get.dart';

class NavigationRoutes {
  static List<GetPage<dynamic>> getRoutes = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: '/splash',
      page: () => SplashScreen(),
      binding: SplashBindings(),
    ),
    GetPage<dynamic>(
      name: '/auth',
      page: () => LoginScreen(),
      binding: AuthBindings(),
    ),
    GetPage<dynamic>(
      name: '/doctor/home',
      page: () => DoctorHomeScreen(),
      binding: DoctorHomeBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: '/practice/home',
      page: () => PracticeHomeScreen(),
      binding: PracticeHomeBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
  ];
}
