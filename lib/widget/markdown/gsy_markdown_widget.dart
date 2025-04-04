// ignore_for_file: unnecessary_string_escapes

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/widget/markdown/syntax_high_lighter.dart';

/// 代码详情
/// Created by guoshuyu
/// Date: 2018-07-24

class GSYMarkdownWidget extends StatelessWidget {
  static const int DARK_WHITE = 0;

  static const int DARK_LIGHT = 1;

  static const int DARK_THEME = 2;

  final String? markdownData;
  final String baseUrl;

  final int style;

  const GSYMarkdownWidget(
      {super.key,
      this.markdownData = "",
      required this.baseUrl,
      this.style = DARK_WHITE});

  _getCommonSheet(BuildContext context, Color codeBackground) {
    MarkdownStyleSheet markdownStyleSheet =
        MarkdownStyleSheet.fromTheme(Theme.of(context));
    return markdownStyleSheet
        .copyWith(
            codeblockDecoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                color: codeBackground,
                border: Border.all(color: GSYColors.subTextColor, width: 0.3)))
        .copyWith(
            blockquoteDecoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                color: GSYColors.subTextColor,
                border: Border.all(color: GSYColors.subTextColor, width: 0.3)),
            blockquote: GSYConstant.smallTextWhite);
  }

  _getStyleSheetDark(BuildContext context) {
    return _getCommonSheet(context, const Color.fromRGBO(40, 44, 52, 1.00))
        .copyWith(
      p: GSYConstant.smallTextWhite,
      h1: GSYConstant.largeLargeTextWhite,
      h2: GSYConstant.largeTextWhiteBold,
      h3: GSYConstant.normalTextMitWhiteBold,
      h4: GSYConstant.middleTextWhite,
      h5: GSYConstant.smallTextWhite,
      h6: GSYConstant.smallTextWhite,
      em: const TextStyle(fontStyle: FontStyle.italic),
      strong: GSYConstant.middleTextWhiteBold,
      code: GSYConstant.smallSubText,
    );
  }

  _getStyleSheetWhite(BuildContext context) {
    return _getCommonSheet(context, const Color.fromRGBO(40, 44, 52, 1.00))
        .copyWith(
      p: GSYConstant.smallText,
      h1: GSYConstant.largeLargeText,
      h2: GSYConstant.largeTextBold,
      h3: GSYConstant.normalTextBold,
      h4: GSYConstant.middleText,
      h5: GSYConstant.smallText,
      h6: GSYConstant.smallText,
      strong: GSYConstant.middleTextBold,
      code: GSYConstant.smallSubText,
    );
  }

  _getStyleSheetTheme(BuildContext context) {
    return _getCommonSheet(context, const Color.fromRGBO(40, 44, 52, 1.00))
        .copyWith(
      p: GSYConstant.smallTextWhite,
      h1: GSYConstant.largeLargeTextWhite,
      h2: GSYConstant.largeTextWhiteBold,
      h3: GSYConstant.normalTextMitWhiteBold,
      h4: GSYConstant.middleTextWhite,
      h5: GSYConstant.smallTextWhite,
      h6: GSYConstant.smallTextWhite,
      em: const TextStyle(fontStyle: FontStyle.italic),
      strong: GSYConstant.middleTextWhiteBold,
      code: GSYConstant.smallSubText,
    );
  }

  _getBackgroundColor(BuildContext context) {
    Color background = GSYColors.white;
    switch (style) {
      case DARK_LIGHT:
        background = GSYColors.primaryLightValue;
        break;
      case DARK_THEME:
        background = Theme.of(context).primaryColor;
        break;
    }
    return background;
  }

  _getStyle(BuildContext context) {
    var styleSheet = _getStyleSheetWhite(context);
    switch (style) {
      case DARK_LIGHT:
        styleSheet = _getStyleSheetDark(context);
        break;
      case DARK_THEME:
        styleSheet = _getStyleSheetTheme(context);
        break;
    }
    return styleSheet;
  }

  /// 处理 Markdown 字符串，转换 img/image 标签为 Markdown 图片格式，并处理 URL。
  ///
  /// 1. 将 <img src="..."> 或 <image src="..."> 替换为 ![alt](src) 格式。
  /// 2. 为非 http/https 开头的 src 添加 baseUrl。
  /// 3. 为最终的 URL 添加 ?raw=true 或 &raw=true (如果尚未存在)。
  ///
  /// @param markdownInput 输入的 Markdown 字符串。
  /// @param baseUrl 用于拼接相对路径的基础 URL。
  /// @return 处理后的 Markdown 字符串。
  String _processMarkdownImages(String markdownInput, String baseUrl) {
    // 确保 baseUrl 以 / 结尾，方便路径拼接
    if (!baseUrl.endsWith('/')) {
      baseUrl += '/';
    }
    final baseUri = Uri.parse(baseUrl);

    // 正则表达式匹配 <img> 或 <image> 标签，以及 Markdown 图片 ![]()
    // 捕获组:
    // Group 1: img/image 标签的 src
    // Group 2: img/image 标签的 alt (可选)
    // Group 3: Markdown 图片的 alt
    // Group 4: Markdown 图片的 url
    final pattern = RegExp(
        '<img\\s+.*?src\\s*=\\s*["\'](.*?)["\'](?:.*?\s+alt\s*=\s*["\'](.*?)["\'])?.*?>' // 匹配 <img ... src="..." alt="...">
        '|<image\\s+.*?src\\s*=\\s*["\'](.*?)["\'](?:.*?\s+alt\s*=\s*["\'](.*?)["\'])?.*?>' // 匹配 <image ... src="..." alt="..."> (理论上 image 不标准，但以防万一)
        '|!\\[(.*?)\\]\\((.*?)\\)', // 匹配 ![alt](url)
        caseSensitive: false, // 忽略大小写
        multiLine: true // 支持多行匹配
        );

    String result = markdownInput.replaceAllMapped(pattern, (match) {
      String? originalUrl;
      String? altText;

      // 检查是匹配了 img/image 标签还是 Markdown 图片
      if (match.group(1) != null || match.group(3) != null) {
        // 匹配到 <img> 或 <image>
        originalUrl = match.group(1) ?? match.group(3); // 获取 src
        altText = match.group(2) ?? match.group(4) ?? ''; // 获取 alt，如果不存在则为空字符串
      } else if (match.group(6) != null) {
        // 匹配到 ![]()
        originalUrl = match.group(6); // 获取 url
        altText = match.group(5) ?? ''; // 获取 alt
      }

      if (originalUrl == null || originalUrl.isEmpty) {
        // 如果没有匹配到有效的 URL，返回原始匹配项
        return match.group(0)!;
      }

      // --- 2. 处理 URL 添加 baseUrl ---
      String processedUrl;
      Uri parsedOriginalUrl;

      try {
        // 尝试解析原始 URL，看它是否已经是绝对路径
        parsedOriginalUrl = Uri.parse(originalUrl.trim()); // 去除前后空格
        if (parsedOriginalUrl.scheme == 'http' ||
            parsedOriginalUrl.scheme == 'https') {
          processedUrl = originalUrl.trim();
        } else {
          // 是相对路径，需要拼接 baseUrl
          // Uri.resolve 能正确处理 "./", "/", "filename" 等情况
          processedUrl = baseUri.resolve(originalUrl.trim()).toString();
        }
      } catch (e) {
        // 如果 URL 解析失败 (格式错误)，尝试作为相对路径直接拼接
        if (kDebugMode) {
          print(
              'Warning: Could not parse URL "$originalUrl". Treating as relative path. Error: $e');
        }
        try {
          processedUrl = baseUri.resolve(originalUrl.trim()).toString();
        } catch (resolveError) {
          if (kDebugMode) {
            print(
                'Error: Could not resolve relative path "$originalUrl" with base "$baseUrl". Keeping original. Error: $resolveError');
          }
          processedUrl = originalUrl.trim(); // 拼接也失败，保留原始值
        }
      }

      // --- 3. 处理 raw=true ---
      Uri finalUri;
      try {
        finalUri = Uri.parse(processedUrl);
        Map<String, dynamic> queryParameters =
            Map.from(finalUri.queryParametersAll); // 使用 All 支持同名参数，虽然这里不一定需要

        // 检查 'raw' 参数是否已经是 'true'
        if (queryParameters['raw']?.contains('true') != true) {
          queryParameters['raw'] = 'true'; // 添加或覆盖 raw 参数
          finalUri = finalUri.replace(queryParameters: queryParameters);
          processedUrl = finalUri.toString();
        }
        // 注意: Uri.replace 会自动处理 ? 和 & 的添加
      } catch (e) {
        if (kDebugMode) {
          print(
              'Warning: Could not parse final URL "$processedUrl" for adding raw=true. Skipping. Error: $e');
        }
        // 解析失败，无法添加 raw=true，保留之前的 processedUrl
      }

      // 返回 Markdown 格式的图片
      return '![$altText]($processedUrl)';
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _getBackgroundColor(context),
      padding: const EdgeInsets.all(5.0),
      child: SingleChildScrollView(
        child: MarkdownBody(
          styleSheet: _getStyle(context),
          syntaxHighlighter: GSYHighlighter(),
          data: _processMarkdownImages(markdownData!, baseUrl),
          imageBuilder: (Uri? uri, String? title, String? alt) {
            if (uri == null || uri.toString().isEmpty) return const SizedBox();
            final StringList parts = uri.toString().split('#');
            double? width;
            double? height;
            if (parts.length == 2) {
              final StringList dimensions = parts.last.split('x');
              if (dimensions.length == 2) {
                var [ws, hs] = dimensions;
                width = double.parse(ws);
                height = double.parse(hs);
              }
            }
            return kDefaultImageBuilder(uri, "", width, height);
          },
          onTapLink: (String text, String? href, String title) {
            CommonUtils.gsyLaunchUrl(context, href);
          },
        ),
      ),
    );
  }
}

