import 'package:flutter/material.dart';

///往下共享环境配置
class OnlyShareInstanceWidget<T> extends StatelessWidget {
  const OnlyShareInstanceWidget({super.key, this.value, this.child});

  @override
  Widget build(BuildContext context) {
    return _OnlyShareInstanceModel(value: value, child: child!);
  }

  static V? of<V>(BuildContext context) {
    final _OnlyShareInstanceModel<V>? inheritedConfig =
    context.dependOnInheritedWidgetOfExactType<_OnlyShareInstanceModel<V>>();
    return inheritedConfig?.value;
  }

  final T? value;

  final Widget? child;
}

class _OnlyShareInstanceModel<T> extends InheritedWidget {
  const _OnlyShareInstanceModel({required this.value, required super.child});

  final T? value;

  ///不需要刷新数据，直接返回false
  @override
  bool updateShouldNotify(_OnlyShareInstanceModel oldWidget) => false;
}