import 'package:dermascan/app/translation/messages_de.dart';
import 'package:dermascan/app/translation/messages_en.dart';
import 'package:dermascan/app/translation/messages_ro.dart';
import 'package:get/get.dart';

class Messages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => <String, Map<String, String>>{
    'de_DE': deDE,
    'en_US': enUS,
    'ro_RO': roRO,
  };
}
