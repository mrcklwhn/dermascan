import 'package:dermascan/core/models/patient.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/encryption_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientDbService extends GetxService {
  final AuthService authService = Get.find<AuthService>();
  final EncryptionService encryptionService = Get.find<EncryptionService>();

  Future<Patient?> createPatientProfile({
    required String practiceId,
    required String name,
    required DateTime dateOfBirth,
    required String gender,
    required bool previousCancerSurgeries,
    required bool sunscreenUse,
    required bool personalHistoryMelanoma,
    required bool familyHistoryMelanoma,
    required bool tanningBedExposure,
    required bool previousSkinSurgeries,
    required bool previousSunburns,
    required String birthCountry,
    required String currentCountry,
  }) async {
    try {
      final String? key = await encryptionService.getPracticeKey(
        practiceId: practiceId,
      );
      if (key == null) throw Exception('No encryption key found for practice.');

      final Map<String, Object> encryptedData = _encryptPatient(
        practiceId: practiceId,
        name: name,
        dateOfBirth: dateOfBirth,
        gender: gender,
        previousCancerSurgeries: previousCancerSurgeries,
        sunscreenUse: sunscreenUse,
        personalHistoryMelanoma: personalHistoryMelanoma,
        familyHistoryMelanoma: familyHistoryMelanoma,
        tanningBedExposure: tanningBedExposure,
        previousSkinSurgeries: previousSkinSurgeries,
        previousSunburns: previousSunburns,
        birthCountry: birthCountry,
        currentCountry: currentCountry,
        key: key,
      );

      final PostgrestMap? response = await authService.supabaseClient
          .from('patient')
          .insert(encryptedData)
          .select()
          .maybeSingle();

      if (response != null) {
        return _decryptPatient(item: response, key: key);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return null;
    }
  }

  Future<Patient?> updatePatientProfile({
    required String patientId,
    required String practiceId,
    required String name,
    required DateTime dateOfBirth,
    required String gender,
    required bool previousCancerSurgeries,
    required bool sunscreenUse,
    required bool personalHistoryMelanoma,
    required bool familyHistoryMelanoma,
    required bool tanningBedExposure,
    required bool previousSkinSurgeries,
    required bool previousSunburns,
    required String birthCountry,
    required String currentCountry,
  }) async {
    try {
      final String? key = await encryptionService.getPracticeKey(
        practiceId: practiceId,
      );
      if (key == null) throw Exception('No encryption key found for practice.');

      final Map<String, Object> encryptedData = _encryptPatient(
        practiceId: practiceId,
        name: name,
        dateOfBirth: dateOfBirth,
        gender: gender,
        previousCancerSurgeries: previousCancerSurgeries,
        sunscreenUse: sunscreenUse,
        personalHistoryMelanoma: personalHistoryMelanoma,
        familyHistoryMelanoma: familyHistoryMelanoma,
        tanningBedExposure: tanningBedExposure,
        previousSkinSurgeries: previousSkinSurgeries,
        previousSunburns: previousSunburns,
        birthCountry: birthCountry,
        currentCountry: currentCountry,
        key: key,
      );

      final PostgrestMap? response = await authService.supabaseClient
          .from('patient')
          .update(encryptedData)
          .eq('patient_id', patientId)
          .select()
          .maybeSingle();

      if (response != null) {
        return _decryptPatient(item: response, key: key);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return null;
    }
  }

  Future<bool> deletePatientProfile({required String patientId}) async {
    try {
      await authService.supabaseClient
          .from('patient')
          .delete()
          .eq('patient_id', patientId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return false;
    }
  }

  Future<List<Patient>> fetchPatients({required String practiceId}) async {
    try {
      final String? key = await encryptionService.getPracticeKey(
        practiceId: practiceId,
      );
      if (key == null) throw Exception('No encryption key found for practice.');

      final PostgrestList response = await authService.supabaseClient
          .from('patient')
          .select()
          .eq('practice_id', practiceId);

      return response.map<Patient>((Map<String, dynamic> item) {
        return _decryptPatient(item: item, key: key);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return <Patient>[];
    }
  }

  Map<String, Object> _encryptPatient({
    required String practiceId,
    required String name,
    required DateTime dateOfBirth,
    required String gender,
    required bool previousCancerSurgeries,
    required bool sunscreenUse,
    required bool personalHistoryMelanoma,
    required bool familyHistoryMelanoma,
    required bool tanningBedExposure,
    required bool previousSkinSurgeries,
    required bool previousSunburns,
    required String birthCountry,
    required String currentCountry,
    required String key,
  }) {
    return <String, Object>{
      'practice_id': practiceId,
      'name': encryptionService.encryptData(
        plainText: name,
        base64Key: key,
      ),
      'date_of_birth': encryptionService.encryptData(
        plainText: dateOfBirth.toIso8601String().split('T').first,
        base64Key: key,
      ),
      'gender': encryptionService.encryptData(
        plainText: gender,
        base64Key: key,
      ),
      'previous_cancer_surgeries': previousCancerSurgeries,
      'sunscreen_use': sunscreenUse,
      'personal_history_melanoma': personalHistoryMelanoma,
      'family_history_melanoma': familyHistoryMelanoma,
      'tanning_bed_exposure': tanningBedExposure,
      'previous_skin_surgeries': previousSkinSurgeries,
      'previous_sunburns': previousSunburns,
      'birth_country': encryptionService.encryptData(
        plainText: birthCountry,
        base64Key: key,
      ),
      'current_country': encryptionService.encryptData(
        plainText: currentCountry,
        base64Key: key,
      ),
    };
  }

  Patient _decryptPatient({
    required Map<String, dynamic> item,
    required String key,
  }) {
    final String name = encryptionService.decryptData(
      encryptedText: item['name'] as String,
      base64Key: key,
    );
    final String dateOfBirth = encryptionService.decryptData(
      encryptedText: item['date_of_birth'] as String,
      base64Key: key,
    );
    final String gender = encryptionService.decryptData(
      encryptedText: item['gender'] as String,
      base64Key: key,
    );
    final String birthCountry = encryptionService.decryptData(
      encryptedText: item['birth_country'] as String,
      base64Key: key,
    );
    final String currentCountry = encryptionService.decryptData(
      encryptedText: item['current_country'] as String,
      base64Key: key,
    );

    return Patient.fromJson(<String, dynamic>{
      ...item,
      'name': name,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'birth_country': birthCountry,
      'current_country': currentCountry,
    });
  }
}
