import 'dart:convert';

import 'package:dermascan/app/constants.dart';
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

  Future<bool> checkDoctorEmail(String email) async {
    return _checkEmailInTable(email: email, table: 'doctor');
  }

  Future<bool> checkPracticeEmail(String email) async {
    return _checkEmailInTable(email: email, table: 'practice');
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

  Future<Patient?> createPatientProfile({
    required String practiceId,
    required String name,
    required DateTime? dateOfBirth,
    required String? gender,
    required String email,
  }) async {
    try {
      final FunctionResponse response = await authService
          .supabaseClient
          .functions
          .invoke(
            'create-patient',
            body: <String, String?>{
              'practiceId': practiceId,
              'name': name,
              'dateOfBirth': dateOfBirth?.toIso8601String().split('T').first,
              'gender': gender,
              'email': email,
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
}