class GSYHighlighter extends SyntaxHighlighter {
  @override
  TextSpan format(String source) {
    String showSource = source.replaceAll("&lt;", "<");
    showSource = showSource.replaceAll("&gt;", ">");
    return DartSyntaxHighlighter().format(showSource);
  }
}

Widget kDefaultImageBuilder(
  Uri uri,
  String? imageDirectory,
  double? width,
  double? height,
) {
  if (uri.scheme.isEmpty) {
    return const SizedBox();
  }
  if (uri.scheme == 'http' || uri.scheme == 'https') {
    return FutureBuilder<bool>(
      future: _isUrlPointingToSvgDio(uri.toString()),
      builder: (c, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data == true) {
            return SvgPicture.network(
              uri.toString(),
              // Add fallback dimensions
              width: width ?? 24.0,
              height: height ?? 24.0,
              allowDrawingOutsideViewBox: false,
              placeholderBuilder: (BuildContext context) => SizedBox(
                child: Center(
                  child: SpinKitRipple(color: Theme.of(context).primaryColor),
                ),
              ),
            );
          } else {
            return Image.network(uri.toString(), width: width, height: height);
          }
        } else {
          return const SizedBox();
        }
      },
    );
  } else if (uri.scheme == 'data') {
    return _handleDataSchemeUri(uri, width, height);
  } else if (uri.scheme == "resource") {
    return Image.asset(uri.path, width: width, height: height);
  } else {
    Uri fileUri = imageDirectory != null
        ? Uri.parse(imageDirectory + uri.toString())
        : uri;
    if (fileUri.scheme == 'http' || fileUri.scheme == 'https') {
      return Image.network(fileUri.toString(), width: width, height: height);
    } else {
      return Image.file(File.fromUri(fileUri), width: width, height: height);
    }
  }
}

