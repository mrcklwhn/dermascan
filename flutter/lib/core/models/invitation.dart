import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/models/practice.dart';

class PracticeInvitation {
  final String invitationId;
  final Practice practice;
  final DateTime createdAt;
  final Doctor doctor;

  PracticeInvitation({
    required this.invitationId,
    required this.practice,
    required this.createdAt,
    required this.doctor,
  });

  factory PracticeInvitation.fromJson(Map<String, dynamic> json) {
    return PracticeInvitation(
      invitationId: json['invitationId'] as String,
      practice: Practice.fromJson(json['practice'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      doctor: Doctor.fromJson(json['doctor'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'invitationId': invitationId,
      'practice': practice.toJson(),
      'created_at': createdAt.toIso8601String(),
      'doctor': doctor.toJson(),
    };
  }
}
