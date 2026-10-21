import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/common/logger.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/widget/gsy_user_icon_widget.dart';
import 'package:talker_flutter/talker_flutter.dart';

void main() {
  final client = _ImageHttpClient();
  HttpOverrides? previousHttpOverrides;

  setUpAll(() {
    previousHttpOverrides = HttpOverrides.current;
    HttpOverrides.global = _ImageHttpOverrides(client);
  });

  tearDownAll(() {
    HttpOverrides.global = previousHttpOverrides;
  });

  setUp(() {
    client.requests.clear();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    talker.cleanHistory();
  });

  tearDown(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    talker.cleanHistory();
  });

  // 2026-10-21：以实际 HTTP 次数和结构化日志同时守住请求/重建边界，避免
  // errorBuilder 日志重放，也避免按 URL 永久去重后把下一次真实失败隐藏。
  testWidgets(
    'failure logs once across rebuilds and each real retry logs again',
    (tester) async {
      const url = 'https://example.invalid/avatar.png';
      for (var attempt = 0; attempt < 3; attempt++) {
        await tester.pumpWidget(_avatarApp(url));
        final element = tester.element(find.byType(GSYUserIconWidget));
        expect(client.requests, hasLength(attempt + 1));
        client.requests.last.respond(HttpStatus.notFound);
        await tester.pumpAndSettle();

        final failures = _avatarFailures();
        expect(failures, hasLength(attempt + 1));
        expect(failures.last.exception, isA<NetworkImageLoadException>());
        expect(failures.last.stackTrace, isNotNull);
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(GSYUserIconWidget)),
          const Size(80, 80),
        );
        expect(tester.getSize(find.byType(ClipOval)), const Size(80, 80));
        final fallback = find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  GSYICons.DEFAULT_USER_ICON,
        );
        expect(fallback, findsOneWidget);
        expect(tester.getSize(fallback), const Size(80, 80));
        expect(find.text('Account identity'), findsOneWidget);

        for (var rebuild = 0; rebuild < 2; rebuild++) {
          await tester.pumpWidget(_avatarApp(url));
          await tester.pumpAndSettle();
          expect(tester.element(find.byType(GSYUserIconWidget)), same(element));
          expect(client.requests, hasLength(attempt + 1));
          expect(_avatarFailures(), hasLength(attempt + 1));
          expect(_avatarFailures().last, same(failures.last));
          expect(tester.takeException(), isNull);
        }

        // Failed NetworkImage requests are evicted by the SDK. Remounting is
        // a real request even with the same URL, rather than a builder replay.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'URL change discards the previous image and the new image still fades in',
    (tester) async {
      // Network/codec callbacks need a real async zone; animation time remains
      // controlled by the test binding's pump calls.
      await tester.runAsync(() async {
        const firstUrl = 'https://example.invalid/first.png';
        const nextUrl = 'https://example.invalid/next.png';
        final firstBytes = await _imageBytes(2);
        final nextBytes = await _imageBytes(3);

        await tester.pumpWidget(_avatarApp(firstUrl));
        final firstState = tester.state(find.byType(FadeInImage));
        await _respondWithImage(tester, client.requests.single, firstBytes);
        await tester.pumpAndSettle();
        expect(_rawImage(tester, 2).opacity!.value, 1);

        await tester.pumpWidget(_avatarApp(nextUrl));
        expect(tester.state(find.byType(FadeInImage)), isNot(same(firstState)));
        expect(
          client.requests.map((request) => request.uri.toString()),
          <String>[firstUrl, nextUrl],
        );
        expect(
          _renderedImages(tester).where((image) => image.width == 2),
          isEmpty,
          reason:
              'The previous user frame must disappear while the next URL loads',
        );

        await _respondWithImage(tester, client.requests.last, nextBytes);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 650));
        expect(
          _rawImage(tester, 3).opacity!.value,
          allOf(greaterThan(0), lessThan(1)),
          reason: 'Keep FadeInImage animation for an asynchronously loaded URL',
        );
        await tester.pumpAndSettle();
        expect(_rawImage(tester, 3).opacity!.value, 1);
        expect(tester.getSize(find.byType(ClipOval)), const Size(80, 80));
        expect(_avatarFailures(), isEmpty);
      });
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _avatarApp(String url) => MaterialApp(
  home: Scaffold(
    body: Row(
      children: [
        GSYUserIconWidget(
          image: url,
          width: 80,
          height: 80,
          padding: EdgeInsets.zero,
          onPressed: () {},
        ),
        const Expanded(child: Text('Account identity')),
      ],
    ),
  ),
);

List<TalkerData> _avatarFailures() => talker.history
    .where((entry) => entry.message == 'Avatar image load failed')
    .toList();

Iterable<ui.Image> _renderedImages(WidgetTester tester) => tester
    .widgetList<RawImage>(find.byType(RawImage))
    .map((widget) => widget.image)
    .whereType<ui.Image>();

RawImage _rawImage(WidgetTester tester, int width) => tester
    .widgetList<RawImage>(find.byType(RawImage))
    .singleWhere((widget) => widget.image?.width == width);

Future<Uint8List> _imageBytes(int width) async {
  final image = await createTestImage(
    width: width,
    height: width,
    cache: false,
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

Future<void> _respondWithImage(
  WidgetTester tester,
  _ImageRequest request,
  Uint8List bytes,
) async {
  // Observe the already pending cached stream so the test awaits real codec
  // completion without timing sleeps. This does not create another HTTP load.
  final provider = tester.widget<FadeInImage>(find.byType(FadeInImage)).image;
  final stream = provider.resolve(ImageConfiguration.empty);
  final loaded = Completer<void>();
  final listener = ImageStreamListener((image, synchronousCall) {
    image.dispose();
    loaded.complete();
  }, onError: loaded.completeError);
  stream.addListener(listener);
  try {
    request.respond(HttpStatus.ok, bytes);
    await loaded.future;
  } finally {
    stream.removeListener(listener);
  }
}

class _ImageHttpOverrides extends HttpOverrides {
  new(this.client);

  final HttpClient client;

  @override
  HttpClient createHttpClient(SecurityContext? context) => client;
}

class _ImageHttpClient implements HttpClient {
  final requests = <_ImageRequest>[];

  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    final request = _ImageRequest(url);
    requests.add(request);
    return request;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ImageRequest implements HttpClientRequest {
  new(this.uri);

  @override
  final Uri uri;
  final _response = Completer<HttpClientResponse>();

  void respond(int statusCode, [List<int> bytes = const []]) =>
      _response.complete(_ImageResponse(statusCode, bytes));

  @override
  Future<HttpClientResponse> close() => _response.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ImageResponse extends Stream<List<int>> implements HttpClientResponse {
  new(this.statusCode, this.bytes);

  @override
  final int statusCode;
  final List<int> bytes;

  @override
  int get contentLength => bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
