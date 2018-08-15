import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/DefaultLocalizations.dart';

/**
 * Created by guoshuyu
 * Date: 2018-08-15
 */
class GSYLocalizationsDelegate extends LocalizationsDelegate<GSYLocalizations> {

  GSYLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<GSYLocalizations> load(Locale locale) {
    return new SynchronousFuture<GSYLocalizations>(new GSYLocalizations(locale));
  }

  @override
  bool shouldReload(LocalizationsDelegate<GSYLocalizations> old) {
    return false;
  }

  static GSYLocalizationsDelegate delegate = new GSYLocalizationsDelegate();
}
