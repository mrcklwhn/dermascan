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
      id: json['id'] as String,
      name: json['name'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      gender: Gender.values.byName(json['gender'] as String),
      practiceId: json['practiceId'] as String,
      birthCountry: json['birthCountry'] as String,
      currentCountry: json['currentCountry'] as String,
      tanningBedExposure: json['tanningBedExposure'] as bool,
      previousSkinSurgeries: json['previousSkinSurgeries'] as bool,
      previousSunburns: json['previousSunburns'] as bool,
      previousCancerSurgeries: json['previousCancerSurgeries'] as bool,
      sunscreenUse: json['sunscreenUse'] as bool,
      personalHistoryMelanoma: json['personalHistoryMelanoma'] as bool,
      familyHistoryMelanoma: json['familyHistoryMelanoma'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender.name,
      'practiceId': practiceId,
      'birthCountry': birthCountry,
      'currentCountry': currentCountry,
      'tanningBedExposure': tanningBedExposure,
      'previousSkinSurgeries': previousSkinSurgeries,
      'previousSunburns': previousSunburns,
      'previousCancerSurgeries': previousCancerSurgeries,
      'sunscreenUse': sunscreenUse,
      'personalHistoryMelanoma': personalHistoryMelanoma,
      'familyHistoryMelanoma': familyHistoryMelanoma,
    };
  }
}
