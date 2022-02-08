import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/default_localizations.dart';

/**
 * 多语言代理
 * Created by guoshuyu
 * Date: 2018-08-15
 */
class GSYLocalizationsDelegate extends LocalizationsDelegate<GSYLocalizations> {

  GSYLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    ///支持中文和英语
    return true;
  }

  ///根据locale，创建一个对象用于提供当前locale下的文本显示
  @override
  Future<GSYLocalizations> load(Locale locale) {
    return new SynchronousFuture<GSYLocalizations>(new GSYLocalizations(locale));
  }

  @override
  bool shouldReload(LocalizationsDelegate<GSYLocalizations> old) {
    return false;
  }

  ///全局静态的代理
  static LocalizationsDelegate<GSYLocalizations> delegate = new GSYLocalizationsDelegate();
}
