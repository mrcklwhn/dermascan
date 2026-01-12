import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends GetxService {
  final SupabaseClient supabaseClient = Supabase.instance.client;
  final Rx<User?> currentUser = Rx<User?>(null);

  bool get isLoggedIn => supabaseClient.auth.currentSession != null;

  @override
  void onInit() {
    super.onInit();
    currentUser.value = supabaseClient.auth.currentUser;

    supabaseClient.auth.onAuthStateChange.listen((AuthState data) {
      currentUser.value = data.session?.user;
    });
  }

  @override
  void onReady() {
    super.onReady();
    // Listen for global authentication state changes
    ever(currentUser, (User? user) {
      if (user == null) {
        // Force navigation to auth on logout or session expiry.
        Get.offAllNamed('/auth');
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

  Future<void> signOut() async {
    await supabaseClient.auth.signOut();
  }
}
