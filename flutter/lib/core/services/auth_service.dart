import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends GetxService {
  final SupabaseClient supabaseClient = Supabase.instance.client;
  final Rx<User?> currentUser = Rx<User?>(null);

  final Rx<Practice?> currentPractice = Rx<Practice?>(null);

  final Rx<Doctor?> currentDoctor = Rx<Doctor?>(null);
  final RxBool hasPractice = false.obs;
  final RxBool isInitialDataLoaded = false.obs;

  bool get isLoggedIn => supabaseClient.auth.currentSession != null;

  Future<void> evaluateRouteAndNavigate() async {
    final User? user = supabaseClient.auth.currentUser;

    if (user == null) {
      await Get.offAllNamed('/auth/login');
      return;
    }

    try {
      final DBService dbService = Get.find<DBService>();
      final Doctor? doctorAccount = await dbService.fetchDoctor(id: user.id);

      if (doctorAccount != null) {
        final Practice? practice = await dbService.checkDoctorHasPractice();

        currentDoctor.value = doctorAccount;
        currentPractice.value = practice;
        hasPractice.value = (practice != null);
        isInitialDataLoaded.value = true;

        await Get.offAllNamed(
          hasPractice.value ? '/doctor/home' : '/doctor/init',
        );
        return;
      }

      final Practice? practiceAccount = await dbService.fetchPractice(
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
      await Get.offAllNamed('/auth/login');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error during navigation: $e! Redirecting to /auth');
      }
      await Get.offAllNamed('/auth/login');
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
        Get.offAllNamed('/auth/login');
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
        print(e);
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
        print(e);
      }
      return null;
    }
  }

  Future<void> signOut() async {
    await supabaseClient.auth.signOut();
  }
}
