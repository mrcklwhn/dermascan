import 'dart:async';
import 'dart:io';

import 'package:dermascan/app/enums.dart';
import 'package:dermascan/core/models/body_lesion.dart';
import 'package:dermascan/core/models/diagnosis.dart';
import 'package:dermascan/core/models/exportable_patient_data.dart';
import 'package:dermascan/core/models/patient.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/features/doctor/patients/screens/pdf_export_diagnosis_selection_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfExportController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  DBService dbService = Get.find<DBService>();

  RxBool isLoading = true.obs;
  RxBool isExporting = false.obs;

  late Patient patient;

  late Rx<ExportablePatientData> exportablePatientData;

  late RxList<BodyLesion> lesions;

  ExportableBodyLesionData? _draftLesion;

  Map<String, List<Uint8List>> lesionPreviewImages =
      <String, List<Uint8List>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_initializeData());
  }

  Future<void> _initializeData() async {
    try {
      final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;
      patient = args['patient'];
      lesions = (args['lesions'] as List<BodyLesion>).obs;

      // Prepare exportable data structure
      exportablePatientData = ExportablePatientData(
        patient: patient,
        lesions: lesions,
      ).obs;

      // Copy latest 3 original images for preview from lesion.diagnoses
      for (final BodyLesion lesion in lesions) {
        final List<Uint8List> previewImages = lesion.diagnoses
            .map<Uint8List?>((Diagnosis diagnosis) => diagnosis.image)
            .whereType<Uint8List>()
            .take(3)
            .toList();

        lesionPreviewImages[lesion.id] = previewImages;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error while loading lesions: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  // UI state helpers

  int getTotalDiagnosesCountPerLesion(BodyLesion lesion) {
    return lesion.diagnoses.length;
  }

  int getSelectedDiagnosesCount(BodyLesion lesion) {
    return exportablePatientData
            .value
            .lesionData[lesion.id]
            ?.selectedDiagnoses
            .length ??
        0;
  }

  String getExportedRatioText(BodyLesion lesion) {
    final int total = getTotalDiagnosesCountPerLesion(lesion);
    final int selected = getSelectedDiagnosesCount(lesion);
    return '$selected / $total';
  }

  bool isMetricSelected(BodyLesion lesion, ExportableDiagnosisMetric metric) {
    _draftLesion ??= exportablePatientData.value.lesionData[lesion.id];
    if (_draftLesion == null) return false;
    return _draftLesion!.selectedMetrics.contains(metric);
  }

  bool allDraftDiagnosesSelected(BodyLesion lesion) {
    _draftLesion ??= exportablePatientData.value.lesionData[lesion.id];
    if (_draftLesion == null) return false;
    return _draftLesion!.selectedDiagnoses.length == lesion.diagnoses.length;
  }

  bool isDraftDiagnosisSelected(BodyLesion lesion, Diagnosis diagnosis) {
    _draftLesion ??= exportablePatientData.value.lesionData[lesion.id];
    if (_draftLesion == null) return false;
    return _draftLesion!.selectedDiagnoses.contains(diagnosis);
  }

  void openLesionDetail(BodyLesion lesion) {
    // open diagnosis selection screen with the given lesion
    final ExportableBodyLesionData? committedLesion =
        exportablePatientData.value.lesionData[lesion.id];
    _draftLesion = committedLesion == null
        ? ExportableBodyLesionData(lesion: lesion)
        : ExportableBodyLesionData.copyOf(committedLesion);

    Get.to(() => PdfExportDiagnosisSelectionScreen(lesion: lesion));
  }

  // selection management

  void toggleDraftDiagnosisSelection(Diagnosis diagnosis) {
    if (_draftLesion?.selectedDiagnoses.contains(diagnosis) == true) {
      _draftLesion?.selectedDiagnoses.remove(diagnosis);
    } else {
      _draftLesion?.selectedDiagnoses.add(diagnosis);
    }
  }

  void toggleAllDraftDiagnosesSelection(BodyLesion lesion) {
    final ExportableBodyLesionData? draftLesion = _draftLesion;
    if (draftLesion == null) {
      return;
    }

    exportablePatientData.value.toggleAllDiagnosesForLesion(draftLesion);
    exportablePatientData.refresh();
  }

  void commitDraftDiagnosisSelection() {
    if (_draftLesion == null) {
      return;
    }

    exportablePatientData.value.setDiagnosisSelection(_draftLesion!);
    exportablePatientData.refresh();
  }

  void toggleDiagnosisMetricSelection(ExportableDiagnosisMetric metric) {
    exportablePatientData.value.toggleMetricSelection(_draftLesion!, metric);

    exportablePatientData.refresh();
  }

  Future<Directory> getDownloadsDirectory() async {
    Directory directory;

    if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!directory.existsSync()) {
        directory =
            await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
      }
    } else {
      throw UnsupportedError('Unsupported platform');
    }

    return directory;
  }

  Future<void> exportPDF() async {
    isExporting.value = true;
    final pw.Document pdf = buildPdf();
    final Directory output = await getDownloadsDirectory();
    final File file = File('${output.path}/example.pdf');
    await file.writeAsBytes(await pdf.save());
    isExporting.value = false;
  }

  pw.Document buildPdf() {
    final ExportablePatientData data = exportablePatientData.value;
    data.ensureExportable();

    int lesionIndex = 1;

    final pw.Document pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: <pw.Widget>[
              pw.Text(
                'Dermascan Report',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Generated on ${_formatDate(DateTime.now(), includeTime: true)}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
        footer: (pw.Context context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
        build: (pw.Context context) => <pw.Widget>[
          _buildPatientSummarySection(data.patient),
          pw.NewPage(),
          ...data.selectedLesions.expand((ExportableBodyLesionData selection) {
            return _buildLesionSection(selection, lesionIndex++);
          }),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildPatientSummarySection(Patient patient) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          'Patient Data',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.8),
          columnWidths: const <int, pw.TableColumnWidth>{
            0: pw.FlexColumnWidth(0.35),
            1: pw.FlexColumnWidth(0.65),
          },
          children: <pw.TableRow>[
            _buildGridRow('Name', patient.name, isHeader: true),
            _buildGridRow('Date of birth', _formatDate(patient.dateOfBirth)),
            _buildGridRow('Gender', patient.gender.name),
            _buildGridRow('Birth country', patient.birthCountry),
            _buildGridRow('Current country', patient.currentCountry),
            _buildGridRow(
              'Tanning bed exposure',
              _formatYesNo(patient.tanningBedExposure),
            ),
            _buildGridRow(
              'Previous skin surgeries',
              _formatYesNo(patient.previousSkinSurgeries),
            ),
            _buildGridRow(
              'Previous sunburns',
              _formatYesNo(patient.previousSunburns),
            ),
          ],
        ),
      ],
    );
  }

  List<pw.Widget> _buildLesionSection(
    ExportableBodyLesionData selection,
    int index,
  ) {
    final bool includeAsymmetry = selection.includesMetric(
      ExportableDiagnosisMetric.asymmetry,
    );
    final bool includeBorder = selection.includesMetric(
      ExportableDiagnosisMetric.border,
    );
    final bool includeColor = selection.includesMetric(
      ExportableDiagnosisMetric.color,
    );
    final bool includeConfidence = selection.includesMetric(
      ExportableDiagnosisMetric.confidence,
    );
    final bool includeClassification = selection.includesMetric(
      ExportableDiagnosisMetric.classification,
    );
    final bool includeNotes = selection.includesMetric(
      ExportableDiagnosisMetric.notes,
    );
    final List<ExportableDiagnosisTableRow> diagnosisRows = selection
        .buildDiagnosisRows();

    return <pw.Widget>[
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text(
              'Lesion #$index: ${selection.lesion.locationName}',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Suspicious: ${selection.lesion.isSuspicious.value ? 'Yes' : 'No'}',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.Text(
              'Removed: ${selection.lesion.wasRemoved.value ? 'Yes' : 'No'}',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.Text(
              'Test result: ${selection.lesion.testResult.trim().isNotEmpty ? selection.lesion.testResult : '-'}',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.Text(
              'Notes: ${selection.lesion.notes.trim().isNotEmpty ? selection.lesion.notes : '-'}',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Diagnosis history',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
          ],
        ),
      ),
      _buildDiagnosisTable(
        diagnosisRows: diagnosisRows,
        includeAsymmetry: includeAsymmetry,
        includeBorder: includeBorder,
        includeColor: includeColor,
        includeConfidence: includeConfidence,
        includeClassification: includeClassification,
        includeNotes: includeNotes,
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 10, bottom: 16),
        child: pw.Divider(color: PdfColors.grey600, thickness: 1),
      ),
    ];
  }

  pw.Widget _buildDiagnosisTable({
    required List<ExportableDiagnosisTableRow> diagnosisRows,
    required bool includeAsymmetry,
    required bool includeBorder,
    required bool includeColor,
    required bool includeConfidence,
    required bool includeClassification,
    required bool includeNotes,
  }) {
    final List<pw.TableRow> rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: <pw.Widget>[
          _tableCell('Date', isHeader: true),
          _tableCell('Image', isHeader: true),
          if (includeAsymmetry) _tableCell('A', isHeader: true),
          if (includeBorder) _tableCell('B', isHeader: true),
          if (includeColor) _tableCell('C', isHeader: true),
          if (includeClassification) _tableCell('Class', isHeader: true),
          if (includeConfidence) _tableCell('Confidence', isHeader: true),
          if (includeNotes) _tableCell('Notes', isHeader: true),
        ],
      ),
      ...diagnosisRows.map(
        (ExportableDiagnosisTableRow row) => pw.TableRow(
          children: <pw.Widget>[
            _tableCell(_formatDate(row.date, includeTime: true)),
            _imageCell(row.imageBytes),
            if (includeAsymmetry) _tableCell(_formatScore(row.asymmetryScore)),
            if (includeBorder) _tableCell(_formatScore(row.borderScore)),
            if (includeColor) _tableCell(_formatScore(row.colorScore)),
            if (includeClassification)
              _tableCell(row.predictionLabel ?? 'Unknown'),
            if (includeConfidence)
              _tableCell(_formatConfidence(row.confidence)),
            if (includeNotes) _tableCell(row.notes),
          ],
        ),
      ),
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.6),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: <int, pw.TableColumnWidth>{
        0: const pw.FlexColumnWidth(0.10),
        1: const pw.FlexColumnWidth(0.18),
        if (includeAsymmetry) 2: const pw.FlexColumnWidth(0.05),
        if (includeBorder) 3: const pw.FlexColumnWidth(0.05),
        if (includeColor) 4: const pw.FlexColumnWidth(0.05),
        if (includeClassification) 5: const pw.FlexColumnWidth(0.10),
        if (includeConfidence) 6: const pw.FlexColumnWidth(0.10),
        if (includeNotes) 7: const pw.FlexColumnWidth(0.18),
      },
      children: rows,
    );
  }

  pw.TableRow _buildGridRow(
    String label,
    String value, {
    bool isHeader = false,
  }) {
    return pw.TableRow(
      children: <pw.Widget>[
        _tableCell(label, isHeader: true),
        _tableCell(value, isHeader: isHeader),
      ],
    );
  }

  pw.Widget _tableCell(String value, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _imageCell(Uint8List? imageBytes) {
    if (imageBytes == null || imageBytes.isEmpty) {
      return pw.Container(
        alignment: pw.Alignment.center,
        width: 100,
        height: 100,
        color: PdfColors.grey300,
        child: pw.Center(child: pw.Text('No Image')),
      );
    }
    final pw.MemoryImage image = pw.MemoryImage(imageBytes);

    return pw.Image(
      image,
      fit: pw.BoxFit.fill,
      alignment: pw.Alignment.center,
      width: 100,
      height: 100,
    );
  }

  String _formatDate(DateTime date, {bool includeTime = false}) {
    final DateTime localDate = date.toLocal();
    final String day = localDate.day.toString().padLeft(2, '0');
    final String month = localDate.month.toString().padLeft(2, '0');
    final String hour = localDate.hour.toString().padLeft(2, '0');
    final String minute = localDate.minute.toString().padLeft(2, '0');
    final String second = localDate.second.toString().padLeft(2, '0');
    if (includeTime) {
      return '$day.$month.${localDate.year} $hour:$minute:$second';
    }
    return '$day.$month.${localDate.year}';
  }

  String _formatYesNo(bool value) => value ? 'Yes' : 'No';

  String _formatScore(double? value) => value?.toStringAsFixed(2) ?? '-';

  String _formatConfidence(double? value) {
    if (value == null) {
      return '-';
    }

    return '${(value * 100).toStringAsFixed(1)}%';
  }
}
