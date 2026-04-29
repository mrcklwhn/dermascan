import 'package:dermascan/core/models/diagnosis.dart';

class Lesion {
  final String id;
  final String location;
  final String patientId;
  final List<Diagnosis> diagnoses;

  Lesion({
    required this.id,
    required this.location,
    required this.patientId,
    required this.diagnoses,
  });

  factory Lesion.fromJson(Map<String, dynamic> json) {
    return Lesion(
      id: json['id'] as String,
      location: json['location'] as String,
      patientId: json['patientId'] as String,
      diagnoses: (json['diagnoses'] as List<dynamic>)
          .map(
            (dynamic item) => Diagnosis.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'location': location,
      'patientId': patientId,
      'diagnoses': diagnoses.map((Diagnosis d) => d.toJson()).toList(),
    };
  }
}
