import 'package:dermascan/core/models/diagnosis.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

class BodyLesion {
  final String id;
  final String position;
  final String normal;
  final String patientId;
  final RxList<Diagnosis> diagnoses;

  RxBool wasRemoved;
  RxBool isSuspicious;
  String? locationName;
  String? testResult;
  String? notes;

  BodyLesion({
    required this.id,
    required this.patientId,
    required this.diagnoses,
    required this.isSuspicious,
    required this.position,
    required this.normal,
    this.locationName,
    this.testResult,
    required this.wasRemoved,
    this.notes,
  });

  factory BodyLesion.fromJson(Map<String, dynamic> json) {
    return BodyLesion(
      id: json['id'] as String,
      locationName: json['locationName'] as String?,
      position: json['position'] as String,
      normal: json['normal'] as String,
      patientId: json['patientId'] as String,
      diagnoses: (json['diagnoses'] as List<dynamic>)
          .map(
            (dynamic item) => Diagnosis.fromJson(item as Map<String, dynamic>),
          )
          .toList()
          .obs,
      isSuspicious: (json['suspicious'] as bool).obs,
      wasRemoved: (json['wasRemoved'] as bool).obs,
      testResult: json['testResult'] as String,
      notes: json['notes'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'locationName': locationName,
      'position': position,
      'normal': normal,
      'patientId': patientId,
      'suspicious': isSuspicious,
      'notes': notes,
      'testResult': testResult,
      'wasRemoved': wasRemoved,
      'diagnoses': diagnoses.map((Diagnosis d) => d.toJson()).toList(),
    };
  }
}
