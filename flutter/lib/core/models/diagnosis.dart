import 'dart:typed_data';

import 'package:dermascan/app/enums.dart';

class Diagnosis {
  final String id;
  final DateTime date;
  final String imagePath;
  final String lesionId;
  final String doctorId;
  final Uint8List image;

  String? doctorName;
  CutoutType cutoutType;
  double aScore;
  double bScore;
  double cScore;
  String notes;
  double confidence;
  LesionType prediction;

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
    required this.image,
    required this.prediction,
    required this.confidence,
  });

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    return Diagnosis(
      id: json['id'] as String,
      notes: json['notes'] as String,
      date: DateTime.parse(json['date'] as String).toLocal(),
      imagePath: json['imagePath'] as String,
      lesionId: json['lesionId'] as String,
      doctorId: json['doctorId'] as String,
      cutoutType: CutoutType.values.firstWhere(
        (CutoutType type) => type.name == (json['cutoutType'] as String),
      ),
      aScore: json['aScore'] as double? ?? 0.0,
      bScore: json['bScore'] as double? ?? 0.0,
      cScore: json['cScore'] as double? ?? 0.0,
      image: json['image'] as Uint8List,
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
      'cutoutType': cutoutType.name,
      'aScore': aScore,
      'bScore': bScore,
      'cScore': cScore,
      'prediction': prediction,
      'confidence': confidence,
    };
  }
}
