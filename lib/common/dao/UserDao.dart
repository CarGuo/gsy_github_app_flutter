
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:gsy_github_app_flutter/common/config/Config.dart';
import 'package:gsy_github_app_flutter/common/config/ignoreConfig.dart';
import 'package:gsy_github_app_flutter/common/local/LocalStorage.dart';
import 'package:gsy_github_app_flutter/common/net/Address.dart';
import 'package:gsy_github_app_flutter/common/net/Api.dart';


class UserDao {

  static login(userName, password, callback) async {
    String type= userName + ":" + password;
    var bytes = utf8.encode(type);
    var base64Str = base64.encode(bytes);
    if(Config.DEBUG) {
      print("base64Str login " + base64Str);
    }
    await LocalStorage.save(Config.USER_NAME_KEY, userName);
    await LocalStorage.save(Config.USER_BASIC_CODE, base64Str);

    Map requestParams = {
      "scopes": ['user', 'repo', 'gist', 'notifications'],
      "note": "admin_script",
      "client_id": NetConfig.CLIENT_ID,
      "client_secret": NetConfig.CLIENT_SECRET
    };
    HttpManager.clearAuthorization();

    var res = await HttpManager.netFetch(Address.getAuthorization(), requestParams, null, new Options(method: "post"));
    if (res != null && res.result) {
      await  LocalStorage.save(Config.PW_KEY, password);
      //todo 登录成功后
      print("login result " + res.result.toString());
      print(res.data.toString());
    }
    if (callback != null) {
      callback(res.result);
    }
  }

}