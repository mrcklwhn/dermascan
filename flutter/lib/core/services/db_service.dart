import 'dart:convert';
import 'dart:io';

import 'package:dermascan/app/constants.dart';
import 'package:dermascan/core/models/body_lesion.dart';
import 'package:dermascan/core/models/diagnosis.dart';
import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/models/invitation.dart';
import 'package:dermascan/core/models/patient.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class DBService extends GetxService {
  AuthService authService = Get.find<AuthService>();

  Future<String?> uploadFile({
    required String bucket,
    required String storagePath,
    required File file,
    required String mimeType,
  }) async {
    try {
      final String filePath = await authService.supabaseClient.storage
          .from(bucket)
          .upload(
            storagePath,
            file,
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

      return await authService.supabaseClient.storage
          .from(bucket)
          .download(storagePath);
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

  Future<Diagnosis?> createDiagnosis({required Diagnosis diagnosis}) async {
    try {
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke(
            'create-diagnosis',
            body: <String, dynamic>{
              'date': diagnosis.date.toUtc().toIso8601String(),
              'id': diagnosis.id,
              'imagePath': diagnosis.imagePath,
              'doctorId': diagnosis.doctorId,
              'lesionId': diagnosis.lesionId,
              'aScore': diagnosis.aScore,
              'bScore': diagnosis.bScore,
              'cScore': diagnosis.cScore,
              'cutoutType': diagnosis.cutoutType.name,
              'prediction': diagnosis.prediction.index,
              'confidence': diagnosis.confidence,
              'notes': diagnosis.notes,
            },
          );

      if (response.status == 201) {
        if (response.data != null) {
          final Map<String, dynamic> responseMap = response.data;
          responseMap.addAll(<String, dynamic>{
            'analyzedImages': <String, Uint8List?>{
              'original': await downloadFile(filePath: diagnosis.imagePath),
            },
          });
          return Diagnosis.fromJson(responseMap);
        }
      } else {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
        }
        return null;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return null;
    }
  }

  Future<bool> deleteDiagnosis({required String diagnosisId}) async {
    try {
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke(
            'delete-diagnosis',
            body: <String, String?>{'id': diagnosisId},
          );

      if (response.status != 200) {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
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

  Future<bool> updateDiagnosis({
    required String diagnosisId,
    required String notes,
  }) async {
    try {
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke(
            'update-diagnosis',
            body: <String, dynamic>{'diagnosisId': diagnosisId, 'notes': notes},
          );

      if (response.status != 200) {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
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

  Future<bool> deleteLesion({required String lesionId}) async {
    try {
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke('delete-lesion', body: <String, String?>{'id': lesionId});

      if (response.status != 200) {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
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

  Future<bool> updateLesion({
    required String lesionId,
    required String locationName,
    required String testResult,
    required String notes,
    required bool suspicious,
    required bool wasRemoved,
  }) async {
    try {
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke(
            'update-lesion',
            body: <String, dynamic>{
              'lesionId': lesionId,
              'locationName': locationName,
              'testResult': testResult,
              'wasRemoved': wasRemoved,
              'notes': notes,
              'suspicious': suspicious,
            },
          );

      if (response.status != 200) {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
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
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke(
            'create-lesion',
            body: <String, dynamic>{
              'patientId': patientId,
              'locationName': locationName,
              'position': position,
              'testResult': testResult,
              'wasRemoved': wasRemoved,
              'notes': notes,
              'normal': normal,
            },
          );

      if (response.status == 201) {
        if (response.data != null) {
          final Map<String, dynamic> responseMap = response.data;
          return BodyLesion.fromJson(responseMap);
        }
      } else {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
        }
        return null;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return null;
    }
  }

  Future<bool> acceptPracticeInvitation({required String practiceId}) async {
    try {
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke(
            'accept-practice-invitation',
            body: <String, String?>{'practiceId': practiceId},
          );

      if (response.status != 200) {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
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

  Future<bool> checkDoctorEmail(String email) async {
    return _checkEmailInTable(email: email, table: 'doctor');
  }

  Future<Practice?> checkDoctorHasPractice() async {
    try {
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke('check-doctor-practice');

      if (response.status == 200) {
        // check-doctor-practice return null if doctor isn't assigned to a practice
        if (response.data != null) {
          final Map<String, dynamic> responseMap = response.data;
          return Practice.fromJson(responseMap);
        }
        return null;
      } else {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return null;
    }
  }

  Future<bool> checkPracticeEmail(String email) async {
    return _checkEmailInTable(email: email, table: 'practice');
  }

  Future<bool> createDoctorProfile({
    required String name,
    required DateTime? dateOfBirth,
    required String gender,
  }) async {
    try {
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke(
            'create-doctor',
            body: <String, String?>{
              'name': name,
              'dateOfBirth': dateOfBirth?.toIso8601String().split('T').first,
              'gender': gender,
            },
          );

      if (response.status != 201) {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
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

  Future<bool> deletePatientProfile({required String patientId}) async {
    try {
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke(
            'delete-patient',
            body: <String, String?>{'patientId': patientId},
          );

      if (response.status != 200) {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
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
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke(
            'create-patient',
            body: <String, dynamic>{
              'practiceId': practiceId,
              'name': name,
              'dateOfBirth': dateOfBirth.toIso8601String().split('T').first,
              'gender': gender,
              'previousCancerSurgeries': previousCancerSurgeries,
              'sunscreenUse': sunscreenUse,
              'personalHistoryMelanoma': personalHistoryMelanoma,
              'familyHistoryMelanoma': familyHistoryMelanoma,
              'tanningBedExposure': tanningBedExposure,
              'previousSkinSurgeries': previousSkinSurgeries,
              'previousSunburns': previousSunburns,
              'birthCountry': birthCountry,
              'currentCountry': currentCountry,
            },
          );

      if (response.status == 201) {
        final Map<String, dynamic> responseMap = response.data;
        return Patient.fromJson(responseMap);
      } else {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
        }
        return null;
      }
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
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke(
            'update-patient',
            body: <String, dynamic>{
              'id': patientId,
              'practiceId': practiceId,
              'name': name,
              'dateOfBirth': dateOfBirth.toIso8601String().split('T').first,
              'gender': gender,
              'previousCancerSurgeries': previousCancerSurgeries,
              'sunscreenUse': sunscreenUse,
              'personalHistoryMelanoma': personalHistoryMelanoma,
              'familyHistoryMelanoma': familyHistoryMelanoma,
              'tanningBedExposure': tanningBedExposure,
              'previousSkinSurgeries': previousSkinSurgeries,
              'previousSunburns': previousSunburns,
              'birthCountry': birthCountry,
              'currentCountry': currentCountry,
            },
          );

      if (response.status == 200) {
        final Map<String, dynamic> responseMap = response.data;
        return Patient.fromJson(responseMap);
      } else {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return null;
    }
  }

  Future<bool> createPracticeProfile({required String name}) async {
    try {
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke('create-practice', body: <String, String?>{'name': name});

      if (response.status != 201) {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
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

  Future<Doctor?> fetchDoctor({required String id}) async {
    try {
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke('fetch-doctor-by-id', body: <String, String?>{'id': id});

      if (response.status == 200) {
        final Map<String, dynamic> responseMap = response.data;
        return Doctor.fromJson(responseMap);
      } else {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return null;
    }
  }

  Future<List<Doctor>> fetchDoctors({required String? practiceId}) async {
    try {
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke(
            'fetch-doctors-by-practice',
            body: <String, String?>{'practiceId': practiceId},
          );

      if (response.status == 200) {
        final List<dynamic> responseList = response.data;

        return responseList.map((dynamic item) {
          return Doctor.fromJson(item as Map<String, dynamic>);
        }).toList();
      } else {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
        }
        return <Doctor>[];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return <Doctor>[];
    }
  }

  Future<List<BodyLesion>> fetchLesions({required String? patientId}) async {
    try {
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke(
            'fetch-patient-lesions',
            body: <String, String?>{'patientId': patientId},
          );

      if (response.status == 200) {
        final List<dynamic> responseList = response.data;
        final List<BodyLesion> parsedLesions = <BodyLesion>[];

        for (final dynamic item in responseList) {
          final Map<String, dynamic> lesionMap = item as Map<String, dynamic>;

          final List<dynamic> diagnosesList =
              (lesionMap['diagnoses'] as List<dynamic>?) ?? <dynamic>[];

          for (final dynamic diagnosisItem in diagnosesList) {
            final Map<String, dynamic> diagnosisMap =
                diagnosisItem as Map<String, dynamic>;

            final String? imagePath = diagnosisMap['imagePath'] as String?;

            if (imagePath != null && imagePath.isNotEmpty) {
              diagnosisMap['analyzedImages'] = <String, Uint8List?>{
                'original': await downloadFile(filePath: imagePath),
              };
            }
          }

          parsedLesions.add(BodyLesion.fromJson(lesionMap));
        }

        return parsedLesions;
      } else {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
        }
        return <BodyLesion>[];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return <BodyLesion>[];
    }
  }

  Future<List<PracticeInvitation>> fetchInvitedDoctors({
    required String practiceId,
  }) async {
    try {
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke(
            'fetch-invited-doctors',
            body: <String, String?>{'practiceId': practiceId},
          );

      if (response.status == 200) {
        final List<dynamic> responseList = response.data;

        return responseList.map((dynamic item) {
          return PracticeInvitation.fromJson(item as Map<String, dynamic>);
        }).toList();
      } else {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
        }
        return <PracticeInvitation>[];
      }
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
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke(
            'fetch-inviting-practices',
            body: <String, String?>{'doctorId': doctorId},
          );

      if (response.status == 200) {
        final List<dynamic> responseList = response.data;

        return responseList.map((dynamic item) {
          return PracticeInvitation.fromJson(item as Map<String, dynamic>);
        }).toList();
      } else {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
        }
        return <PracticeInvitation>[];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return <PracticeInvitation>[];
    }
  }

  Future<List<Patient>> fetchPatients({required String practiceId}) async {
    try {
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke(
            'fetch-patients-by-practice',
            body: <String, String?>{'practiceId': practiceId},
          );

      if (response.status == 200) {
        final List<dynamic> responseList = response.data;

        return responseList.map((dynamic item) {
          return Patient.fromJson(item as Map<String, dynamic>);
        }).toList();
      } else {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
        }
        return <Patient>[];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return <Patient>[];
    }
  }

  Future<Practice?> fetchPractice({required String id}) async {
    try {
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke('fetch-practice-by-id', body: <String, String?>{'id': id});

      if (response.status == 200) {
        final Map<String, dynamic> responseMap = response.data;
        return Practice.fromJson(responseMap);
      } else {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return null;
    }
  }

  Future<bool> inviteDoctorToPractice({
    required String practiceId,
    required String doctorId,
  }) async {
    try {
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke(
            'create-practice-invitation',
            body: <String, String?>{
              'practiceId': practiceId,
              'doctorId': doctorId,
            },
          );

      if (response.status != 201) {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
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

  Future<bool> revokePracticeInvitation({
    required String practiceId,
    required String doctorId,
  }) async {
    try {
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke(
            'revoke-practice-invitation',
            body: <String, String?>{
              'practiceId': practiceId,
              'doctorId': doctorId,
            },
          );

      if (response.status != 200) {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
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

  Future<bool> leaveCurrentPractice({required String doctorId}) async {
    try {
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke(
            'leave-assigned-practice',
            body: <String, String?>{'doctorId': doctorId},
          );

      if (response.status != 200) {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
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

  Future<Doctor?> changeDoctorName({required String newName}) async {
    try {
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke(
            'change-doctor-name',
            body: <String, String?>{'newName': newName},
          );

      if (response.status == 200) {
        final Map<String, dynamic> responseMap = response.data;
        return Doctor.fromJson(responseMap);
      } else {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return null;
    }
  }

  Future<Practice?> changePracticeName({required String newName}) async {
    try {
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke(
            'change-practice-name',
            body: <String, String?>{'newName': newName},
          );

      if (response.status == 200) {
        final Map<String, dynamic> responseMap = response.data;
        return Practice.fromJson(responseMap);
      } else {
        if (kDebugMode) {
          debugPrint('Error: ${response.status} - ${response.data}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return null;
    }
  }

  Future<bool> _checkEmailInTable({
    required String email,
    required String table,
  }) async {
    try {
      final http.Response response = await http.post(
        Uri.parse('$edgeFunctionsURL/check-email'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $anonKey',
        },
        body: jsonEncode(<String, String>{'email': email, 'table': table}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseMap = jsonDecode(response.body);
        if (responseMap.containsKey('exists') &&
            responseMap['exists'] is bool) {
          return responseMap['exists'];
        }
        return false;
      } else {
        if (kDebugMode) {
          debugPrint('Error: ${response.statusCode} - ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      return false;
    }
  }
}
