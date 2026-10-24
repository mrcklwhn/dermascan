import 'package:dermascan/app/enums.dart';

class Patient {
  final String id;
  final String name;
  final DateTime dateOfBirth;
  final Gender gender;
  final String practiceId;
  final String birthCountry;
  final String currentCountry;
  final bool tanningBedExposure;
  final bool previousSkinSurgeries;
  final bool previousSunburns;
  final bool previousCancerSurgeries;
  final bool sunscreenUse;
  final bool personalHistoryMelanoma;
  final bool familyHistoryMelanoma;

  Patient({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    required this.practiceId,
    required this.birthCountry,
    required this.currentCountry,
    required this.tanningBedExposure,
    required this.previousSkinSurgeries,
    required this.previousSunburns,
    required this.previousCancerSurgeries,
    required this.sunscreenUse,
    required this.personalHistoryMelanoma,
    required this.familyHistoryMelanoma,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['patient_id'] as String,
      name: json['name'] as String,
      dateOfBirth: DateTime.parse(json['date_of_birth'] as String),
      gender: Gender.values.byName(json['gender'] as String),
      practiceId: json['practice_id'] as String,
      birthCountry: json['birth_country'] as String,
      currentCountry: json['current_country'] as String,
      tanningBedExposure: json['tanning_bed_exposure'] as bool,
      previousSkinSurgeries: json['previous_skin_surgeries'] as bool,
      previousSunburns: json['previous_sunburns'] as bool,
      previousCancerSurgeries: json['previous_cancer_surgeries'] as bool,
      sunscreenUse: json['sunscreen_use'] as bool,
      personalHistoryMelanoma: json['personal_history_melanoma'] as bool,
      familyHistoryMelanoma: json['family_history_melanoma'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'patient_id': id,
      'name': name,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'gender': gender.name,
      'practice_id': practiceId,
      'birth_country': birthCountry,
      'current_country': currentCountry,
      'tanning_bed_exposure': tanningBedExposure,
      'previous_skin_surgeries': previousSkinSurgeries,
      'previous_sunburns': previousSunburns,
      'previous_cancer_surgeries': previousCancerSurgeries,
      'sunscreen_use': sunscreenUse,
      'personal_history_melanoma': personalHistoryMelanoma,
      'family_history_melanoma': familyHistoryMelanoma,
    };
  }
}
