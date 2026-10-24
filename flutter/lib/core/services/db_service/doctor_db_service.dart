import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/encryption_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorDbService extends GetxService {
  final AuthService authService = Get.find<AuthService>();
  final EncryptionService encryptionService = Get.find<EncryptionService>();

  Future<bool> createDoctorProfile({
    required String name,
    required DateTime? dateOfBirth,
    required String gender,
  }) async {
    try {
      final User? user = authService.supabaseClient.auth.currentUser;
      if (user == null) return false;

      await authService.supabaseClient.from('doctor').insert(<String, String?>{
        'doctor_id': user.id,
        'email': user.email,
        'name': name,
        'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
        'gender': gender,
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return false;
    }
  }

  Future<Doctor?> fetchDoctor({required String id}) async {
    try {
      final PostgrestMap? response = await authService.supabaseClient
          .from('doctor')
          .select()
          .eq('doctor_id', id)
          .maybeSingle();

      if (response != null) {
        return Doctor.fromJson(response);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return null;
    }
  }

  Future<List<Doctor>> fetchDoctors({required String? practiceId}) async {
    try {
      final PostgrestList response = practiceId == null
          ? await authService.supabaseClient
              .from('doctor')
              .select()
              .isFilter('practice_id', null)
          : await authService.supabaseClient
              .from('doctor')
              .select()
              .eq('practice_id', practiceId);

      return response.map<Doctor>((Map<String, dynamic> item) {
        return Doctor.fromJson(item);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return <Doctor>[];
    }
  }

  Future<Practice?> checkDoctorHasPractice() async {
    try {
      final String? userId = authService.supabaseClient.auth.currentUser?.id;
      if (userId == null) return null;

      final PostgrestMap? response = await authService.supabaseClient
          .from('doctor')
          .select('practice(*)')
          .eq('doctor_id', userId)
          .maybeSingle();

      if (response != null && response['practice'] != null) {
        final Map<String, dynamic> practiceData = response['practice'] as Map<String, dynamic>;
        return Practice.fromJson(practiceData);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return null;
    }
  }

  Future<Doctor?> changeDoctorName({
    required String doctorId,
    required String newName,
  }) async {
    try {
      final PostgrestMap? response = await authService.supabaseClient
          .from('doctor')
          .update(<dynamic, dynamic>{'name': newName})
          .eq('doctor_id', doctorId)
          .select()
          .maybeSingle();

      if (response != null) {
        return Doctor.fromJson(response);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return null;
    }
  }
}
