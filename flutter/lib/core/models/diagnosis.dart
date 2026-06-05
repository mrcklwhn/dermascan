import 'dart:typed_data';

import 'package:dermascan/app/enums.dart';
import 'package:get/get.dart';

class Diagnosis {
  final String? id;
  final DateTime date;
  final String imagePath;
  final String lesionId;
  final String doctorId;
  String? doctorName;
  CutoutType? cutoutType;
  double? aScore;
  double? bScore;
  double? cScore;

  String notes;
  double? confidence;
  LesionType? prediction;

  final Map<String, Uint8List?>? analyzedImages;

  Diagnosis({
    this.id,
    required this.notes,
    required this.date,
    required this.imagePath,
    required this.lesionId,
    required this.doctorId,
    this.doctorName,
    this.cutoutType,
    this.aScore,
    this.bScore,
    this.cScore,
    this.analyzedImages,
    this.prediction,
    this.confidence,
  });

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    return Diagnosis(
      id: json['id'] as String,
      notes: json['notes'] as String,
      date: DateTime.parse(json['date'] as String).toLocal(),
      imagePath: json['imagePath'] as String,
      lesionId: json['lesionId'] as String,
      doctorId: json['doctorId'] as String,
      cutoutType: CutoutType.values.firstWhereOrNull(
        (CutoutType type) => type.name == (json['cutoutType'] as String),
      ),
      aScore: json['aScore'] as double? ?? 0.0,
      bScore: json['bScore'] as double? ?? 0.0,
      cScore: json['cScore'] as double? ?? 0.0,
      analyzedImages: json['analyzedImages'] as Map<String, Uint8List?>?,
      prediction: LesionType.values[json['prediction'] as int],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'notes': notes,
      'date': date.toIso8601String(),
      'imagePath': imagePath,
      'lesionId': lesionId,
      'doctorId': doctorId,
      'cutoutType': cutoutType?.name,
      'aScore': aScore,
      'bScore': bScore,
      'cScore': cScore,
      'prediction': prediction,
      'confidence': confidence,
    };
  }
}
