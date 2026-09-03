import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/page/repos/widget/repos_item.dart';

/// [ReposItem] 布局回归契约（P2 §2 修复 2026-09-03）
///
/// 目标：锁死"底部 star/fork/watch 三段行在窄容器下不再 overflow"。
///
/// 背景：修复前 `_getBottomItem` 里的 `textWidth` 用
/// `MediaQuery.sizeOf(context).width` 硬算，导致双栏 master 列（~500dp）
/// 下 SizedBox 硬宽（按 1440dp 屏宽算得 268/447 dp）远大于父 Expanded
/// 实际分到的宽（约 90 dp），触发 "OVERFLOWED BY 141/243 PIXELS" 红黄斜条纹。
///
/// 修复策略：build 里套 `LayoutBuilder`，用 `constraints.maxWidth` 换掉
/// `MediaQuery.sizeOf(context).width`，textWidth 按卡片真实可用宽算，
/// 父约束多窄限多窄，ellipsis 语义不变。
///
/// 本 case 用 `takeException()` 精准捕获 RenderFlex overflow FlutterError，
/// 图片相关的 asset/NetworkImage 报错走 FlutterError.onError 不进 zone
/// error queue，因此不会与 overflow 断言互相干扰。
void main() {
  // 拦截 NetworkImage 的 HTTP 请求，返回一张 1x1 透明 PNG。ReposItem 内
  // 部的 GSYUserIconWidget 会给 avatar 建 NetworkImage；测试环境下真去发
  // HTTP 请求既慢又容易冒 SocketException 干扰 takeException()。
  setUpAll(() {
    HttpOverrides.global = _TransparentPngHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  Widget mount({required double width, required ReposViewModel vm}) {
    return MaterialApp(
      home: Scaffold(
        // 500dp 是 P2 §2 双栏 master 列在 1200dp expanded 屏（flex 42 / 100）
        // 下的近似宽；395dp 覆盖 master 列进一步压窄（1080dp 屏、去掉 rail）
        // 的边界；用 SizedBox 卡死宽度，模拟"卡片必须在这个可用宽内布局"。
        body: Center(
          child: SizedBox(
            width: width,
            child: ListView(children: [ReposItem(vm)]),
          ),
        ),
      ),
    );
  }

  ReposViewModel makeVm({
    String repositoryStar = '15461',
    String repositoryFork = '4210',
    String repositoryWatch = '183 today',
  }) {
    return ReposViewModel()
      ..ownerName = 'CarGuo'
      ..ownerPic = 'https://example.com/avatar.png'
      ..repositoryName = 'gsy_github_app_flutter'
      ..repositoryStar = repositoryStar
      ..repositoryFork = repositoryFork
      ..repositoryWatch = repositoryWatch
      ..repositoryType = 'Dart'
      ..repositoryDes =
          'GSY GitHub App Flutter 一个非常好用的 GitHub 客户端 App 示例工程';
  }

  testWidgets(
      'ReposItem 在 500dp 容器（双栏 master 列近似宽）下底部 star/fork/watch 行不 overflow',
      (tester) async {
    // 覆盖 P2 §2 用户报告的真实场景：1200dp expanded 屏 flex 42/100 布局下
    // master 列约 500dp。修复前该 case 会冒 "OVERFLOWED BY 141 PIXELS"，
    // 因为 _getBottomItem 里的 textWidth 用 MediaQuery.sizeOf(context).width
    // 按 test 默认屏（800dp）算得 (800-100)/5=140dp、(800-100)/3=233dp，
    // 硬 SizedBox 超过父 Expanded flex-3/flex-4 在 500dp 容器下实际分到的
    // ~138/184dp。修复后按 constraints.maxWidth 算得 80/133dp，稳妥 fit。
    await tester.pumpWidget(mount(width: 500, vm: makeVm()));
    await tester.pump();

    final err = tester.takeException();
    expect(
      err,
      isNull,
      reason: '契约：500dp 容器下 ReposItem 不允许触发 RenderFlex overflow。'
          'takeException 返回：$err',
    );
  });
}

/// 1x1 透明 PNG 字节，用于测试环境下拦截头像 NetworkImage 请求。
final Uint8List _transparentPng = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class _TransparentPngHttpOverrides extends HttpOverrides {
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
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}

  @override
  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials credentials) {}

  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String? realm)? f) {}

  @override
  set authenticateProxy(
      Future<bool> Function(String host, int port, String scheme, String? realm)? f) {}

  @override
  set badCertificateCallback(
      bool Function(X509Certificate cert, String host, int port)? callback) {}

  @override
  set connectionFactory(
      Future<ConnectionTask<Socket>> Function(
              Uri url, String? proxyHost, int? proxyPort)?
          f) {}

  @override
  set keyLog(Function(String line)? callback) {}

  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      _fakeRequest();

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => _fakeRequest();

  @override
  set findProxy(String Function(Uri url)? f) {}

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      _fakeRequest();

  @override
  Future<HttpClientRequest> getUrl(Uri url) => _fakeRequest();

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      _fakeRequest();

  @override
  Future<HttpClientRequest> headUrl(Uri url) => _fakeRequest();

  @override
  Future<HttpClientRequest> open(
          String method, String host, int port, String path) =>
      _fakeRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) => _fakeRequest();

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      _fakeRequest();

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => _fakeRequest();

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      _fakeRequest();

  @override
  Future<HttpClientRequest> postUrl(Uri url) => _fakeRequest();

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      _fakeRequest();

  @override
  Future<HttpClientRequest> putUrl(Uri url) => _fakeRequest();

  Future<HttpClientRequest> _fakeRequest() async => _FakeHttpClientRequest();
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  bool bufferOutput = true;
  @override
  int contentLength = 0;
  @override
  late Encoding encoding;
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  bool persistentConnection = true;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  final List<Cookie> cookies = <Cookie>[];

  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();

  @override
  Future<HttpClientResponse> get done => close();

  @override
  Future flush() async {}

  @override
  String get method => 'GET';

  @override
  Uri get uri => Uri.parse('https://example.com');

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future addStream(Stream<List<int>> stream) async {}

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  void write(Object? obj) {}

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? obj = '']) {}
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  bool chunkedTransferEncoding = false;
  @override
  int contentLength = 0;
  @override
  ContentType? contentType;
  @override
  DateTime? date;
  @override
  DateTime? expires;
  @override
  String? host;
  @override
  DateTime? ifModifiedSince;
  @override
  bool persistentConnection = true;
  @override
  int? port;

  @override
  List<String>? operator [](String name) => null;

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void clear() {}

  @override
  void forEach(void Function(String name, List<String> values) f) {}

  @override
  void noFolding(String name) {}

  @override
  void remove(String name, Object value) {}

  @override
  void removeAll(String name) {}

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  String? value(String name) => null;
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  X509Certificate? get certificate => null;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  HttpConnectionInfo? get connectionInfo => null;
  @override
  int get contentLength => _transparentPng.length;
  @override
  List<Cookie> get cookies => <Cookie>[];
  @override
  Future<Socket> detachSocket() => throw UnimplementedError();
  @override
  HttpHeaders get headers => _FakeHttpHeaders();
  @override
  bool get isRedirect => false;
  @override
  bool get persistentConnection => true;
  @override
  String get reasonPhrase => 'OK';
  @override
  Future<HttpClientResponse> redirect(
          [String? method, Uri? url, bool? followLoops]) =>
      throw UnimplementedError();
  @override
  List<RedirectInfo> get redirects => <RedirectInfo>[];
  @override
  int get statusCode => 200;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.value(_transparentPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
