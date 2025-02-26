import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../common/style/gsy_style.dart';

part 'app_state_provider.g.dart';

final globalContainer = ProviderContainer();

final appStateProvider = Provider<(bool, Locale, ThemeData)>((ref) {
  final var1 = ref.watch(appGrepStateProvider);
  final var2 = ref.watch(appLocalStateProvider);
  final var3 = ref.watch(appThemeStateProvider);
  return (var1, var2, var3);
});

ColorFilter greyscale = const ColorFilter.matrix(
  <double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ],
);

/// 控制 App 灰度效果
@riverpod
class AppGrepState extends _$AppGrepState {
  @override
  bool build() => false;

  void changeGrey() {
    state = !state;
  }
}

/// 控制 App 语言
@riverpod
class AppLocalState extends _$AppLocalState {
  @override
  Locale build() {
    return WidgetsBinding.instance.platformDispatcher.locale;
  }

  _getLocale(int? index) {
    switch (index) {
      case 1:
        return const Locale('zh', 'CH');
      case 2:
        return const Locale('en', 'US');
      case 3:
        return const Locale('ko', 'KR');
      case 4:
        return const Locale('ja', 'JP');
      default:
        return WidgetsBinding.instance.platformDispatcher.locale;
    }
  }

  void changeLocale(String? index) {
    int? localeIndex =
        (index != null && index.isNotEmpty) ? int.parse(index) : null;
    state = _getLocale(localeIndex);
  }
}

/// 控制 App 主题
@riverpod
class AppThemeState extends _$AppThemeState {
  @override
  ThemeData build() {
    return CommonUtils.getThemeData(GSYColors.primarySwatch);
  }

  void pushTheme(String? index) {
    int? localeIndex =
        (index != null && index.isNotEmpty) ? int.parse(index) : null;
    if (localeIndex != null) {
      List<Color> colors = CommonUtils.getThemeListColor();
      state = _getThemeData(colors[localeIndex]);
    }
  }

  ThemeData _getThemeData(Color color) {
    return ThemeData(
      useMaterial3: false,

      ///用来适配 Theme.of(context).primaryColorLight 和 primaryColorDark 的颜色变化，不设置可能会是默认蓝色
      primarySwatch: color as MaterialColor,

      /// Card 在 M3 下，会有 apply Overlay

      colorScheme: ColorScheme.fromSeed(
        seedColor: color,
        primary: color,

        brightness: Brightness.light,

        ///影响 card 的表色，因为 M3 下是  applySurfaceTint ，在 Material 里
        surfaceTint: Colors.transparent,
      ),

      /// 受到 iconThemeData.isConcrete 的印象，需要全参数才不会进入 fallback
      iconTheme: const IconThemeData(
        size: 24.0,
        fill: 0.0,
        weight: 400.0,
        grade: 0.0,
        opticalSize: 48.0,
        color: Colors.white,
        opacity: 0.8,
      ),

      ///修改 FloatingActionButton的默认主题行为
      floatingActionButtonTheme: FloatingActionButtonThemeData(
          foregroundColor: Colors.white,
          backgroundColor: color,
          shape: const CircleBorder()),
      appBarTheme: AppBarTheme(
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 24.0,
        ),
        backgroundColor: color,
        titleTextStyle: Typography.dense2021.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // 如果需要去除对应的水波纹效果
      // splashFactory: NoSplash.splashFactory,
      // textButtonTheme: TextButtonThemeData(
      //   style: ButtonStyle(splashFactory: NoSplash.splashFactory),
      // ),
      // elevatedButtonTheme: ElevatedButtonThemeData(
      //   style: ButtonStyle(splashFactory: NoSplash.splashFactory),
      // ),
    );
  }
}
