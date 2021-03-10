import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui show Codec;

import 'package:flutter/painting.dart' as image_provider;


/**
 * Created by guoshuyu
 * on 2019/4/13.
 */
class NetworkCacheImage extends ImageProvider<NetworkCacheImage> {
  /// Creates an object that fetches the image at the given URL.
  ///
  /// The arguments must not be null.
  const NetworkCacheImage(this.url, {this.scale = 1.0, this.headers});

  /// The URL from which the image will be fetched.
  final String url;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  /// The HTTP headers that will be used with [HttpClient.get] to fetch image from network.
  final Map<String, String>? headers;

  @override
  Future<NetworkCacheImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<NetworkCacheImage>(this);
  }

  @override
  ImageStreamCompleter load(NetworkCacheImage key, DecoderCallback decode) {
    // Ownership of this controller is handed off to [_loadAsync]; it is that
    // method's responsibility to close the controller's stream when the image
    // has been loaded or an error is thrown.
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      informationCollector: () {
        return <DiagnosticsNode>[
          DiagnosticsProperty<ImageProvider>('Image provider', this),
          DiagnosticsProperty<NetworkCacheImage>('Image key', key),
        ];
      },
    );
  }

  static final HttpClient _httpClient = HttpClient();

  Future<ui.Codec> _loadAsync(
      NetworkCacheImage key,
      StreamController<ImageChunkEvent> chunkEvents,
      DecoderCallback decode,
      ) async {
    try {
      assert(key == this);

      final Uri resolved = Uri.base.resolve(key.url);
      final HttpClientRequest request = await _httpClient.getUrl(resolved);
      headers?.forEach((String name, String value) {
        request.headers.add(name, value);
      });
      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok)
        throw image_provider.NetworkImageLoadException(statusCode: response.statusCode, uri: resolved);

      final Uint8List bytes = await consolidateHttpClientResponseBytes(
        response,
        onBytesReceived: (int cumulative, int? total) {
          chunkEvents.add(ImageChunkEvent(
            cumulativeBytesLoaded: cumulative,
            expectedTotalBytes: total,
          ));
        },
      );
      if (bytes.lengthInBytes == 0)
        throw Exception('NetworkImage is an empty file: $resolved');
      return decode(bytes);
    } finally {
      chunkEvents.close();
    }
  }

  /*Future<ui.Codec> _loadAsync(
    NetworkCacheImage key,
    StreamController<ImageChunkEvent> chunkEvents,
    DecoderCallback decode,
  ) async {
    try {
      assert(key == this);

      /// add this start
      /// flutter_cache_manager DefaultCacheManager
      final fileInfo = await DefaultCacheManager().getFileFromCache(key.url);
      if (fileInfo != null && fileInfo.file != null) {
        final Uint8List cacheBytes = await fileInfo.file.readAsBytes();
        if (cacheBytes != null) {
          return PaintingBinding.instance.instantiateImageCodec(cacheBytes);
        }
      }

      /// add this end

      final Uri resolved = Uri.base.resolve(key.url);
      final HttpClientRequest request = await _httpClient.getUrl(resolved);
      headers?.forEach((String name, String value) {
        request.headers.add(name, value);
      });
      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok)
        throw NetworkImageLoadException(
            statusCode: response.statusCode, uri: resolved);

      final Uint8List bytes = await consolidateHttpClientResponseBytes(
        response,
        onBytesReceived: (int cumulative, int total) {
          chunkEvents.add(ImageChunkEvent(
            cumulativeBytesLoaded: cumulative,
            expectedTotalBytes: total,
          ));
        },
      );
      if (bytes.lengthInBytes == 0)
        throw Exception('NetworkImage is an empty file: $resolved');

      /// add this start
      await DefaultCacheManager().putFile(key.url, bytes);

      /// add this edn

      return decode(bytes);
    } finally {
      chunkEvents.close();
    }
  }*/

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final NetworkCacheImage typedOther = other;
    return url == typedOther.url && scale == typedOther.scale;
  }

  @override
  int get hashCode => hashValues(url, scale);

  @override
  String toString() => '$runtimeType("$url", scale: $scale)';
}
