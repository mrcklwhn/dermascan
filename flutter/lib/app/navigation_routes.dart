import 'package:dermascan/core/services/middlewares/auth_middleware.dart';
import 'package:dermascan/core/services/middlewares/doctor_middleware.dart';
import 'package:dermascan/features/auth/bindings/auth_bindings.dart';
import 'package:dermascan/features/auth/screens/change_mail_screen.dart';
import 'package:dermascan/features/auth/screens/change_password_screen.dart';
import 'package:dermascan/features/auth/screens/login/login_screen.dart';
import 'package:dermascan/features/auth/screens/onboarding/onboarding_screen.dart';
import 'package:dermascan/features/auth/screens/register/register_screen.dart';
import 'package:dermascan/features/doctor/home/bindings/home_bindings.dart';
import 'package:dermascan/features/doctor/home/screens/home_view.dart';
import 'package:dermascan/features/doctor/init/bindings/init_bindings.dart';
import 'package:dermascan/features/doctor/init/screens/init_screen.dart';
import 'package:dermascan/features/doctor/init/screens/invitations_screen.dart';
import 'package:dermascan/features/doctor/init/screens/key_import_screen.dart';
import 'package:dermascan/features/doctor/init/screens/key_lock_screen.dart';
import 'package:dermascan/features/doctor/patients/bindings/patients_bindings.dart';
import 'package:dermascan/features/doctor/patients/screens/add_patient_screen.dart';
import 'package:dermascan/features/doctor/patients/screens/edit_lesion_screen.dart';
import 'package:dermascan/features/doctor/patients/screens/edit_patient_screen.dart';
import 'package:dermascan/features/doctor/patients/screens/patient_details_screen.dart';
import 'package:dermascan/features/doctor/patients/screens/pdf_export_screen.dart';
import 'package:dermascan/features/help/bindings/help_bindings.dart';
import 'package:dermascan/features/help/screens/documentation_feature_screen.dart';
import 'package:dermascan/features/help/screens/documentation_screen.dart';
import 'package:dermascan/features/practice/doctors/bindings/doctors_bindings.dart';
import 'package:dermascan/features/practice/doctors/screens/available_doctors_screen.dart';
import 'package:dermascan/features/practice/doctors/screens/doctor_details_screen.dart';
import 'package:dermascan/features/practice/doctors/screens/doctors_screen.dart';
import 'package:dermascan/features/practice/doctors/screens/invited_doctors_screen.dart';
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
      name: '/auth/onboarding',
      page: () => const OnboardingScreen(),
      binding: AuthBindings(),
    ),
    GetPage<dynamic>(
      name: '/auth/login',
      page: () => const LoginScreen(),
      binding: AuthBindings(),
    ),
    GetPage<dynamic>(
      name: '/auth/register',
      page: () => const RegisterScreen(),
      binding: AuthBindings(),
    ),
    GetPage<dynamic>(
      name: '/auth/change-mail',
      page: () => const ChangeEmailScreen(),
      binding: AuthBindings(),
    ),
    GetPage<dynamic>(
      name: '/auth/change-password',
      page: () => const ChangePasswordScreen(),
      binding: AuthBindings(),
    ),

    // Help - Documentation
    GetPage<dynamic>(
      name: '/help/documentation',
      page: () => const DocumentationScreen(),
      binding: HelpBindings(),
    ),
    GetPage<dynamic>(
      name: '/help/documentation/detail',
      page: () => const DocumentationFeatureScreen(),
      binding: HelpBindings(),
    ),

    // Doctor - Screens
    GetPage<dynamic>(
      name: '/doctor/home',
      page: () => const DoctorHomeScreen(),
      binding: DoctorHomeBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware(), DoctorMiddleware()],
    ),
    GetPage<dynamic>(
      name: '/doctor/init',
      page: () => const DoctorInitScreen(),
      binding: DoctorInitBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware(), DoctorMiddleware()],
    ),
    GetPage<dynamic>(
      name: '/doctor/key-import',
      page: () => const KeyImportScreen(),
      binding: DoctorInitBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware(), DoctorMiddleware()],
    ),
    GetPage<dynamic>(
      name: '/doctor/key-lock',
      page: () => const KeyLockScreen(),
      binding: DoctorInitBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware(), DoctorMiddleware()],
    ),
    GetPage<dynamic>(
      name: '/doctor/invitations',
      page: () => const InvitationsScreen(),
      binding: DoctorInitBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware(), DoctorMiddleware()],
    ),
    GetPage<dynamic>(
      name: '/doctor/add-new-patient',
      page: () => const AddPatientScreen(),
      binding: PatientsBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware(), DoctorMiddleware()],
    ),
    GetPage<dynamic>(
      name: '/doctor/edit-patient',
      page: () => const EditPatientScreen(),
      binding: PatientsBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware(), DoctorMiddleware()],
    ),
    GetPage<dynamic>(
      name: '/doctor/edit-lesion',
      page: () => const EditLesionScreen(),
      binding: PatientsBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware(), DoctorMiddleware()],
    ),
    GetPage<dynamic>(
      name: '/doctor/patient-details',
      page: () => const PatientDetailsScreen(),
      binding: PatientsBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware(), DoctorMiddleware()],
    ),
    GetPage<dynamic>(
      name: '/doctor/patient-pdf-export/lesions',
      page: () => const PdfExportLesionSelectionScreen(),
      binding: PatientsBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware(), DoctorMiddleware()],
    ),
    // GetPage<dynamic>(
    //   name: '/doctor/patient-pdf-export/lesion',
    //   page: () => const PdfExportLesionDetailScreen(),
    //   binding: PdfExportBindings(),
    //   middlewares: <GetMiddleware>[AuthMiddleware(), DoctorMiddleware()],
    // ),

    // Practice - Screens
    GetPage<dynamic>(
      name: '/practice/home',
      page: () => PracticeHomeScreen(),
      binding: PracticeHomeBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: '/practice/assigned-doctors',
      page: () => const DoctorsScreen(),
      binding: DoctorsBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: '/practice/available-doctors',
      page: () => const AvailableDoctorsScreen(),
      binding: DoctorsBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: '/practice/pending-invitations',
      page: () => const InvitedDoctorsScreen(),
      binding: DoctorsBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: '/practice/doctor-details',
      page: () => const DoctorDetailsScreen(),
      binding: DoctorsBindings(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
  ];
}
