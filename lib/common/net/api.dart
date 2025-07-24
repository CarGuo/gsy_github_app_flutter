import 'package:dio/dio.dart';
import 'package:gsy_github_app_flutter/common/net/code.dart';

import 'dart:collection';

import 'package:gsy_github_app_flutter/common/net/interceptors/error_interceptor.dart';
import 'package:gsy_github_app_flutter/common/net/interceptors/header_interceptor.dart';
import 'package:gsy_github_app_flutter/common/net/interceptors/log_interceptor.dart';

import 'package:gsy_github_app_flutter/common/net/interceptors/response_interceptor.dart';
import 'package:gsy_github_app_flutter/common/net/interceptors/token_interceptor.dart';
import 'package:gsy_github_app_flutter/common/net/result_data.dart';

///http请求
class HttpManager {
  static const String CONTENT_TYPE_JSON = "application/json";
  static const String CONTENT_TYPE_FORM = "application/x-www-form-urlencoded";

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
        errorResponse = Response(statusCode: 666, requestOptions: RequestOptions(path: url));
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
