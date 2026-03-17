import 'package:dermascan/core/services/middlewares/auth_middleware.dart';
import 'package:dermascan/core/services/middlewares/doctor_middleware.dart';
import 'package:dermascan/features/auth/bindings/auth_bindings.dart';
import 'package:dermascan/features/auth/screens/login/login_screen.dart';
import 'package:dermascan/features/doctor/home/bindings/home_bindings.dart';
import 'package:dermascan/features/doctor/home/screens/home_view.dart';
import 'package:dermascan/features/doctor/init/bindings/init_bindings.dart';
import 'package:dermascan/features/doctor/init/screens/init_screen.dart';
import 'package:dermascan/features/doctor/init/screens/invitations_screen.dart';
import 'package:dermascan/features/doctor/patients/bindings/patients_bindings.dart';
import 'package:dermascan/features/doctor/patients/screens/create_patient_screen.dart';
import 'package:dermascan/features/doctor/patients/screens/patient_details_screen.dart';
import 'package:dermascan/features/doctor/practice/bindings/practice_bindings.dart';
import 'package:dermascan/features/doctor/practice/screens/practice_details_screen.dart';
import 'package:dermascan/features/practice/doctors/bindings/doctors_bindings.dart';
import 'package:dermascan/features/practice/doctors/screens/assigned_doctors_screen.dart';
import 'package:dermascan/features/practice/doctors/screens/available_doctors_screen.dart';
import 'package:dermascan/features/practice/doctors/screens/doctor_details_screen.dart';
import 'package:dermascan/features/practice/doctors/screens/pending_invitations_screen.dart';
import 'package:dermascan/features/practice/home/bindings/home_bindings.dart';
import 'package:dermascan/features/practice/home/screens/home_view.dart';
import 'package:dermascan/features/splash/bindings/splash_bindings.dart';
import 'package:dermascan/features/splash/screens/splash_screen.dart';
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

    // Doctor - Screens
    GetPage<dynamic>(
      name: '/doctor/home',
      page: () => DoctorHomeScreen(),
      binding: DoctorHomeBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware(), DoctorMiddleware()],
    ),
    GetPage<dynamic>(
      name: '/doctor/init',
      page: () => DoctorInitScreen(),
      binding: DoctorInitBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware(), DoctorMiddleware()],
    ),
    GetPage<dynamic>(
      name: '/doctor/invitations',
      page: () => InvitationsScreen(),
      binding: DoctorInitBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware(), DoctorMiddleware()],
    ),
    GetPage<dynamic>(
      name: '/doctor/practice-details',
      page: () => PracticeDetailsScreen(),
      binding: DoctorInitBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware(), DoctorMiddleware()],
    ),
    GetPage<dynamic>(
      name: '/doctor/create-new-patient',
      page: () => CreatePatientScreen(),
      binding: PatientsBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware(), DoctorMiddleware()],
    ),
    GetPage<dynamic>(
      name: '/doctor/patient-details',
      page: () => PatientDetailsScreen(),
      binding: PatientsBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware(), DoctorMiddleware()],
    ),

    // Practice - Screens
    GetPage<dynamic>(
      name: '/practice/home',
      page: () => PracticeHomeScreen(),
      binding: PracticeHomeBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: '/practice/assigned-doctors',
      page: () => AssignedDoctorsScreen(),
      binding: DoctorsBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: '/practice/available-doctors',
      page: () => AvailableDoctorsScreen(),
      binding: DoctorsBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: '/practice/pending-invitations',
      page: () => PendingInvitationsScreen(),
      binding: DoctorsBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: '/practice/doctor-details',
      page: () => DoctorDetailsScreen(),
      binding: DoctorsBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
  ];
}
