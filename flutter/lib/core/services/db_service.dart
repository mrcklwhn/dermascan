import 'dart:convert';

import 'package:dermascan/app/constants.dart';
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
        final Map<String, dynamic> json = jsonDecode(response.body);
        if (json.containsKey('exists') && json['exists'] is bool) {
          return json['exists'];
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

  Future<bool> createDoctorProfile({
    required String name,
    DateTime? dateOfBirth,
    String? gender,
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
}
