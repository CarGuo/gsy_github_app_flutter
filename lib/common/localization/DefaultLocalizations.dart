import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStringBase.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStringEn.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStringZh.dart';

class GSYLocalizations {
  final Locale locale;

  GSYLocalizations(this.locale);

  static Map<String, GSYStringBase> _localizedValues = {
    'en': new GSYStringEn(),
    'zh': new GSYStringZh(),
  };

  GSYStringBase get currentLocalized {
    print("++++++++++++++++++++++++++++++++++");
    print(locale.languageCode);
    print("++++++++++++++++++++++++++++++++++");
    return _localizedValues[locale.languageCode];
  }

  static GSYLocalizations of(BuildContext context) {
    return Localizations.of(context, GSYLocalizations);
  }
}
