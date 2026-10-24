import 'package:dermascan/core/models/invitation.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/encryption_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PracticeDbService extends GetxService {
  final AuthService authService = Get.find<AuthService>();
  final EncryptionService encryptionService = Get.find<EncryptionService>();

  Future<bool> createPracticeProfile({
    required String name,
    required String keyVerifier,
  }) async {
    try {
      final User? user = authService.supabaseClient.auth.currentUser;
      if (user == null) return false;

      await authService.supabaseClient
          .from('practice')
          .insert(<String, String?>{
            'practice_id': user.id,
            'name': name,
            'email': user.email,
            'key_verifier': keyVerifier,
          });
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return false;
    }
  }

  Future<Practice?> fetchPractice({required String id}) async {
    try {
      final PostgrestMap? response = await authService.supabaseClient
          .from('practice')
          .select()
          .eq('practice_id', id)
          .maybeSingle();

      if (response != null) {
        return Practice.fromJson(response);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return null;
    }
  }

  Future<List<PracticeInvitation>> fetchInvitedDoctors({
    required String practiceId,
  }) async {
    try {
      final PostgrestList response = await authService.supabaseClient
          .from('practice_invitation')
          .select('*, practice(*), doctor(*)')
          .eq('practice_id', practiceId);

      return response.map<PracticeInvitation>((Map<String, dynamic> item) => PracticeInvitation.fromJson(item)
      ).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return <PracticeInvitation>[];
    }
  }

  Future<List<PracticeInvitation>> fetchInvitingPractices({
    required String doctorId,
  }) async {
    try {
      final PostgrestList response = await authService.supabaseClient
          .from('practice_invitation')
          .select('*, practice(*), doctor(*)')
          .eq('doctor_id', doctorId);

      return response.map<PracticeInvitation>((Map<String, dynamic> item) => PracticeInvitation.fromJson(item)
      ).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return <PracticeInvitation>[];
    }
  }

  Future<bool> inviteDoctorToPractice({
    required String practiceId,
    required String doctorId,
  }) async {
    try {
      await authService.supabaseClient.from('practice_invitation').insert(<String, String>{
        'practice_id': practiceId,
        'doctor_id': doctorId,
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return false;
    }
  }

  Future<bool> revokePracticeInvitation({
    required String practiceId,
    required String doctorId,
  }) async {
    try {
      await authService.supabaseClient
          .from('practice_invitation')
          .delete()
          .eq('practice_id', practiceId)
          .eq('doctor_id', doctorId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return false;
    }
  }

  Future<bool> acceptPracticeInvitation({required String practiceId}) async {
    try {
      await authService.supabaseClient.rpc(
        'accept_practice_invitation',
        params: <String, dynamic>{'p_practice_id': practiceId},
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return false;
    }
  }

  Future<bool> leaveCurrentPractice({required String doctorId}) async {
    try {
      await authService.supabaseClient.rpc(
        'remove_doctor_from_practice',
        params: <String, dynamic>{'p_doctor_id': doctorId},
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return false;
    }
  }

  Future<Practice?> changePracticeName({
    required String practiceId,
    required String newName,
  }) async {
    try {
      final PostgrestMap? response = await authService.supabaseClient
          .from('practice')
          .update(<dynamic, dynamic>{'name': newName})
          .eq('practice_id', practiceId)
          .select()
          .maybeSingle();

      if (response != null) {
        return Practice.fromJson(response);
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
