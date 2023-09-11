import 'package:dio/dio.dart';
import 'package:gsy_github_app_flutter/common/config/config.dart';

/**
 * Log 拦截器
 * Created by guoshuyu
 * on 2019/3/23.
 */
class LogsInterceptors extends InterceptorsWrapper {
  static List<Map?> sHttpResponses = [];
  static List<String?> sResponsesHttpUrl = [];

  static List<Map<String, dynamic>?> sHttpRequest = [];
  static List<String?> sRequestHttpUrl = [];

  static List<Map<String, dynamic>?> sHttpError = [];
  static List<String?> sHttpErrorUrl = [];

  @override
  onRequest(RequestOptions options, handler) async {
    if (Config.DEBUG!) {
      print("请求url：${options.path} ${options.method}");
      options.headers.forEach((k, v) => options.headers[k] = v ?? "");
      print('请求头: ' + options.headers.toString());
      if (options.data != null) {
        print('请求参数: ' + options.data.toString());
      }
    }
    try {
      addLogic(sRequestHttpUrl, options.path);
      var data;
      if (options.data is Map) {
        data = options.data;
      } else {
        data = Map<String, dynamic>();
      }
      var map = {
        "header:": {...options.headers},
      };
      if (options.method == "POST") {
        map["data"] = data;
      }
      addLogic(sHttpRequest, map);
    } catch (e) {
      print(e);
    }
    return super.onRequest(options, handler);
  }

  @override
  onResponse(Response response, handler) async {
    if (Config.DEBUG!) {
      print('返回参数: ' + response.toString());
    }
    switch (response.data.runtimeType) {
      case Map || List:
        {
          try {
            var data = Map<String, dynamic>();
            data["data"] = response.data;
            addLogic(sResponsesHttpUrl, response.requestOptions.uri.toString());
            addLogic(sHttpResponses, data);
          } catch (e) {
            print(e);
          }
        }
      case String:
        {
          try {
            var data = Map<String, dynamic>();
            data["data"] = response.data;
            addLogic(sResponsesHttpUrl, response.requestOptions.uri.toString());
            addLogic(sHttpResponses, data);
          } catch (e) {
            print(e);
          }
        }
    }
    return super.onResponse(response, handler);
  }

  @override
  onError(DioException err, handler) async {
    if (Config.DEBUG!) {
      print('请求异常: ' + err.toString());
      print('请求异常信息: ' + (err.response?.toString() ?? ""));
    }
    try {
      addLogic(sHttpErrorUrl, err.requestOptions.path);
      var errors = Map<String, dynamic>();
      errors["error"] = err.message;
      addLogic(sHttpError, errors);
    } catch (e) {
      print(e);
    }
    return super.onError(err, handler);
  }

  static addLogic(List list, data) {
    if (list.length > 20) {
      list.removeAt(0);
    }
    list.add(data);
  }
}
