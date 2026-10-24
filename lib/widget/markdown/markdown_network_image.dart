import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gsy_github_app_flutter/common/logger.dart';
import 'package:http/http.dart' as http;

/// 2026-10 FPR-101: classification and rendering share the downloaded body.
/// Each mounted image owns its probe; decoded image/SVG caches keep their own
/// stable source keys and never own the temporary probe bytes or widget State.
class MarkdownNetworkImage extends StatefulWidget {
  const new({
    super.key,
    required this.uri,
    required this.errorBuilder,
    required this.svgPlaceholderBuilder,
    this.headers,
    this.width,
    this.height,
  });

  final Uri uri;
  final Map<String, String>? headers;
  final double? width;
  final double? height;
  final ImageErrorWidgetBuilder errorBuilder;
  final WidgetBuilder svgPlaceholderBuilder;

  @override
  State<MarkdownNetworkImage> createState() => _MarkdownNetworkImageState();
}

class _MarkdownNetworkImageState extends State<MarkdownNetworkImage> {
  late _ImageSource _source;
  _ImageProbe? _probe;
  _ProbeOperation? _operation;
  Object? _error;
  StackTrace? _stack;

  @visibleForTesting
  int get debugRetainedProbeBytes => _probe?.bytes?.length ?? 0;

  @override
  void initState() {
    super.initState();
    _start(_ImageSource(widget.uri, widget.headers));
  }

  @override
  void didUpdateWidget(MarkdownNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final source = _ImageSource(widget.uri, widget.headers);
    if (source != _source) {
      _stop();
      _start(source);
    }
  }

  void _start(_ImageSource source) {
    _source = source;
    _probe = null;
    _error = null;
    _stack = null;
    final operation = _ProbeOperation(source);
    _operation = operation;
    // Store no Future<probe>: its completed value would retain the body even
    // after a cache hit. The only retained payload is the releasable lease.
    unawaited(_prepare(operation));
  }

  Future<void> _prepare(_ProbeOperation operation) async {
    try {
      final probe = await operation.load();
      if (!mounted || _operation != operation) {
        probe.release();
        return;
      }
      setState(() => _probe = probe);
    } catch (error, stack) {
      if (mounted &&
          _operation == operation &&
          !(error is DioException && CancelToken.isCancel(error))) {
        setState(() {
          _error = error;
          _stack = stack;
        });
      }
    } finally {
      operation.close();
      if (_operation == operation) _operation = null;
    }
  }

  void _stop() {
    _operation?.cancel();
    _operation = null;
    _probe?.release();
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder(context, _error!, _stack);
    }
    final probe = _probe;
    if (probe == null) return const SizedBox();
    if (probe.isSvg) {
      return SvgPicture(
        _MarkdownSvgLoader(_source, probe.bytes),
        width: widget.width ?? 24.0,
        height: widget.height ?? 24.0,
        allowDrawingOutsideViewBox: false,
        placeholderBuilder: widget.svgPlaceholderBuilder,
        // 2026-10 FPR-101: live/pending picture hits can skip this consumer's
        // loader entirely. The widget owns its probe, so release it at the
        // package's actual presentation/error boundary as well as disposal.
        imageBuilder: (context, child) {
          probe.release();
          return child;
        },
        errorBuilder: (context, error, stack) {
          probe.release();
          printLog('Markdown SVG load failed: ${error.runtimeType}', stack);
          // Preserve SvgPicture's existing visible error/placeholder contract.
          return widget.svgPlaceholderBuilder(context);
        },
      );
    }
    return Image(
      image: _PrefetchedRaster(_source, probe.bytes!),
      width: widget.width,
      height: widget.height,
      errorBuilder: (context, error, stack) {
        // A shared pending cache entry may fail without consuming this
        // consumer's own body. The visible error must release that lease too.
        probe.release();
        return widget.errorBuilder(context, error, stack);
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        // loadImage is skipped on ImageCache hits. Release the unused probe
        // body when that cached frame is available, as well as on disposal.
        if (frame != null) probe.release();
        return child;
      },
    );
  }
}

@immutable
class _ImageSource {
  new(this.uri, Map<String, String>? headers)
    : headers = headers == null ? null : Map.unmodifiable(headers);

  final Uri uri;
  final Map<String, String>? headers;

  NetworkImage get rasterKey => NetworkImage(uri.toString(), headers: headers);

  @override
  bool operator ==(Object other) =>
      other is _ImageSource &&
      other.uri == uri &&
      mapEquals(other.headers, headers);

  @override
  int get hashCode {
    final names = headers?.keys.toList();
    names?.sort();
    return Object.hash(
      uri,
      names == null
          ? null
          : Object.hashAll(
              names.map((name) => Object.hash(name, headers![name])),
            ),
    );
  }
}

/// A one-shot, explicitly releasable payload, never an image cache key.
class _ProbeBytes {
  new(this._bytes);
  Uint8List? _bytes;
  int get length => _bytes?.lengthInBytes ?? 0;
  Uint8List? take() {
    final bytes = _bytes;
    _bytes = null;
    return bytes;
  }

