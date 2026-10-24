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
  String locationName;
  String testResult;
  String notes;

  BodyLesion({
    required this.id,
    required this.patientId,
    required this.diagnoses,
    required this.isSuspicious,
    required this.position,
    required this.normal,
    required this.locationName,
    required this.testResult,
    required this.wasRemoved,
    required this.notes,
  });

  factory BodyLesion.fromJson(Map<String, dynamic> json) {
    return BodyLesion(
      id: json['lesion_id'] as String,
      locationName: json['location_name'] as String,
      position: json['position'] as String,
      normal: json['normal'] as String,
      patientId: json['patient_id'] as String,
      diagnoses: (json['diagnoses'] as List<dynamic>?)
              ?.map(
                (dynamic item) =>
                    Diagnosis.fromJson(item as Map<String, dynamic>),
              )
              .toList()
              .obs ??
          <Diagnosis>[].obs,
      isSuspicious: (json['suspicious'] as bool).obs,
      wasRemoved: (json['was_removed'] as bool).obs,
      testResult: json['test_result'] as String,
      notes: json['notes'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'lesion_id': id,
      'location_name': locationName,
      'position': position,
      'normal': normal,
      'patient_id': patientId,
      'suspicious': isSuspicious.value,
      'notes': notes,
      'test_result': testResult,
      'was_removed': wasRemoved.value,
      'diagnoses': diagnoses.map((Diagnosis d) => d.toJson()).toList(),
    };
  }
}
