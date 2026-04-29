import 'package:dermascan/app/enums.dart';

class Doctor {
  final String id;
  final String name;
  final DateTime dateOfBirth;
  final Gender gender;
  final String? practiceId;
  final String email;

  Doctor({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    this.practiceId,
    required this.email,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as String,
      name: json['name'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      gender: Gender.values.byName(json['gender'] as String),
      practiceId: json['practiceId'] as String?,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender.name,
      'practiceId': practiceId,
      'email': email,
    };
  }
}
