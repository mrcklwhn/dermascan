import 'package:dermascan/translations/de/de_de.dart';
import 'package:dermascan/translations/en/en_us.dart';
import 'package:dermascan/translations/ro/ro_ro.dart';
import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => <String, Map<String, String>>{
    'en_US': EnUs.translations,
    'de_DE': DeDe.translations,
    'ro_RO': RoRo.translations,
  };
}
