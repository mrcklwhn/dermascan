import 'package:dermascan/translations/en/auth.dart';
import 'package:dermascan/translations/en/common.dart';
import 'package:dermascan/translations/en/diagnosis.dart';
import 'package:dermascan/translations/en/doctor.dart';
import 'package:dermascan/translations/en/help.dart';
import 'package:dermascan/translations/en/lesion.dart';
import 'package:dermascan/translations/en/onboarding.dart';
import 'package:dermascan/translations/en/patient.dart';
import 'package:dermascan/translations/en/pdf.dart';
import 'package:dermascan/translations/en/practice.dart';

class EnUs {
  static Map<String, String> get translations => <String, String>{
    ...EnCommon.translations,
    ...EnAuth.translations,
    ...EnOnboarding.translations,
    ...EnPatient.translations,
    ...EnLesion.translations,
    ...EnDiagnosis.translations,
    ...EnPractice.translations,
    ...EnDoctor.translations,
    ...EnPdf.translations,
    ...EnHelp.translations,
  };
}
