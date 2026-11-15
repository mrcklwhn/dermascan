import 'package:dermascan/translations/app_translations.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.clearTranslations();
    Get.addTranslations(AppTranslations().keys);
  });

  tearDown(() {
    Get.reset();
  });

  group('GetX Localizations Refactor Tests', () {
    test('English translations work correctly', () {
      Get.locale = const Locale('en', 'US');

      expect(TrKeys.common.save.tr, 'Save');
      expect(TrKeys.auth.login.tr, 'Login');
      expect(TrKeys.patient.patients.tr, 'Patients');
      expect(TrKeys.lesion.cropLesion.tr, 'Crop Lesion');
      expect(TrKeys.diagnosis.diagnosis.tr, 'Diagnosis');
      expect(TrKeys.practice.currentPractice.tr, 'Current Practice');
      expect(TrKeys.doctor.doctor.tr, 'Doctor');
      expect(TrKeys.pdf.exportPdf.tr, 'PDF Export');
      expect(TrKeys.help.documentation.tr, 'Documentation');
    });

    test('German translations work correctly', () {
      Get.locale = const Locale('de', 'DE');

      expect(TrKeys.common.save.tr, 'Speichern');
      expect(TrKeys.auth.login.tr, 'Login');
      expect(TrKeys.patient.patients.tr, 'Patienten');
      expect(TrKeys.lesion.cropLesion.tr, 'Läsion zuschneiden');
      expect(TrKeys.diagnosis.diagnosis.tr, 'Diagnose');
      expect(TrKeys.practice.currentPractice.tr, 'Aktuelle Praxis');
      expect(TrKeys.doctor.doctor.tr, 'Arzt');
      expect(TrKeys.pdf.exportPdf.tr, 'PDF-Export');
      expect(TrKeys.help.documentation.tr, 'Dokumentation');
    });

    test('Romanian translations work correctly', () {
      Get.locale = const Locale('ro', 'RO');

      expect(TrKeys.common.save.tr, 'Salvează');
      expect(TrKeys.auth.login.tr, 'Autentificare');
      expect(TrKeys.patient.patients.tr, 'Pacienți');
      expect(TrKeys.lesion.cropLesion.tr, 'Decupați leziunea');
      expect(TrKeys.diagnosis.diagnosis.tr, 'Diagnostic');
      expect(TrKeys.practice.currentPractice.tr, 'Cabinetul curent');
      expect(TrKeys.doctor.doctor.tr, 'Medic');
      expect(TrKeys.pdf.exportPdf.tr, 'Export PDF');
      expect(TrKeys.help.documentation.tr, 'Documentație');
    });

    test('Fallback works for missing translations', () {
      Get.locale = const Locale('fr', 'FR');
      Get.fallbackLocale = const Locale('en', 'US');

      expect(TrKeys.common.save.tr, 'Save');
    });

    test('All language files have identical key sets', () {
      final Map<String, String> enKeys = AppTranslations().keys['en_US']!;
      final Map<String, String> deKeys = AppTranslations().keys['de_DE']!;
      final Map<String, String> roKeys = AppTranslations().keys['ro_RO']!;

      expect(deKeys.keys.toSet(), equals(enKeys.keys.toSet()));
      expect(roKeys.keys.toSet(), equals(enKeys.keys.toSet()));
    });
  });

  testWidgets('Widget displays correct translation in GetMaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: Scaffold(
          body: Text(TrKeys.auth.welcomeBack.tr),
        ),
      ),
    );

    expect(find.text('Welcome Back!'), findsOneWidget);
  });
}
