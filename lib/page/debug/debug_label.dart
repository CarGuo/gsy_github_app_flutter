import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/default_localizations.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/env/config_wrapper.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DebugLabel {
  static bool hadShow = false;
  static OverlayEntry? _overlayEntry;

  static showDebugLabel(BuildContext context) async {
    if (!ConfigWrapper.of(context)!.debug!) {
      return false;
    }
    if (hadShow) {
      return false;
    }
    hadShow = true;
    var gl = GSYLocalizations.of(context);
    var overlayState = Overlay.of(context);
    var (version, platform) = await _getDeviceInfo();
    PackageInfo packInfo = await PackageInfo.fromPlatform();
    var language = gl!.locale.languageCode;
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    _overlayEntry = OverlayEntry(builder: (context) {
      return GlobalLabel(
          version: packInfo.version,
          deviceInfo: version,
          platform: platform,
          language: language);
    });
    overlayState.insert(_overlayEntry!);
  }

  static resetDebugLabel(BuildContext context) {
    hideDebugLabel();
    showDebugLabel(context);
  }

  static hideDebugLabel() {
    hadShow = false;
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }
}

Future<(String, String)> _getDeviceInfo() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return (androidInfo.version.sdkInt.toString(), "Android");
  }
  IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
  String device = await CommonUtils.getDeviceInfo();
  return (iosInfo.systemVersion , device);
}

class GlobalLabel extends StatefulWidget {
  final String? version;
  final String? deviceInfo;
  final String? platform;
  final String? language;

  const GlobalLabel({super.key, this.version, this.deviceInfo, this.platform, this.language});

  @override
  _GlobalLabelState createState() => _GlobalLabelState();
}

class _GlobalLabelState extends State<GlobalLabel> {
  bool doubleClick = false;
  bool longClick = false;

  @override
  void dispose() {
    DebugLabel.hadShow = false;
    //_overlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        alignment: const Alignment(0.97, 0.8),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.all(
                Radius.circular(5),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
            child: InkWell(
              onLongPress: () {
                longClick = true;
              },
              onDoubleTap: () {
                doubleClick = true;
                if (longClick && doubleClick) {
                  NavigatorUtils.goDebugDataPage(context);
                }
              },
              child: Text(
                "${widget.platform} ${widget.deviceInfo} ${widget.language} ${widget.version}",
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ),
      );
    });
  }
}
