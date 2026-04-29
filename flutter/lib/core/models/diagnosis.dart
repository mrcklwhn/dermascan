class Diagnosis {
  final String id;
  final String notes;
  final DateTime date;
  final String imageLink;
  final String lesionId;
  final String doctorId;
  final String classificationResult;
  final double aScore;
  final double bScore;
  final double cScore;

  Diagnosis({
    required this.id,
    required this.notes,
    required this.date,
    required this.imageLink,
    required this.lesionId,
    required this.doctorId,
    required this.classificationResult,
    required this.aScore,
    required this.bScore,
    required this.cScore,
  });

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    return Diagnosis(
      id: json['id'] as String,
      notes: json['notes'] as String,
      date: DateTime.parse(json['date'] as String),
      imageLink: json['imageLink'] as String,
      lesionId: json['lesionId'] as String,
      doctorId: json['doctorId'] as String,
      classificationResult: json['classificationResult'] as String,
      aScore: (json['aScore'] as num).toDouble(),
      bScore: (json['bScore'] as num).toDouble(),
      cScore: (json['cScore'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'notes': notes,
      'date': date.toIso8601String(),
      'imageLink': imageLink,
      'lesionId': lesionId,
      'doctorId': doctorId,
      'classificationResult': classificationResult,
      'aScore': aScore,
      'bScore': bScore,
      'cScore': cScore,
    };
  }
}
