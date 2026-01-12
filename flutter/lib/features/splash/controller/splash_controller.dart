import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashController extends GetxController {
  String _targetRoute = '/auth';

  AuthService authService = Get.find<AuthService>();
  DBService dbService = Get.find<DBService>();

  @override
  Future<void> onReady() async {
    super.onReady();
    await _initializeData();
    _pushCorrespondingScreen();
  }

  Future<void> _initializeData() async {
    try {
      final Session? session = authService.supabaseClient.auth.currentSession;

      if (session == null || session.user.email == null) {
        _targetRoute = '/auth';
        return;
      }

      final String email = session.user.email!;

      final bool isDoctor = await dbService.checkDoctorEmail(email);
      if (isDoctor) {
        _targetRoute = '/doctor/home';
        return;
      }

      final bool isPractice = await dbService.checkPracticeEmail(email);
      if (isPractice) {
        _targetRoute = '/practice/home';
        return;
      }

      if (kDebugMode) {
        debugPrint('User logged in ($email), but role not found in DB.');
      }

      await Supabase.instance.client.auth.signOut();
      _targetRoute = '/auth';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error while initializing: $e');
      }
      _targetRoute = '/auth';
    }
  }

  void _pushCorrespondingScreen() {
    Get.offAllNamed(_targetRoute);
  }
}