  void release() => _bytes = null;
}

class _ImageProbe {
  new(this.isSvg, [this.bytes]);
  final bool isSvg;
  final _ProbeBytes? bytes;
  void release() => bytes?.release();
}

class _ProbeOperation {
  new(this.source)
    : dio = Dio(
        BaseOptions(
          // Preserve the previous probe's connection/receive timeout contract.
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: source.headers,
        ),
      );

  final _ImageSource source;
  final Dio dio;
  final CancelToken cancelToken = CancelToken();

  Future<_ImageProbe> load() async {
    try {
      final head = await dio.head(
        source.uri.toString(),
        cancelToken: cancelToken,
      );
      if (_hasSvgMime(head.headers)) return _ImageProbe(true);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      // HEAD is optional (for example 405); the body remains authoritative.
    }
    final response = await dio.get<Uint8List>(
      source.uri.toString(),
      options: Options(responseType: ResponseType.bytes),
      cancelToken: cancelToken,
    );
    final bytes = response.data!;
    if (bytes.isEmpty) throw const FormatException('Empty Markdown image');
    final prefix = utf8
        .decode(
          Uint8List.sublistView(
            bytes,
            0,
            bytes.length > 200 ? 200 : bytes.length,
          ),
          allowMalformed: true,
        )
        .trimLeft();
    // Preserve SVG bodies with missing or misleading raster Content-Type.
    final isSvg =
        _hasSvgMime(response.headers) ||
        prefix.startsWith('<svg') ||
        (prefix.startsWith('<?xml') && prefix.contains('<svg'));
    if (!isSvg && response.statusCode != 200) {
      throw NetworkImageLoadException(
        statusCode: response.statusCode!,
        uri: source.uri,
      );
    }
    return _ImageProbe(isSvg, _ProbeBytes(bytes));
  }

  bool _hasSvgMime(Headers headers) =>
      headers
          .value(Headers.contentTypeHeader)
          ?.toLowerCase()
          .contains('image/svg+xml') ??
      false;

  void cancel() {
    cancelToken.cancel('Markdown image source detached');
    dio.close(force: true);
  }

  void close() => dio.close();
}

/// Uses Flutter's original URL/headers key, not Uint8List identity. A cache
/// hit therefore reuses the existing codec/completer without retaining bytes.
class _PrefetchedRaster extends ImageProvider<NetworkImage> {
  const new(this.source, this.bytes);
  final _ImageSource source;
  final _ProbeBytes bytes;

  @override
  Future<NetworkImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(source.rasterKey);

  @override
  ImageStreamCompleter loadImage(
    NetworkImage key,
    ImageDecoderCallback decode,
  ) {
    final payload = bytes.take();
    // An evicted/re-resolved provider remains usable after its one-shot body
    // was consumed. The ordinary NetworkImage owns that fresh cache miss.
    if (payload == null) return key.loadImage(key, decode);
    return MultiFrameImageStreamCompleter(
      codec: _decodeRaster(payload, key, decode),
      scale: key.scale,
    );
  }
}

Future<ui.Codec> _decodeRaster(
  Uint8List bytes,
  NetworkImage key,
  ImageDecoderCallback decode,
) async {
  try {
    return await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  } catch (_) {
    // Match NetworkImage: a transient failed decode must not poison retries.
    scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
    rethrow;
  }
}

/// Keep the package's native SVG compiler/compiled cache and source identity.
/// Only the initial unknown-type body is handed in; HEAD-known SVGs still let
/// this cached loader fetch, so a hot compiled SVG needs no body download.
class _MarkdownSvgLoader extends SvgLoader<Uint8List> {
  const new(this.source, this.bytes);
  final _ImageSource source;
  final _ProbeBytes? bytes;

  @override
  SvgCacheKey cacheKey(BuildContext? context) => SvgCacheKey(
    keyData: source,
    theme: getTheme(context),
    colorMapper: colorMapper,
  );

  @override
  Future<Uint8List?> prepareMessage(BuildContext? context) {
    final payload = bytes?.take();
    return payload == null
        ? _loadSvgNetwork(source)
        : SynchronousFuture(payload);
  }

  @override
  String provideSvg(Uint8List? message) =>
      utf8.decode(message!, allowMalformed: true);

  @override
  Future<ByteData> loadBytes(BuildContext? context) =>
      super.loadBytes(context).whenComplete(() => bytes?.release());

  @override
  bool operator ==(Object other) =>
      other is _MarkdownSvgLoader &&
      other.source == source &&
      other.theme == theme &&
      other.colorMapper == colorMapper;

  @override
  int get hashCode => Object.hash(source, theme, colorMapper);
}

Future<Uint8List> _loadSvgNetwork(_ImageSource source) async {
  // This request belongs to the shared compiled-cache load, not an individual
  // widget probe; detaching one consumer must not cancel another consumer.
  final client = http.Client();
  try {
    return (await client.get(source.uri, headers: source.headers)).bodyBytes;
  } finally {
    client.close();
  }
}
