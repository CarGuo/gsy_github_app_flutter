import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/config/config.dart';
import 'package:gsy_github_app_flutter/env/env_config.dart';

///往下共享环境配置
class ConfigWrapper extends StatelessWidget {
  const ConfigWrapper({super.key, this.config, this.child});

  @override
  Widget build(BuildContext context) {
    ///设置 Config.DEBUG 的静态变量
    Config.DEBUG = config?.debug;
    print("ConfigWrapper build ${Config.DEBUG}");
    return _InheritedConfig(config: config, child: child!);
  }

  static EnvConfig? of(BuildContext context) {
    final _InheritedConfig inheritedConfig =
        context.dependOnInheritedWidgetOfExactType<_InheritedConfig>()!;
    return inheritedConfig.config;
  }

  final EnvConfig? config;

  final Widget? child;
}

class _InheritedConfig extends InheritedWidget {
  const _InheritedConfig(
      {required this.config, required super.child});

  final EnvConfig? config;

  @override
  bool updateShouldNotify(_InheritedConfig oldWidget) =>
      config != oldWidget.config;
}
