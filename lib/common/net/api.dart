import 'package:dio/dio.dart';

import 'dart:collection';

import 'package:gsy_github_app_flutter/common/net/interceptors/error_interceptor.dart';
import 'package:gsy_github_app_flutter/common/net/interceptors/header_interceptor.dart';
import 'package:gsy_github_app_flutter/common/net/interceptors/log_interceptor.dart';

import 'package:gsy_github_app_flutter/common/net/interceptors/response_interceptor.dart';
import 'package:gsy_github_app_flutter/common/net/interceptors/token_interceptor.dart';

///http请求
class HttpManager {
  static const CONTENT_TYPE_JSON = "application/json";
  static const CONTENT_TYPE_FORM = "application/x-www-form-urlencoded";

  Dio _dio = new Dio(); // 使用默认配置

  final TokenInterceptors _tokenInterceptors = new TokenInterceptors();

  HttpManager() {

    _dio.interceptors.add(new HeaderInterceptors());

    _dio.interceptors.add(_tokenInterceptors);

    _dio.interceptors.add(new LogsInterceptors());

    _dio.interceptors.add(new ErrorInterceptors(_dio));

    _dio.interceptors.add(new ResponseInterceptors());
  }

  ///发起网络请求
  ///[ url] 请求url
  ///[ params] 请求参数
  ///[ header] 外加头
  ///[ option] 配置
  netFetch(url, params, Map<String, dynamic> header, Options option, {noTip = false}) async {
    Map<String, dynamic> headers = new HashMap();
    if (header != null) {
      headers.addAll(header);
    }

    if (option != null) {
      option.headers = headers;
    } else {
      option = new Options(method: "get");
      option.headers = headers;
    }

    option.headers[NOT_TIP_KEY] = noTip;

    Response response;
    try {
      response = await _dio.request(url, data: params, options: option);
    } catch (e) {
      print(e.toString());
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
}

final HttpManager httpManager = new HttpManager();
