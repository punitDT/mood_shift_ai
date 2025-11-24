import 'package:get/get.dart';
import 'en_us.dart';
import 'en_gb.dart';
import 'hi_in.dart';
import 'es_es.dart';
import 'zh_cn.dart';
import 'fr_fr.dart';
import 'de_de.dart';
import 'ar_sa.dart';
import 'ja_jp.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': enUS,
        'en_GB': enGB,
        'hi_IN': hiIN,
        'es_ES': esES,
        'zh_CN': zhCN,
        'fr_FR': frFR,
        'de_DE': deDE,
        'ar_SA': arSA,
        'ja_JP': jaJP,
      };
}

