import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/gsy_string_base.dart';
import 'package:gsy_github_app_flutter/common/localization/gsy_string_en.dart';
import 'package:gsy_github_app_flutter/common/localization/gsy_string_zh.dart';
import 'package:gsy_github_app_flutter/common/localization/gsy_string_ja.dart';
import 'package:gsy_github_app_flutter/common/localization/gsy_string_ko.dart';

///自定义多语言实现
class GSYLocalizations {
  final Locale locale;

  GSYLocalizations(this.locale);

  ///根据不同 locale.languageCode 加载不同语言对应
  ///GSYStringEn和GSYStringZh都继承了GSYStringBase
  static final Map<String, GSYStringBase> localizedValues = {
    'en': GSYStringEn(),
    'zh': GSYStringZh(),
    'ja': GSYStringJa(),
    'ko': GSYStringKo(),
  };

  GSYStringBase? get currentLocalized {
    return localizedValues[locale.languageCode];
  }

  ///通过 Localizations 加载当前的 GSYLocalizations
  ///获取对应的 GSYStringBase
  static GSYLocalizations? of(BuildContext context) {
    return Localizations.of<GSYLocalizations>(context, GSYLocalizations);
  }

  ///通过 Localizations 加载当前的 GSYLocalizations
  ///获取对应的 GSYStringBase
  static GSYStringBase? i18n(BuildContext context) {
    return (Localizations.of(context, GSYLocalizations) as GSYLocalizations)
        .currentLocalized;
  }
}
