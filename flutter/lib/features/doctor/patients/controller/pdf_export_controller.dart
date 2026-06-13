import 'dart:async';
import 'dart:io';

import 'package:dermascan/core/models/body_lesion.dart';
import 'package:dermascan/core/models/diagnosis.dart';
import 'package:dermascan/core/models/patient.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/widgets/custom_snack_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class PdfExportController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  DBService dbService = Get.find<DBService>();

  ScrollController scrollController = ScrollController();

  RxBool isLoading = true.obs;
  RxBool isExporting = false.obs;

  RxBool shouldExportMLClassification = true.obs;
  RxBool shouldExportABCScores = true.obs;
  RxBool shouldExportNotes = true.obs;

  late Patient patient;
  late RxList<BodyLesion> lesions;

  RxMap<String, Diagnosis> selectedDiagnoses = <String, Diagnosis>{}.obs;

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
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error while loading lesions: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  // UI state helpers

  bool isDiagnosisSelected(BodyLesion lesion, Diagnosis diagnosis) {
    return selectedDiagnoses['${lesion.id}_${diagnosis.id}'] != null;
  }

  bool? areAllDiagnosesSelected(BodyLesion lesion) {
    // returns true if all diagnoses are selected, false if none are selected, null if some are selected
    final int total = getTotalDiagnosesCountPerLesion(lesion);
    final int selected = getSelectedDiagnosesCount(lesion);
    
    if (selected == 0) {
      return false;
    } else if (selected == total) {
      return true;
    } else {
      return null;
    }
  }

  int getTotalDiagnosesCountPerLesion(BodyLesion lesion) {
    return lesion.diagnoses.length;
  }

  int getSelectedDiagnosesCount(BodyLesion lesion) {
    return selectedDiagnoses.keys
        .where((String key) => key.startsWith('${lesion.id}_'))
        .length;
  }

  String getExportedRatioText(BodyLesion lesion) {
    final int total = getTotalDiagnosesCountPerLesion(lesion);
    final int selected = getSelectedDiagnosesCount(lesion);
    return '$selected / $total';
  }

  bool isExportable() => selectedDiagnoses.isNotEmpty;

  // selection management

  void toggleDiagnosisSelection(BodyLesion lesion, Diagnosis diagnosis) {
    final String key = '${lesion.id}_${diagnosis.id}';
    if (selectedDiagnoses.containsKey(key)) {
      selectedDiagnoses.remove(key);
    } else {
      selectedDiagnoses[key] = diagnosis;
    }
  }

  void toggleAllDiagnosesForLesion(BodyLesion lesion) {
    final bool allSelected = getSelectedDiagnosesCount(lesion) ==
        getTotalDiagnosesCountPerLesion(lesion);

    if (allSelected) {
      selectedDiagnoses.removeWhere((String key, Diagnosis _) => key.startsWith('${lesion.id}_'));
    } else {
      for (final Diagnosis diagnosis in lesion.diagnoses) {
        selectedDiagnoses['${lesion.id}_${diagnosis.id}'] = diagnosis;
      }
    }
  }

  // PDF generation

  Future<void> exportPDF() async {
    try {
      isExporting.value = true;
      
      final pw.Document pdf = buildPdf();
      final Directory output = await getApplicationDocumentsDirectory();
      final File file = File('${output.path}/example.pdf');
      
      // Save the PDF file
      await file.writeAsBytes(await pdf.save());
      isExporting.value = false;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          title: 'Dermascan Report',
        ),
      );
      
    } catch (e) {
      isExporting.value = false;
      if (!Get.isSnackbarOpen) {
        Get.showSnackbar(
          CustomSnackBar(
            icon: Icons.error,
            title: 'Export Failed',
            message:
              'An error occurred while exporting the PDF. Please try again.',
          ),
        );
      }
    }
  }

  pw.Document buildPdf() {
    int lesionIndex = 1;

    final List<BodyLesion> selectedLesions = lesions
      .where((BodyLesion lesion) => getSelectedDiagnosesCount(lesion) > 0)
      .toList();

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
          _buildPatientSummarySection(patient),
          pw.NewPage(),
          ...selectedLesions.expand((BodyLesion lesion) {
            return _buildLesionSection(lesion, lesionIndex++);
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
    BodyLesion lesion,
    int index,
  ) {
    final List<Diagnosis> diagnosisRows = lesion.diagnoses
        .where((Diagnosis diagnosis) => isDiagnosisSelected(lesion, diagnosis))
        .toList();

    return <pw.Widget>[
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text(
              'Lesion #$index: ${lesion.locationName}',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Suspicious: ${lesion.isSuspicious.value ? 'Yes' : 'No'}',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.Text(
              'Removed: ${lesion.wasRemoved.value ? 'Yes' : 'No'}',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.Text(
              'Test result: ${lesion.testResult.trim().isNotEmpty ? lesion.testResult : '-'}',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.Text(
              'Notes: ${lesion.notes.trim().isNotEmpty ? lesion.notes : '-'}',
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
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 10, bottom: 16),
        child: pw.Divider(color: PdfColors.grey600, thickness: 1),
      ),
    ];
  }

  pw.Widget _buildDiagnosisTable({
    required List<Diagnosis> diagnosisRows,
  }) {
    final List<pw.TableRow> rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: <pw.Widget>[
          _tableCell('Date', isHeader: true),
          _tableCell('Image', isHeader: true),
          if (shouldExportABCScores.value) _tableCell('A', isHeader: true),
          if (shouldExportABCScores.value) _tableCell('B', isHeader: true),
          if (shouldExportABCScores.value) _tableCell('C', isHeader: true),
          if (shouldExportMLClassification.value) _tableCell('Class', isHeader: true),
          if (shouldExportMLClassification.value) _tableCell('Confidence', isHeader: true),
          if (shouldExportNotes.value) _tableCell('Notes', isHeader: true),
        ],
      ),
      ...diagnosisRows.map(
        (Diagnosis diagnosis) => pw.TableRow(
          children: <pw.Widget>[
            _tableCell(_formatDate(diagnosis.date, includeTime: true)),
            _imageCell(diagnosis.analyzedImages?['original']),
            if (shouldExportABCScores.value) _tableCell(_formatScore(diagnosis.aScore)),
            if (shouldExportABCScores.value) _tableCell(_formatScore(diagnosis.bScore)),
            if (shouldExportABCScores.value) _tableCell(_formatScore(diagnosis.cScore)),
            if (shouldExportMLClassification.value)
              _tableCell(diagnosis.prediction.name),
            if (shouldExportMLClassification.value)
              _tableCell(_formatConfidence(diagnosis.confidence)),
            if (shouldExportNotes.value) _tableCell(diagnosis.notes),
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
        if (shouldExportABCScores.value) 2: const pw.FlexColumnWidth(0.05),
        if (shouldExportABCScores.value) 3: const pw.FlexColumnWidth(0.05),
        if (shouldExportABCScores.value) 4: const pw.FlexColumnWidth(0.05),
        if (shouldExportMLClassification.value) 5: const pw.FlexColumnWidth(0.10),
        if (shouldExportMLClassification.value) 6: const pw.FlexColumnWidth(0.10),
        if (shouldExportNotes.value) 7: const pw.FlexColumnWidth(0.18),
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
