import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gsy_github_app_flutter/common/net/code.dart';
import 'package:gsy_github_app_flutter/common/net/result_data.dart';

/// Token拦截器
/// Created by guoshuyu
/// on 2019/3/23.
class ResponseInterceptors extends InterceptorsWrapper {
  @override
  onResponse(Response response, handler) async {
    RequestOptions option = response.requestOptions;
    dynamic value;
    try {
      var header = response.headers[Headers.contentTypeHeader];
      if ((header != null && header.toString().contains("text"))) {
        value = ResultData(response.data, true, Code.SUCCESS);
      } else if (response.statusCode! >= 200 && response.statusCode! < 300) {
        value = ResultData(response.data, true, Code.SUCCESS,
            headers: response.headers);
      }
    } catch (e) {
      if (kDebugMode) {
        print(e.toString() + option.path);
      }
      value = ResultData(response.data, false, response.statusCode,
          headers: response.headers);
    }
    response.data = value;
    return handler.next(response);
  }
}
