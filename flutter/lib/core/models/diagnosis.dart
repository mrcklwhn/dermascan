import 'dart:typed_data';

import 'package:dermascan/core/enums.dart';

class Diagnosis {
  final String id;
  final DateTime date;
  final String imagePath;
  final String lesionId;
  final String doctorId;
  String? doctorName;
  CutoutType cutoutType;
  double aScore;
  double bScore;
  double cScore;
  String notes;

  final Map<String, Uint8List?>? analyzedImages;

  Diagnosis({
    required this.id,
    required this.notes,
    required this.date,
    required this.imagePath,
    required this.lesionId,
    required this.doctorId,
    this.doctorName,
    required this.cutoutType,
    required this.aScore,
    required this.bScore,
    required this.cScore,
    required this.analyzedImages,
  });

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    return Diagnosis(
      id: json['diagnosis_id'] as String,
      notes: json['notes'] as String,
      date: DateTime.parse(json['date'] as String).toLocal(),
      imagePath: json['image_path'] as String,
      lesionId: json['lesion_id'] as String,
      doctorId: json['doctor_id'] as String,
      cutoutType: CutoutType.values.firstWhere(
        (CutoutType type) => type.name == (json['cutout_type'] as String),
      ),
      aScore: (json['a_score'] as num?)?.toDouble() ?? 0.0,
      bScore: (json['b_score'] as num?)?.toDouble() ?? 0.0,
      cScore: (json['c_score'] as num?)?.toDouble() ?? 0.0,
      analyzedImages: json['analyzedImages'] as Map<String, Uint8List?>?,
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
      'cutout_type': cutoutType.name,
      'a_score': aScore,
      'b_score': bScore,
      'c_score': cScore,
    };
  }
}
