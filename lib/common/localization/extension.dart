import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/l10n/app_localizations.dart';




extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}