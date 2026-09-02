import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/widget/gsy_user_icon_widget.dart';

/// GSYUserIconWidget 的**视觉尺寸 vs 命中区尺寸 vs 布局占位**契约守约：
///
/// GSY 拍板方向（2026-09，见 `docs/03-runbooks/dart-3.13-adoption.md` D5）：
/// - **widget 层默认 `minTapTargetSize = kMinInteractiveDimension`（48dp）**——
///   无障碍红线是安全出厂设置：Material / iOS HIG 均要求可点击控件命中区 ≥ 48dp。
/// - 稠密列表（dynamic timeline / discussion 内嵌评论 / PR files inline
///   comment / 组织 & 赞助者头像并排）里头像本就 20-28 dp，紧挨 `Expanded(Text)`，
///   默认外扩到 48 会挤压兄弟文本。这些 caller **必须显式传 `minTapTargetSize: null`
///   opt-out**，声明"接受 <48dp 命中区以换布局稳定"。
///
/// 测量口径：
/// - 布局占位 = GSYUserIconWidget 自身 render size 减去外层 Padding
///   （构造函数默认 padding 是 EdgeInsets.only(top: 4, right: 5, left: 5)）
///
/// 网络图片兜底策略：
/// - GSYUserIconWidget 内部 `FadeInImage` 用 `NetworkImage(默认头像 URL)` 加载图片。
///   测试环境无网络 → HTTP 400/连不上 → 异常从 `MultiFrameImageStreamCompleter`
///   的 async future 泄漏，会被 flutter_test 判红。
/// - 单靠 `FlutterError.onError` 过滤 `NetworkImageLoadException` 不够——
///   test framework 是通过 zone 未捕获的 async error 判红，不是通过 FlutterError.onError。
/// - 正确做法是覆写 `HttpOverrides.global`，让全体 `HttpClient` 走一个 fake
///   实现，返回一个能被 image codec 解码的最小 PNG。这样 image stream 正常 emit
///   frame，不再触发异常，布局断言就能真正测到。
/// - 这是 Flutter 官方 cookbook「Work with images in tests」推荐的路径，
///   也是 `flutter/packages/flutter/test/painting/` 内部用的方式，
///   避免为一个纯布局测试引入 `network_image_mock` 之类的第三方包。
void main() {
  HttpOverrides? previousHttpOverrides;

  setUpAll(() {
    previousHttpOverrides = HttpOverrides.current;
    HttpOverrides.global = _FakeImageHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = previousHttpOverrides;
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Row(
          children: [
            child,
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }

  Size iconLayoutSize(WidgetTester tester) {
    // GSYUserIconWidget 自身返回 Padding → SizedBox → RawMaterialButton，
    // 用 GSYUserIconWidget 自身 render size 减去默认 padding 得到布局占位。
    final Size widgetSize = tester.getSize(find.byType(GSYUserIconWidget));
    // 默认 padding: top 4, right 5, left 5 → 高 +4, 宽 +10
    return Size(widgetSize.width - 10, widgetSize.height - 4);
  }

  group('GSYUserIconWidget 布局占位守约（无障碍默认 + 稠密位 opt-out）', () {
    testWidgets('默认 caller + 有 onPressed：布局占位外扩到 48×48（无障碍红线）',
        (tester) async {
      await tester.pumpWidget(wrap(
        GSYUserIconWidget(
          width: 20,
          height: 20,
          onPressed: () {},
        ),
      ));
      expect(iconLayoutSize(tester), const Size(48, 48),
          reason: '默认 minTapTargetSize=48 是"安全出厂设置"，'
              '视觉尺寸 <48 时命中区/布局占位外扩到 48，守住无障碍红线');
    });

    testWidgets('显式 opt-out minTapTargetSize=null：布局占位=视觉尺寸（20×20）',
        (tester) async {
      await tester.pumpWidget(wrap(
        GSYUserIconWidget(
          width: 20,
          height: 20,
          onPressed: () {},
          minTapTargetSize: null,
        ),
      ));
      expect(iconLayoutSize(tester), const Size(20, 20),
          reason: '稠密列表（timeline/内嵌评论）显式 null，'
              '接受 <48dp 命中区以换 Row 里 Expanded 文本不被挤压');
    });

    testWidgets('onPressed=null + 保持默认 48dp：布局占位仍 = 视觉尺寸（28×28）',
        (tester) async {
      await tester.pumpWidget(wrap(
        const GSYUserIconWidget(
          width: 28,
          height: 28,
        ),
      ));
      expect(iconLayoutSize(tester), const Size(28, 28),
          reason: 'onPressed=null 表示不可点，此时即使默认 minTapTargetSize=48 '
              '也不应外扩——不可点的头像没必要保 48dp 命中区');
    });

    testWidgets('显式 opt-in minTapTargetSize=48：布局占位外扩到 48×48',
        (tester) async {
      await tester.pumpWidget(wrap(
        GSYUserIconWidget(
          width: 20,
          height: 20,
          onPressed: () {},
          minTapTargetSize: kMinInteractiveDimension,
        ),
      ));
      expect(iconLayoutSize(tester), const Size(48, 48),
          reason: 'caller 显式声明 minTapTargetSize 就是明确接受布局占位外扩');
    });

    testWidgets('minTapTargetSize 小于视觉尺寸时不缩小（视觉尺寸为下限）',
        (tester) async {
      await tester.pumpWidget(wrap(
        GSYUserIconWidget(
          width: 60,
          height: 60,
          onPressed: () {},
          minTapTargetSize: 48,
        ),
      ));
      expect(iconLayoutSize(tester), const Size(60, 60),
          reason: 'minTapTargetSize 是"最小"命中区，不应把大视觉头像反向缩小');
    });
  });
}

/// 让 `HttpClient` 走 fake 实现，把 `NetworkImage` 的 IO 分支变成
/// "永远拿到一段可解码的最小 PNG"。
///
/// 参考 Flutter framework 内部 `test_utils/test_widgets.dart` 的
/// `_createHttpClient` 手法，只覆写 [createHttpClient]。
class _FakeImageHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient();
  }
}

class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Duration? connectionTimeout;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  int? maxConnectionsPerHost;

  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeHttpClientRequest();

  // 下面这些是 HttpClient 接口里我们用不到的方法。测试路径只会走 getUrl。
  // 用 noSuchMethod 兜底而不是一条条实现，避免为一个 mock 塞几十行 stub。
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  final HttpHeaders _headers = _FakeHttpHeaders();

  @override
  HttpHeaders get headers => _headers;

  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();

  @override
  Future<HttpClientResponse> get done async => _FakeHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable(<List<int>>[_kTransparentImage])
        .listen(onData,
            onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 1x1 全透明 PNG 的字节序列。
///
/// 这是 Flutter 官方在测试图片加载相关代码时用的最小可解码 PNG payload
/// （见 `flutter/packages/flutter/test/painting/image_provider_test.dart`）。
/// 图像编解码器能识别这段字节流为合法 PNG，从而正常 emit ImageFrame，
/// 走完 FadeInImage 的加载生命周期，测试环境不再需要真实网络。
const List<int> _kTransparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];
