import 'dart:typed_data';

import 'package:dermascan/core/enums.dart';

class Diagnosis {
  final String id;
  final DateTime date;
  final String imagePath;
  final String lesionId;
  final String doctorId;
  final Uint8List? image;

  String? doctorName;
  String notes;


  Diagnosis({
    required this.id,
    required this.date,
    required this.imagePath,
    required this.lesionId,
    required this.doctorId,
    required this.image,
    this.doctorName,
    required this.notes,
  });

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    return Diagnosis(
      id: json['diagnosis_id'] as String,
      notes: json['notes'] as String,
      date: DateTime.parse(json['date'] as String).toLocal(),
      imagePath: json['image_path'] as String,
      lesionId: json['lesion_id'] as String,
      doctorId: json['doctor_id'] as String,
      image: json['image'] as Uint8List?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'diagnosis_id': id,
      'notes': notes,
      'date': date.toIso8601String(),
      'image_path': imagePath,
      'lesion_id': lesionId,
      'doctor_id': doctorId,
    };
  }
}
