import 'package:dermascan/translations/ro/auth.dart';
import 'package:dermascan/translations/ro/common.dart';
import 'package:dermascan/translations/ro/diagnosis.dart';
import 'package:dermascan/translations/ro/doctor.dart';
import 'package:dermascan/translations/ro/help.dart';
import 'package:dermascan/translations/ro/lesion.dart';
import 'package:dermascan/translations/ro/onboarding.dart';
import 'package:dermascan/translations/ro/patient.dart';
import 'package:dermascan/translations/ro/pdf.dart';
import 'package:dermascan/translations/ro/practice.dart';

class RoRo {
  static Map<String, String> get translations => <String, String>{
    ...RoCommon.translations,
    ...RoAuth.translations,
    ...RoOnboarding.translations,
    ...RoPatient.translations,
    ...RoLesion.translations,
    ...RoDiagnosis.translations,
    ...RoPractice.translations,
    ...RoDoctor.translations,
    ...RoPdf.translations,
    ...RoHelp.translations,
  };
}
