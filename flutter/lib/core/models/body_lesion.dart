import 'package:dermascan/core/models/diagnosis.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

class BodyLesion {
  final String id;
  final String location;
  final String patientId;
  final RxList<Diagnosis> diagnoses;

  RxBool isSuspicious;

  BodyLesion({
    required this.id,
    required this.location,
    required this.patientId,
    required this.diagnoses,
    required this.isSuspicious,
  });

  factory BodyLesion.fromJson(Map<String, dynamic> json) {
    return BodyLesion(
      id: json['id'] as String,
      location: json['location'] as String,
      patientId: json['patientId'] as String,
      diagnoses: (json['diagnoses'] as List<dynamic>)
          .map(
            (dynamic item) => Diagnosis.fromJson(item as Map<String, dynamic>),
          )
          .toList()
          .obs,
      isSuspicious: (json['suspicious'] as bool).obs,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'location': location,
      'patientId': patientId,
      'suspicious': isSuspicious,
      'diagnoses': diagnoses.map((Diagnosis d) => d.toJson()).toList(),
    };
  }
}
