import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/db_service/doctor_db_service.dart';
import 'package:dermascan/core/services/db_service/practice_db_service.dart';
import 'package:dermascan/core/services/encryption_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends GetxService {
  final SupabaseClient supabaseClient = Supabase.instance.client;
  final Rx<User?> currentUser = Rx<User?>(null);

  final Rx<Practice?> currentPractice = Rx<Practice?>(null);

  final Rx<Doctor?> currentDoctor = Rx<Doctor?>(null);
  final RxBool isInitialDataLoaded = false.obs;

  bool get isLoggedIn => supabaseClient.auth.currentSession != null;

  Future<void> evaluateRouteAndNavigate() async {
    final User? user = supabaseClient.auth.currentUser;

    if (user == null) {
      await Get.offAllNamed('/auth/onboarding');
      return;
    }

    try {
      final DoctorDbService doctorDbService = Get.find<DoctorDbService>();
      final PracticeDbService practiceDbService = Get.find<PracticeDbService>();
      final Doctor? doctorAccount = await doctorDbService.fetchDoctor(id: user.id);

      if (doctorAccount != null) {
        final Practice? practice = await doctorDbService.checkDoctorHasPractice();

        currentDoctor.value = doctorAccount;
        currentPractice.value = practice;
        isInitialDataLoaded.value = true;

        if (practice != null) {
          final EncryptionService encryptionService = Get.find<EncryptionService>();
          final String? key = await encryptionService.getPracticeKey(practiceId: practice.id);
          if (key == null || !encryptionService.isValidKeyFormat(base64Key: key)) {
            await Get.offAllNamed('/doctor/key-lock');
            return;
          }
          await Get.offAllNamed('/doctor/home');
        } else {
          await Get.offAllNamed('/doctor/init');
        }
        return;
      }

      final Practice? practiceAccount = await practiceDbService.fetchPractice(
        id: user.id,
      );

      if (practiceAccount != null) {
        currentPractice.value = practiceAccount;
        currentDoctor.value = null;
        isInitialDataLoaded.value = true;

        await Get.offAllNamed('/practice/home');
        return;
      }

      isInitialDataLoaded.value = true;
      await Get.offAllNamed('/auth/onboarding');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error during navigation: $e! Redirecting to /auth');
      }
      await Get.offAllNamed('/auth/onboarding');
    }
  }

  @override
  void onInit() {
    super.onInit();
    currentUser.value = supabaseClient.auth.currentUser;

    supabaseClient.auth.onAuthStateChange.listen((AuthState data) {
      currentUser.value = data.session?.user;
      if (data.session?.user == null) {
        currentPractice.value = null;
        currentDoctor.value = null;
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
    // Listen for global authentication state changes
    ever(currentUser, (User? user) {
      if (user == null) {
        // Force navigation to auth on logout or session expiry.
        Get.offAllNamed('/auth/onboarding');
      }
      // Note: Forward navigation (Login) is handled by SplashController
      // to avoid race conditions during app startup.
    });
  }

  Future<bool> register({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
      );
      return response.user != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      final AuthResponse response = await supabaseClient.auth
          .signInWithPassword(email: email, password: password);
      return response.user != null;
    } catch (e) {
      return false;
    }
  }

  Future<UserResponse?> changeEmail({required String newEmail}) async {
    try {
      final UserResponse response = await supabaseClient.auth.updateUser(
        UserAttributes(email: newEmail),
      );
      currentUser.value = response.user;
      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
      return null;
    }
  }

  Future<UserResponse?> changePassword({required String newPassword}) async {
    try {
      final UserResponse response = await supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      currentUser.value = response.user;
      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
      return null;
    }
  }

  Future<void> signOut() async {
    await supabaseClient.auth.signOut();
  }
}
