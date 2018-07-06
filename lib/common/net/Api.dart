

import 'package:dio/dio.dart';
import 'package:gsy_github_app_flutter/common/net/Code.dart';

import 'dart:collection';

import 'package:gsy_github_app_flutter/common/config/Config.dart';
import 'package:gsy_github_app_flutter/common/local/LocalStorage.dart';
import 'package:gsy_github_app_flutter/common/net/ResultData.dart';

///http请求
class HttpManager {
  static const CONTENT_TYPE_JSON = "application/json";
  static const CONTENT_TYPE_FORM = "application/x-www-form-urlencoded";
  static Map optionParams = {
    "timeoutMs": 15000,
    "token": null,
    "authorizationCode": null,
  };

  ///发起网络请求
  ///[ url] 请求url
  ///[ params] 请求参数
  ///[ header] 外加头
  ///[ text] 是否text返回
  ///[ option] 配置
  static netFetch(url, params, Map<String, String> header, Options option) async {

    //todo 没有网络
    /*var isConnected = await NetInfo.isConnected.fetch().done;
      if (!isConnected) {
      return {
      result: false,
      code: Code.NETWORK_ERROR,
      msg: I18n('netError')
      }
      }*/

    Map<String, String> headers = new HashMap();
    if (header != null) {
      headers.addAll(headers);
    }

    //授权码
    if (optionParams["authorizationCode"] == null) {
      var authorizationCode = await getAuthorization();
      if (authorizationCode != null) {
        optionParams["authorizationCode"] = authorizationCode;
      }
    }

    headers["Authorization"] = optionParams["authorizationCode"];

    option.headers = headers;

    Dio dio = new Dio();
    Response response = await dio.get(url, data: params, options: option);

    if (Config.DEBUG) {
      print('请求url: ' + url);
      if (params != null) {
        print('请求参数: ' + params.toString());
      }
      if (response != null) {
        print('返回参数: ' + response.toString());
      }
    }

    try {
      if (option.contentType != null && option.contentType.primaryType == "text") {
        return new ResultData(response.data, true, Code.SUCCESS);
      } else {
        var responseJson = await response.data;
        if (response.statusCode == 201 && responseJson.token != null) {
          optionParams["authorizationCode"] = 'token ' + responseJson.token;
          await LocalStorage.save(Config.TOKEN_KEY, optionParams["authorizationCode"]);
        }
      }
      if (response.statusCode == 200 || response.statusCode == 201) {
        return new ResultData(response.data, true, Code.SUCCESS, headers: response.headers);
      }
    } catch (e) {
      print(e.toString() + url);
      return new ResultData(response.data, false, response.statusCode, headers: response.headers);
    }
    return new ResultData(Code.errorHandleFunction(response.statusCode), false, response.statusCode);
  }

  ///清除授权
  static clearAuthorization() {
    optionParams["authorizationCode"] = null;
    LocalStorage.remove(Config.TOKEN_KEY);
  }

  ///获取授权token
  static getAuthorization() async {
    String token = await LocalStorage.get(Config.TOKEN_KEY);
    if (token == null) {
      String basic = await LocalStorage.get(Config.USER_BASIC_CODE);
      if (basic == null) {
        //提示输入账号密码
      } else {
        //通过 basic 去获取token，获取到设置，返回token
        return "Basic $basic";
      }
    } else {
      optionParams["authorizationCode"] = token;
      return token;
    }
  }
}
