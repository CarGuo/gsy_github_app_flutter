import 'package:dio/dio.dart';
import 'package:gsy_github_app_flutter/common/logger.dart';
import 'package:gsy_github_app_flutter/common/net/code.dart';

import 'dart:collection';

//import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:gsy_github_app_flutter/common/net/interceptors/error_interceptor.dart';
import 'package:gsy_github_app_flutter/common/net/interceptors/header_interceptor.dart';
import 'package:gsy_github_app_flutter/common/net/interceptors/log_interceptor.dart';

import 'package:gsy_github_app_flutter/common/net/interceptors/response_interceptor.dart';
import 'package:gsy_github_app_flutter/common/net/interceptors/token_interceptor.dart';
import 'package:gsy_github_app_flutter/common/net/result_data.dart';

///http请求
class HttpManager {
  static const CONTENT_TYPE_JSON = "application/json";
  static const CONTENT_TYPE_FORM = "application/x-www-form-urlencoded";
  late final Dio _dio;
  late final TokenInterceptors _tokenInterceptors;

  HttpManager._internal() {
    _dio = Dio(); // 使用默认配置
    _tokenInterceptors = TokenInterceptors();

    _dio.interceptors.addAll([
      HeaderInterceptors(),
      _tokenInterceptors,
      LogsInterceptors(),
      ErrorInterceptors(),
      ResponseInterceptors(),
    ]);
  }

  static final HttpManager _instance = HttpManager._internal();

  ///发起网络请求
  ///[ url] 请求url
  ///[ params] 请求参数
  ///[ header] 外加头
  ///[ option] 配置
  Future<ResultData?> netFetch(
      url, params, Map<String, dynamic>? header, Options? option,
      {noTip = false}) async {
    Map<String, dynamic> headers = HashMap();
    if (header != null) {
      headers.addAll(header);
    }

    if (option != null) {
      option.headers = headers;
    } else {
      option = Options(method: "get");
      option.headers = headers;
    }

    resultError(DioException e) {
      Response? errorResponse;
      if (e.response != null) {
        errorResponse = e.response;
      } else {
        errorResponse = Response(
            statusCode: 666, requestOptions: RequestOptions(path: url));
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorResponse!.statusCode = Code.NETWORK_TIMEOUT;
      }
      return ResultData(
          Code.errorHandleFunction(errorResponse!.statusCode, e.message, noTip),
          false,
          errorResponse.statusCode);
    }

    Response response;
    try {
      response = await _dio.request(url, data: params, options: option);
    } on DioException catch (e) {
      return resultError(e);
    } catch (e, s) {
      // 2026-09 修：netFetch 之前只 catch DioException，
      // 但底层可能抛：
      //   - Interceptor 里的插件异常（connectivity_plus 在 iOS 模拟器上
      //     偶发失败、Fluttertoast 平台通道抛 MissingPluginException）
      //   - SocketException / HandshakeException / TlsException（部分场景
      //     dio 不会重新包装为 DioException）
      //   - JSON 解析或 TypeError 等运行时错误
      // 这些异常穿透到调用方（typically 一个 await）后，UI 层的 Loading
      // dialog 就永远关不掉、Redux 的 LoginSuccessAction 也不会 yield。
      // 这里统一兜底为 ResultData(false)，把"网络异常"和"请求失败"归为同一类
      // 对上层的语义，保证调用点永远拿得到一个 ResultData，走正常失败分支。
      printLog('netFetch caught non-Dio error on $url: $e\n$s');
      return ResultData(
          Code.errorHandleFunction(Code.NETWORK_ERROR, e.toString(), noTip),
          false,
          Code.NETWORK_ERROR);
    }
    if (response.data is DioException) {
      return resultError(response.data);
    }
    return response.data;
  }

  ///清除授权
  clearAuthorization() {
    _tokenInterceptors.clearAuthorization();
  }

  ///获取授权token
  getAuthorization() async {
    return _tokenInterceptors.getAuthorization();
  }

  /// 提供单例访问
  static HttpManager get instance => _instance;
}

final HttpManager httpManager = HttpManager.instance;

//
//
// initDio() {
//   DioClient.getInstance();
//   initializeNetworkListener();
// }
//
// class DioClient {
//   static Dio? _dio;
//
//   DioClient._();
//
//   static Future<Dio> getInstance() async {
//     if (_dio == null) {
//       await _initialize();
//     }
//     return _dio!;
//   }
//
//   static Future<void> _initialize() async {
//     _dio = Dio(BaseOptions(
//       connectTimeout: const Duration(seconds: 10),
//       receiveTimeout: const Duration(seconds: 10),
//     ));
//
//     _dio!.interceptors.add(LogInterceptor(
//       requestHeader: true,
//       requestBody: true,
//       responseHeader: true,
//       responseBody: true,
//     ));
//   }
//
//   static void reset() {
//     _dio?.close();
//     _dio = null;
//   }
// }
//
// void initializeNetworkListener() {
//   Connectivity().onConnectivityChanged.listen((result) {
//     DioClient.reset();
//   });
// }
