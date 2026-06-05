import 'package:dermascan/app/enums.dart';
import 'package:dermascan/core/models/body_lesion.dart';
import 'package:dermascan/core/models/diagnosis.dart';
import 'package:dermascan/core/models/patient.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';


class ExportablePatientData {
  final Patient patient;
  // final Map<String, ExportableBodyLesionSelection> lesionSelections;

  final RxList<BodyLesion> lesions;
  Map<String, ExportableBodyLesionData> lesionData = <String, ExportableBodyLesionData>{};

  ExportablePatientData({
    required this.patient,
    required this.lesions,
  }) {
    // Initialize lesionData with empty selections for each selected lesion
    for (final BodyLesion lesion in lesions) {
      lesionData[lesion.id] = ExportableBodyLesionData(lesion: lesion);
    }
  }

  // state helpers
  Iterable<ExportableBodyLesionData> get selectedLesions =>
    lesionData.values.where(
      (ExportableBodyLesionData selection) => selection.selectedDiagnoses.isNotEmpty,
    );

  RxBool isLesionSelected(BodyLesion lesion) => lesions.any((BodyLesion item) => item.id == lesion.id).obs;

  RxBool isDiagnosisSelected(BodyLesion lesion, Diagnosis diagnosis) {
    final ExportableBodyLesionData? data = lesionData[lesion.id];
    if (data == null) return false.obs;
    return data.selectedDiagnoses.contains(diagnosis).obs;
  }

  RxBool isMetricSelected(BodyLesion lesion, ExportableDiagnosisMetric metric) {
    final ExportableBodyLesionData? data = lesionData[lesion.id];
    if (data == null) return false.obs;
    return data.selectedMetrics.contains(metric).obs;
  }
  
  RxBool get canExport => lesionData.values.any((ExportableBodyLesionData lesion) => lesion.selectedDiagnoses.isNotEmpty).obs;

  void ensureExportable() {
    if (!canExport.value) {
      throw StateError('At least one diagnosis must be selected before exporting the PDF.');
    }
  }

  // selection management
  void toggleLesionSelection(BodyLesion lesion) {
    if (isLesionSelected(lesion).value == true) {
      lesionData.remove(lesion.id);
    } else {
      lesions.add(lesion);
      lesionData[lesion.id] = ExportableBodyLesionData(
        lesion: lesion,
        selectedDiagnoses: lesion.diagnoses,
      );
    }
  }

  void toggleDiagnosisSelection(BodyLesion lesion, Diagnosis diagnosis) {
    final ExportableBodyLesionData data = lesionData.putIfAbsent(
      lesion.id,
      () => ExportableBodyLesionData(lesion: lesion),
    );

    if (isDiagnosisSelected(lesion, diagnosis).value == true) {
      data.selectedDiagnoses.remove(diagnosis);
    } else {
      data.selectedDiagnoses.add(diagnosis);
    }
  }

  void setDiagnosisSelection(ExportableBodyLesionData draftLesionData) {
    lesionData[draftLesionData.lesion.id] = ExportableBodyLesionData.copyOf(draftLesionData);
  }

  void toggleAllDiagnosesForLesion(ExportableBodyLesionData draftLesionData) {
    final bool allSelected = draftLesionData.selectedDiagnoses.length == draftLesionData.lesion.diagnoses.length;

    if (allSelected) {
      draftLesionData.selectedDiagnoses.clear();
    } else {
      draftLesionData.selectedDiagnoses
        ..clear()
        ..addAll(draftLesionData.lesion.diagnoses);
    }
  }

  void toggleMetricSelection(ExportableBodyLesionData lesionData, ExportableDiagnosisMetric metric) {
    if (lesionData.selectedMetrics.contains(metric)) {
      lesionData.selectedMetrics.remove(metric);
    } else {
      lesionData.selectedMetrics.add(metric);
    }
  }
}

class ExportableBodyLesionData {
  final BodyLesion lesion;
  final RxList<Diagnosis> selectedDiagnoses;
  final RxList<ExportableDiagnosisMetric> selectedMetrics;

  ExportableBodyLesionData({
    required this.lesion,
    List<Diagnosis> selectedDiagnoses = const <Diagnosis>[],
  })  : selectedDiagnoses = RxList<Diagnosis>.from(selectedDiagnoses),
        selectedMetrics = RxList<ExportableDiagnosisMetric>.from(ExportableDiagnosisMetric.values);

  ExportableBodyLesionData.copyOf(ExportableBodyLesionData other)
      : lesion = other.lesion,
        selectedDiagnoses = RxList<Diagnosis>.from(other.selectedDiagnoses),
        selectedMetrics = RxList<ExportableDiagnosisMetric>.from(other.selectedMetrics);

  bool includesMetric(ExportableDiagnosisMetric metric) => selectedMetrics.contains(metric);

  List<ExportableDiagnosisTableRow> buildDiagnosisRows() {
    return selectedDiagnoses.map(ExportableDiagnosisTableRow.fromDiagnosis).toList();
  }
}

class ExportableDiagnosisTableRow {
  final String diagnosisId;
  final DateTime date;
  final Uint8List? imageBytes;
  final String? predictionLabel;
  final double? asymmetryScore;
  final double? borderScore;
  final double? colorScore;
  final double? confidence;
  final String notes;

  const ExportableDiagnosisTableRow({
    required this.diagnosisId,
    required this.date,
    required this.imageBytes,
    required this.predictionLabel,
    required this.asymmetryScore,
    required this.borderScore,
    required this.colorScore,
    required this.confidence,
    required this.notes,
  });

  factory ExportableDiagnosisTableRow.fromDiagnosis(Diagnosis diagnosis) {
    return ExportableDiagnosisTableRow(
      diagnosisId: diagnosis.id,
      date: diagnosis.date,
      imageBytes: diagnosis.image,
      predictionLabel: diagnosis.prediction.name,
      asymmetryScore: diagnosis.aScore,
      borderScore: diagnosis.bScore,
      colorScore: diagnosis.cScore,
      confidence: diagnosis.confidence,
      notes: diagnosis.notes,
    );
  }

  Map<String, Object?> toPdfMap({
    required bool includeAsymmetry,
    required bool includeBorder,
    required bool includeColor,
    required bool includeConfidence,
    required bool includeClassification,
    required bool includeNotes,
  }) {
    return <String, Object?>{
      'diagnosisId': diagnosisId,
      'date': date,
      'predictionLabel': predictionLabel,
      if (includeAsymmetry) 'asymmetryScore': asymmetryScore,
      if (includeBorder) 'borderScore': borderScore,
      if (includeColor) 'colorScore': colorScore,
      if (includeConfidence) 'confidence': confidence,
      if (includeClassification) 'classification': predictionLabel,
      if (includeNotes) 'notes': notes,
    };
  }
}