Widget _handleDataSchemeUri(
    Uri uri, final double? width, final double? height) {
  final String mimeType = uri.data!.mimeType;
  if (mimeType.startsWith('image/')) {
    return Image.memory(
      uri.data!.contentAsBytes(),
      width: width,
      height: height,
    );
  } else if (mimeType.startsWith('text/')) {
    return Text(uri.data!.contentAsString());
  }
  return const SizedBox();
}

/// 使用 Dio 检查给定 URL 指向的资源是否可能是 SVG。
///
/// 它优先尝试检查 Content-Type header (通过 HEAD 或 GET 请求)。
/// 如果 Content-Type 不明确，它会下载响应体的一小部分并检查其内容
/// 是否以 SVG 的 XML 标记开头。
///
/// [urlString]: 要检查的 URL 字符串。
/// [timeout]: 整个检查过程的超时设置 (连接和接收)。
///
/// 返回 Future<bool>，如果资源被认为是 SVG，则为 true，否则为 false。
Future<bool> _isUrlPointingToSvgDio(String urlString,
    {Duration timeout = const Duration(seconds: 15)}) async {
  Uri uri;
  try {
    uri = Uri.parse(urlString);
    // Dio 通常处理 scheme，但基础验证有帮助
    if (!uri.isAbsolute || !['http', 'https'].contains(uri.scheme)) {
      throw const FormatException("URL 必须是绝对的 http 或 https URL");
    }
  } catch (e) {
    if (kDebugMode) {
      print("无效的 URL 格式: $urlString - $e");
    }
    return false;
  }

  // 创建 Dio 实例
  // 可以为 Dio 实例配置全局选项，或在每个请求中指定
  final dio = Dio(BaseOptions(
    connectTimeout: timeout, // 连接超时
    receiveTimeout: timeout, // 接收数据超时
    // 不自动跟随重定向，如果需要检查原始响应头的话。
    // 但通常我们关心最终资源，所以让它跟随重定向（默认行为）
    // followRedirects: false,
    // validateStatus: (status) {
    //   // 接受所有状态码，以便我们可以在下面处理它们
    //   return status != null && status < 500; // 例如，只处理非服务器错误
    // },
  ));

  try {
    // --- 1. 尝试 HEAD 请求获取 Headers (更高效) ---
    try {
      // 注意：并非所有服务器都正确支持或允许 HEAD 请求
      final headResponse = await dio.head(urlString); // 超时由 Dio 配置处理

      // Dio 默认只认为 2xx 是成功，这里 statusCode 检查可省略，除非自定义了 validateStatus
      // if (headResponse.statusCode != null && headResponse.statusCode! >= 200 && headResponse.statusCode! < 300) {
      final contentType = headResponse.headers
          .value(Headers.contentTypeHeader); // 获取 Content-Type
      if (kDebugMode) {
        print("HEAD Content-Type for $urlString: $contentType");
      }
      if (contentType != null &&
          contentType.toLowerCase().contains('image/svg+xml')) {
        return true; // 明确是 SVG
      }
      // 如果 Content-Type 不明确，我们仍需尝试 GET
      // }
    } on DioException catch (e) {
      // HEAD 请求失败很常见 (例如 405 Method Not Allowed)，不应阻止尝试 GET
      if (e.type == DioExceptionType.badResponse &&
          e.response?.statusCode == 405) {
        if (kDebugMode) {
          print(
              "HEAD request received 405 (Method Not Allowed) for $urlString. Falling back to GET.");
        }
      } else {
        if (kDebugMode) {
          print(
              "HEAD request failed for $urlString: ${e.type} - ${e.message}. Falling back to GET.");
        }
      }
      // 继续执行 GET 请求
    }

    // --- 2. 如果 HEAD 不可行或 Content-Type 不确定，使用 GET 请求 ---
    final response = await dio.get(
      urlString,
      options: Options(
        responseType: ResponseType.bytes, // **重要**: 获取原始字节用于嗅探
      ),
    );

    // 再次检查状态码 (虽然 Dio 默认会为非 2xx 抛出异常，除非配置了 validateStatus)
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      // 2.1 再次检查 GET 请求的 Content-Type Header
      final contentType = response.headers.value(Headers.contentTypeHeader);
      if (kDebugMode) {
        print("GET Content-Type for $urlString: $contentType");
      }
      if (contentType != null &&
          contentType.toLowerCase().contains('image/svg+xml')) {
        return true; // 明确是 SVG
      }

      // 2.2 Content-Type 不明确? 进行内容嗅探 (Content Sniffing)
      if (response.data is List<int>) {
        final bodyBytes = response.data as List<int>;
        if (bodyBytes.isEmpty) {
          if (kDebugMode) {
            print("Response body is empty for $urlString.");
          }
          return false; // 空内容不是 SVG
        }

        const bytesToCheck = 200; // 检查开头的字节数
        final startBytes = bodyBytes.length > bytesToCheck
            ? bodyBytes.sublist(0, bytesToCheck)
            : bodyBytes;

        try {
          // 尝试用 UTF-8 解码开头部分
          final bodyStart =
              utf8.decode(startBytes, allowMalformed: true).trimLeft();

          // 检查是否以 <svg 开头，或以 <?xml 开头且包含 <svg
          if (bodyStart.startsWith('<svg') ||
              (bodyStart.startsWith('<?xml') && bodyStart.contains('<svg'))) {
            if (kDebugMode) {
              print("Content start matches SVG pattern for $urlString.");
            }
            return true; // 内容看起来像 SVG
          } else {
            // 打印开头一小段供调试（注意可能包含非打印字符）
            if (kDebugMode) {
              print(
                  "Content start does not look like SVG for $urlString. Start (limited length): '${bodyStart.substring(0, bodyStart.length > 50 ? 50 : bodyStart.length)}'");
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print(
                "Error decoding or checking response body start for $urlString: $e");
          }
          // 解码错误可能意味着它不是基于文本的 SVG
          return false;
        }
      } else {
        // 这通常不应该发生，因为我们设置了 ResponseType.bytes
        if (kDebugMode) {
          print(
              "Unexpected response data type: ${response.data?.runtimeType} for $urlString");
        }
        return false;
      }
    } else {
      // 如果自定义了 validateStatus，需要在这里处理非 2xx 状态码
      if (kDebugMode) {
        print(
            "GET request failed or returned non-2xx status: ${response.statusCode} for $urlString");
      }
      return false;
    }
  } on DioException catch (e) {
    // 处理 Dio 的特定异常
    if (kDebugMode) {
      print("DioException caught while checking URL $urlString:");
      print("  Type: ${e.type}");
      if (e.response != null) {
        print("  Status Code: ${e.response?.statusCode}");
        print("  Status Message: ${e.response?.statusMessage}");
      }
      if (e.message != null) {
        print("  Message: ${e.message}");
      }
    }
    return false;
  } catch (e) {
    // 捕获其他任何意外错误
    if (kDebugMode) {
      print("Unexpected error checking URL $urlString: $e");
    }
    return false;
  }

  // 如果所有检查都未通过
  return false;
}
