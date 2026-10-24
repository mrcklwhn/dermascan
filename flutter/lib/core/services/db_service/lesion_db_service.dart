import 'dart:io';

import 'package:dermascan/core/models/body_lesion.dart';
import 'package:dermascan/core/models/diagnosis.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/encryption_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LesionDbService extends GetxService {
  final AuthService authService = Get.find<AuthService>();
  final EncryptionService encryptionService = Get.find<EncryptionService>();

  Future<String?> _getPracticeKey() async {
    final String? practiceId = authService.currentPractice.value?.id;
    if (practiceId == null) return null;
    return await encryptionService.getPracticeKey(practiceId: practiceId);
  }

  Future<String?> uploadFile({
    required String bucket,
    required String storagePath,
    required File file,
    required String mimeType,
  }) async {
    try {
      final String? key = await _getPracticeKey();
      if (key == null) return null;

      final Uint8List fileBytes = await file.readAsBytes();
      final Uint8List encryptedBytes = encryptionService.encryptBytes(
        plainBytes: fileBytes,
        base64Key: key,
      );

      final String filePath = await authService.supabaseClient.storage
          .from(bucket)
          .uploadBinary(
            storagePath,
            encryptedBytes,
            fileOptions: FileOptions(contentType: mimeType),
          );
      return filePath;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return null;
    }
  }

  Future<Uint8List?> downloadFile({required String filePath}) async {
    try {
      final List<String> segments = filePath.split('/');
      final String bucket = segments[0];
      final String storagePath = segments.sublist(1).join('/');

      final Uint8List bytes = await authService.supabaseClient.storage
          .from(bucket)
          .download(storagePath);

      final String? key = await _getPracticeKey();
      if (key != null) {
        return encryptionService.decryptBytes(
          encryptedBytes: bytes,
          base64Key: key,
        );
      }
      return bytes;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return null;
    }
  }

  Future<bool> deleteFile({
    required String bucket,
    required String storagePath,
  }) async {
    try {
      final List<FileObject> deletedFiles = await authService
          .supabaseClient
          .storage
          .from(bucket)
          .remove(<String>[storagePath]);
      if (deletedFiles.isEmpty) {
        if (kDebugMode) {
          debugPrint('Error: File not found or no permissions.');
        }
        return false;
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return false;
    }
  }

  Future<BodyLesion?> createLesion({
    required String patientId,
    required String locationName,
    required String testResult,
    required String notes,
    required String position,
    required String normal,
    required bool wasRemoved,
  }) async {
    try {
      final String? key = await _getPracticeKey();
      if (key == null) return null;

      final PostgrestMap? response = await authService.supabaseClient
          .from('lesion')
          .insert(<String, Object>{
            'patient_id': patientId,
            'location_name': encryptionService.encryptData(
              plainText: locationName,
              base64Key: key,
            ),
            'test_result': encryptionService.encryptData(
              plainText: testResult,
              base64Key: key,
            ),
            'notes': encryptionService.encryptData(
              plainText: notes,
              base64Key: key,
            ),
            'position': encryptionService.encryptData(
              plainText: position,
              base64Key: key,
            ),
            'normal': encryptionService.encryptData(
              plainText: normal,
              base64Key: key,
            ),
            'was_removed': wasRemoved,
          })
          .select()
          .maybeSingle();

      if (response != null) {
        // Decrypt fields before creating model
        response['location_name'] = encryptionService.decryptData(
          encryptedText: response['location_name'] as String? ?? '',
          base64Key: key,
        );
        response['test_result'] = encryptionService.decryptData(
          encryptedText: response['test_result'] as String? ?? '',
          base64Key: key,
        );
        response['notes'] = encryptionService.decryptData(
          encryptedText: response['notes'] as String? ?? '',
          base64Key: key,
        );
        response['position'] = encryptionService.decryptData(
          encryptedText: response['position'] as String? ?? '',
          base64Key: key,
        );
        response['normal'] = encryptionService.decryptData(
          encryptedText: response['normal'] as String? ?? '',
          base64Key: key,
        );

        return BodyLesion.fromJson(response);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return null;
    }
  }

  Future<bool> updateLesion({
    required String lesionId,
    required String locationName,
    required String testResult,
    required String notes,
    required bool suspicious,
    required bool wasRemoved,
  }) async {
    try {
      final String? key = await _getPracticeKey();
      if (key == null) return false;

      await authService.supabaseClient
          .from('lesion')
          .update(<dynamic, dynamic>{
            'location_name': encryptionService.encryptData(
              plainText: locationName,
              base64Key: key,
            ),
            'test_result': encryptionService.encryptData(
              plainText: testResult,
              base64Key: key,
            ),
            'notes': encryptionService.encryptData(
              plainText: notes,
              base64Key: key,
            ),
            'suspicious': suspicious,
            'was_removed': wasRemoved,
          })
          .eq('lesion_id', lesionId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return false;
    }
  }

  Future<bool> deleteLesion({required String lesionId}) async {
    try {
      await authService.supabaseClient
          .from('lesion')
          .delete()
          .eq('lesion_id', lesionId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return false;
    }
  }

  Future<List<BodyLesion>> fetchLesions({required String? patientId}) async {
    if (patientId == null) return <BodyLesion>[];
    try {
      final String? key = await _getPracticeKey();
      if (key == null) return <BodyLesion>[];

      final PostgrestList responseList = await authService.supabaseClient
          .from('lesion')
          .select('*, diagnoses:diagnosis(*)')
          .eq('patient_id', patientId);

      final List<BodyLesion> parsedLesions = <BodyLesion>[];

      for (final dynamic item in responseList) {
        final Map<String, dynamic> lesionMap = item as Map<String, dynamic>;
        
        lesionMap['location_name'] = encryptionService.decryptData(
          encryptedText: lesionMap['location_name'] as String? ?? '',
          base64Key: key,
        );
        lesionMap['test_result'] = encryptionService.decryptData(
          encryptedText: lesionMap['test_result'] as String? ?? '',
          base64Key: key,
        );
        lesionMap['notes'] = encryptionService.decryptData(
          encryptedText: lesionMap['notes'] as String? ?? '',
          base64Key: key,
        );
        lesionMap['position'] = encryptionService.decryptData(
          encryptedText: lesionMap['position'] as String? ?? '',
          base64Key: key,
        );
        lesionMap['normal'] = encryptionService.decryptData(
          encryptedText: lesionMap['normal'] as String? ?? '',
          base64Key: key,
        );

        final List<dynamic> diagnosesList = (lesionMap['diagnoses'] as List<dynamic>?) ?? <dynamic>[];

        for (final dynamic diagnosisItem in diagnosesList) {
          final Map<String, dynamic> diagnosisMap = diagnosisItem as Map<String, dynamic>;
          diagnosisMap['notes'] = encryptionService.decryptData(
            encryptedText: diagnosisMap['notes'] as String? ?? '',
            base64Key: key,
          );
          
          final String? imagePath = diagnosisMap['imagePath'] as String? ?? diagnosisMap['image_path'] as String?;

          if (imagePath != null && imagePath.isNotEmpty) {
            diagnosisMap['analyzedImages'] = <String, Uint8List?>{
              'original': await downloadFile(filePath: imagePath),
            };
          }
        }

        parsedLesions.add(BodyLesion.fromJson(lesionMap));
      }

      return parsedLesions;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return <BodyLesion>[];
    }
  }

  Future<Diagnosis?> createDiagnosis({required Diagnosis diagnosis}) async {
    try {
      final String? key = await _getPracticeKey();
      if (key == null) return null;

      final PostgrestMap? response = await authService.supabaseClient
          .from('diagnosis')
          .insert(<String, Object>{
            'diagnosis_id': diagnosis.id,
            'date': diagnosis.date.toUtc().toIso8601String(),
            'image_path': diagnosis.imagePath,
            'doctor_id': diagnosis.doctorId,
            'lesion_id': diagnosis.lesionId,
            'a_score': diagnosis.aScore,
            'b_score': diagnosis.bScore,
            'c_score': diagnosis.cScore,
            'cutout_type': diagnosis.cutoutType.name,
            'prediction': diagnosis.prediction.index,
            'confidence': diagnosis.confidence,
            'notes': encryptionService.encryptData(
              plainText: diagnosis.notes,
              base64Key: key,
            ),
          })
          .select()
          .maybeSingle();

      if (response != null) {
        final Map<String, dynamic> responseMap = response;
        responseMap['notes'] = encryptionService.decryptData(
          encryptedText: responseMap['notes'] as String? ?? '',
          base64Key: key,
        );
        responseMap['analyzedImages'] = <String, Uint8List?>{
          'original': await downloadFile(filePath: diagnosis.imagePath),
        };
        return Diagnosis.fromJson(responseMap);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return null;
    }
  }

  Future<bool> updateDiagnosis({
    required String diagnosisId,
    required String notes,
  }) async {
    try {
      final String? key = await _getPracticeKey();
      if (key == null) return false;

      await authService.supabaseClient
          .from('diagnosis')
          .update(<dynamic, dynamic>{
            'notes': encryptionService.encryptData(
              plainText: notes,
              base64Key: key,
            ),
          })
          .eq('diagnosis_id', diagnosisId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return false;
    }
  }

  Future<bool> deleteDiagnosis({required String diagnosisId}) async {
    try {
      await authService.supabaseClient
          .from('diagnosis')
          .delete()
          .eq('diagnosis_id', diagnosisId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return false;
    }
  }
}
