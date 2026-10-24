import 'package:dermascan/translations/de/auth.dart';
import 'package:dermascan/translations/de/common.dart';
import 'package:dermascan/translations/de/diagnosis.dart';
import 'package:dermascan/translations/de/doctor.dart';
import 'package:dermascan/translations/de/help.dart';
import 'package:dermascan/translations/de/lesion.dart';
import 'package:dermascan/translations/de/onboarding.dart';
import 'package:dermascan/translations/de/patient.dart';
import 'package:dermascan/translations/de/pdf.dart';
import 'package:dermascan/translations/de/practice.dart';

class DeDe {
  static Map<String, String> get translations => <String, String>{
    ...DeCommon.translations,
    ...DeAuth.translations,
    ...DeOnboarding.translations,
    ...DePatient.translations,
    ...DeLesion.translations,
    ...DeDiagnosis.translations,
    ...DePractice.translations,
    ...DeDoctor.translations,
    ...DePdf.translations,
    ...DeHelp.translations,
  };
}
