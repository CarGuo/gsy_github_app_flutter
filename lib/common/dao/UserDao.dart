import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gsy_github_app_flutter/common/config/Config.dart';
import 'package:gsy_github_app_flutter/common/config/ignoreConfig.dart';
import 'package:gsy_github_app_flutter/common/dao/DaoResult.dart';
import 'package:gsy_github_app_flutter/common/local/LocalStorage.dart';
import 'package:gsy_github_app_flutter/common/model/User.dart';
import 'package:gsy_github_app_flutter/common/net/Address.dart';
import 'package:gsy_github_app_flutter/common/net/Api.dart';
import 'package:gsy_github_app_flutter/common/redux/UserRedux.dart';
import 'package:gsy_github_app_flutter/widget/EventItem.dart';
import 'package:gsy_github_app_flutter/widget/UserItem.dart';
import 'package:redux/redux.dart';

class UserDao {
  static login(userName, password, callback) async {
    String type = userName + ":" + password;
    var bytes = utf8.encode(type);
    var base64Str = base64.encode(bytes);
    if (Config.DEBUG) {
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

    var res = await HttpManager.netFetch(Address.getAuthorization(), json.encode(requestParams), null, new Options(method: "post"));
    if (res != null && res.result) {
      await LocalStorage.save(Config.PW_KEY, password);
      var resultData = await getUserInfo(null);
      if (Config.DEBUG) {
        print("user result " + resultData.result.toString());
        print(resultData.data);
        print(res.data.toString());
      }
    }
    if (callback != null) {
      callback(res);
    }
  }

  ///初始化用户信息
  static initUserInfo(Store store) async {
    var token = await LocalStorage.get(Config.TOKEN_KEY);
    var res = await getUserInfoLocal();
    if (res != null && res.result && token != null) {
      store.dispatch(UpdateUserAction(res.data));
    }
    return new DataResult(res.data, (res.result && (token != null)));
  }

  ///获取本地登录用户信息
  static getUserInfoLocal() async {
    var userText = await LocalStorage.get(Config.USER_INFO);
    if (userText != null) {
      var userMap = json.decode(userText);
      User user = User.fromJson(userMap);
      return new DataResult(user, true);
    } else {
      return new DataResult(null, false);
    }
  }

  ///获取用户详细信息
  static getUserInfo(userName) async {
    var res;
    if (userName == null) {
      res = await HttpManager.netFetch(Address.getMyUserInfo(), null, null, null);
    } else {
      res = await HttpManager.netFetch(Address.getUserInfo(userName), null, null, null);
    }
    if (res != null && res.result) {
      String starred = "---";
      if(res.data["type"] !=  "Organization") {
        var countRes = await getUserStaredCountNet(res.data["login"]);
        if (countRes.result) {
          starred = countRes.data;
        }
      }
      User user = User.fromJson(res.data);
      user.starred = starred;
      if (userName == null) {
        LocalStorage.save(Config.USER_INFO, json.encode(res.data));
      }
      return new DataResult(user, true);
    } else {
      return new DataResult(res.data, false);
    }
  }

  static clearAll() async {
    HttpManager.clearAuthorization();
    LocalStorage.remove(Config.USER_INFO);
  }

  /**
   * 在header中提起stared count
   */
  static getUserStaredCountNet(userName) async {
    String url = Address.userStar(userName, null) + "&per_page=1";
    var res = await HttpManager.netFetch(url, null, null, null);
    if (res != null && res.result && res.headers != null) {
      try {
        List<String> link = res.headers['link'];
        if (link != null) {
          int indexStart = link[0].lastIndexOf("page=") + 5;
          int indexEnd = link[0].lastIndexOf(">");
          if (indexStart >= 0 && indexEnd >= 0) {
            String count = link[0].substring(indexStart, indexEnd);
            return new DataResult(count, true);
          }
        }
      } catch (e) {
        print(e);
      }
    }
    return new DataResult(null, false);
  }

  /**
   * 获取用户粉丝列表
   */
  static getFollowerListDao(userName, page) async {
    String url = Address.getUserFollower(userName) + Address.getPageParams("?", page);
    var res = await HttpManager.netFetch(url, null, null, null);
    if (res != null && res.result) {
      List<UserItemViewModel> list = new List();
      var data = res.data;
      if (data == null || data.length == 0) {
        return new DataResult(null, false);
      }
      for (int i = 0; i < data.length; i++) {
        list.add(new UserItemViewModel(data[i]['login'], data[i]["avatar_url"]));
      }
      return new DataResult(list, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * 获取用户关注列表
   */
  static getFollowedListDao(userName, page) async {
    String url = Address.getUserFollow(userName) + Address.getPageParams("?", page);
    var res = await HttpManager.netFetch(url, null, null, null);
    if (res != null && res.result) {
      List<UserItemViewModel> list = new List();
      var data = res.data;
      if (data == null || data.length == 0) {
        return new DataResult(null, false);
      }
      for (int i = 0; i < data.length; i++) {
        list.add(new UserItemViewModel(data[i]['login'], data[i]["avatar_url"]));
      }
      return new DataResult(list, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * 获取用户相关通知
   */
  static getNotifyDao(bool all, bool participating, page) async {
    String tag = (!all && !participating) ? '?' : "&";
    String url = Address.getNotifation(all, participating) + Address.getPageParams(tag, page);
    var res = await HttpManager.netFetch(url, null, null, null);
    if (res != null && res.result) {
      List<EventViewModel> list = new List();
      var data = res.data;
      if (data == null || data.length == 0) {
        return new DataResult([], true);
      }
      for (int i = 0; i < data.length; i++) {
        list.add(EventViewModel.fromNotify(data[i]));
      }
      return new DataResult(list, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * 设置单个通知已读
   */
  static setNotificationAsReadDao(id) async {
    String url = Address.setNotificationAsRead(id);
    var res = await HttpManager.netFetch(url, null, null, new Options(method: "PATCH"));
    return res;
  }

  /**
   * 检查用户关注状态
   */
  static checkFollowDao(name) async {
    String url = Address.doFollow(name);
    var res = await HttpManager.netFetch(url, null, null, new Options(contentType: ContentType.TEXT), noTip: true);
    return new DataResult(res.data, res.result);
  }

  /**
   * 关注用户
   */
  static doFollowDao(name, bool followed) async {
    String url = Address.doFollow(name);
    print(followed);
    var res = await HttpManager.netFetch(url, null, null, new Options(method: !followed ? "PUT" : "DELETE"), noTip: true);
    return new DataResult(res.data, res.result);
  }

  /**
   * 组织成员
   */
  static getMemberDao(userName, page) async {
    String url = Address.getMember(userName) + Address.getPageParams("?", page);
    var res = await HttpManager.netFetch(url, null, null, null);
    if (res != null && res.result) {
      List<UserItemViewModel> list = new List();
      var data = res.data;
      if (data == null || data.length == 0) {
        return new DataResult(null, false);
      }
      for (int i = 0; i < data.length; i++) {
        list.add(new UserItemViewModel(data[i]['login'], data[i]["avatar_url"]));
      }
      return new DataResult(list, true);
    } else {
      return new DataResult(null, false);
    }
  }
}
