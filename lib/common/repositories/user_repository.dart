import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gsy_github_app_flutter/common/logger.dart';
import 'package:gsy_github_app_flutter/common/net/graphql/client.dart';
import 'package:gsy_github_app_flutter/db/provider/user/user_followed_db_provider.dart';
import 'package:gsy_github_app_flutter/db/provider/user/user_follower_db_provider.dart';
import 'package:gsy_github_app_flutter/db/provider/user/userinfo_db_provider.dart';
import 'package:gsy_github_app_flutter/db/provider/user/user_orgs_db_provider.dart';
import 'package:gsy_github_app_flutter/common/config/config.dart';
import 'package:gsy_github_app_flutter/common/config/ignoreConfig.dart';
import 'package:gsy_github_app_flutter/common/repositories/data_result.dart';
import 'package:gsy_github_app_flutter/common/local/local_storage.dart';
import 'package:gsy_github_app_flutter/model/notification.dart' as Model;
import 'package:gsy_github_app_flutter/model/search_user_ql.dart';
import 'package:gsy_github_app_flutter/model/user.dart';
import 'package:gsy_github_app_flutter/model/user_org.dart';
import 'package:gsy_github_app_flutter/common/net/address.dart';
import 'package:gsy_github_app_flutter/common/net/api.dart';
import 'package:gsy_github_app_flutter/provider/app_state_provider.dart';
import 'package:gsy_github_app_flutter/redux/gsy_state.dart';
import 'package:gsy_github_app_flutter/redux/user_redux.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:redux/redux.dart';

class UserRepository {
  static oauth(code, store) async {
    httpManager.clearAuthorization();

    var res = await httpManager.netFetch(
      "https://github.com/login/oauth/access_token?"
      "client_id=${NetConfig.CLIENT_ID}"
      "&client_secret=${NetConfig.CLIENT_SECRET}"
      "&code=$code",
      null,
      null,
      Options(method: "POST"),
    );
    dynamic resultData;
    if (res != null && res.result) {
      var result = Uri.parse("gsy://oauth?${res.data}");
      var token = result.queryParameters["access_token"]!;
      var token0 = 'token $token';
      await LocalStorage.save(Config.TOKEN_KEY, token0);

      resultData = await getUserInfo(null);
      if (Config.DEBUG!) {
        printLog("user result ${resultData.result}");
        printLog(resultData.data);
        printLog(res.data.toString());
      }
      if (resultData.result == true) {
        store.dispatch(UpdateUserAction(resultData.data));
      }
    }

    return DataResult(resultData, res!.result);
  }

  /// 使用用户提供的 Personal Access Token（PAT）直接登录。
  ///
  /// 背景：
  /// - GitHub 已于 2020-11-13 关停 basic-auth 密码 API，[login] 已 deprecated
  /// - OAuth 走 webview 拿 `code` → `access_token`，但对无浏览器 / 无 CLIENT_SECRET
  ///   的场景（例如新装机首次登录、需要绕过 webview 的调试路径）不方便
  /// - 官方推荐 PAT（fine-grained 或 classic）作为 API 认证凭据，可直接以
  ///   `Authorization: token <PAT>` 携带
  ///
  /// 与 [oauth] 保持完全一致的 **token 落地流程**：
  ///   1. 清 httpManager 已缓存的旧 token（避免旧 401 残留）
  ///   2. 写入 [Config.TOKEN_KEY]（拦截器 [TokenInterceptor] 读的就是它）
  ///   3. `getUserInfo(null)` 拉一次自己的 profile，作为 token 有效性校验
  ///   4. 成功 → dispatch [UpdateUserAction]；失败 → 回滚 token，让 UI 提示
  ///
  /// 返回 [DataResult]，`result=true` 当且仅当 `/user` 拉到了合法用户。
  /// 上层（[TokenLoginAction] 的 epic）根据 result 决定 [LoginSuccessAction]。
  static loginWithToken(String rawToken, store) async {
    final trimmed = rawToken.trim();
    if (trimmed.isEmpty) {
      return DataResult(null, false);
    }

    // 兼容用户粘贴时带上 "token " / "Bearer " / 前后空白等噪音
    String bareToken = trimmed;
    final lower = bareToken.toLowerCase();
    if (lower.startsWith('token ')) {
      bareToken = bareToken.substring(6).trim();
    } else if (lower.startsWith('bearer ')) {
      bareToken = bareToken.substring(7).trim();
    }
    if (bareToken.isEmpty) {
      return DataResult(null, false);
    }

    httpManager.clearAuthorization();
    final headerValue = 'token $bareToken';
    await LocalStorage.save(Config.TOKEN_KEY, headerValue);

    final resultData = await getUserInfo(null);
    if (Config.DEBUG!) {
      printLog("token login user result ${resultData.result}");
    }
    if (resultData != null && resultData.result == true) {
      store.dispatch(UpdateUserAction(resultData.data));
      return DataResult(resultData.data, true);
    }

    // token 不合法（401 / 403 / 网络异常）：立刻回滚，避免下次冷启动
    // [initUserInfo] 读到一个不能用的 token 又静默"看起来已登录"，把用户困在错状态。
    await LocalStorage.remove(Config.TOKEN_KEY);
    httpManager.clearAuthorization();
    return DataResult(null, false);
  }

  static login(String userName, String password, store) async {
    String type = "$userName:$password";
    var bytes = utf8.encode(type);
    var base64Str = base64.encode(bytes);
    if (Config.DEBUG!) {
      printLog("base64Str login $base64Str");
    }

    await LocalStorage.save(Config.USER_NAME_KEY, userName);
    await LocalStorage.save(Config.USER_BASIC_CODE, base64Str);

    Map requestParams = {
      "scopes": ['user', 'repo', 'gist', 'notifications'],
      "note": "admin_script",
      "client_id": NetConfig.CLIENT_ID,
      "client_secret": NetConfig.CLIENT_SECRET,
    };
    httpManager.clearAuthorization();

    var res = await httpManager.netFetch(
      Address.getAuthorization(),
      json.encode(requestParams),
      null,
      Options(method: "post"),
    );
    dynamic resultData;
    if (res != null && res.result) {
      await LocalStorage.save(Config.PW_KEY, password);
      var resultData = await getUserInfo(null);
      if (Config.DEBUG!) {
        printLog("user result ${resultData.result}");
        printLog(resultData.data);
        printLog(res.data.toString());
      }
      store.dispatch(UpdateUserAction(resultData.data));
    }
    return DataResult(resultData, res!.result);
  }

  ///初始化用户信息
  static initUserInfo(Store<GSYState> store, WidgetRef ref) async {
    var token = await LocalStorage.get(Config.TOKEN_KEY);
    var res = await getUserInfoLocal();
    if (res != null && res.result && token != null) {
      store.dispatch(UpdateUserAction(res.data));
    }

    ///读取主题
    String? themeIndex = await LocalStorage.get(Config.THEME_COLOR);
    ref.read(appThemeStateProvider.notifier).pushTheme(themeIndex);

    ///切换语言
    String? localeIndex = await LocalStorage.get(Config.LOCALE);
    ref.read(appLocalStateProvider.notifier).changeLocale(localeIndex);

    ///震动开关
    String? vibrationEnable = await LocalStorage.get(Config.VIBRATION_ENABLE);
    bool enable = vibrationEnable != "false";
    ref
        .read(appVibrationStateProvider.notifier)
        .changeVibration(enable, save: false);

    return DataResult(res.data, (res.result && (token != null)));
  }

  ///获取本地登录用户信息
  static getUserInfoLocal() async {
    var userText = await LocalStorage.get(Config.USER_INFO);
    if (userText != null) {
      var userMap = json.decode(userText);
      User user = User.fromJson(userMap);
      return DataResult(user, true);
    } else {
      return DataResult(null, false);
    }
  }

  ///获取用户详细信息
  static getUserInfo(String? userName, {needDb = false}) async {
    UserInfoDbProvider provider = UserInfoDbProvider();
    next() async {
      dynamic res;
      if (userName == null) {
        res = await httpManager.netFetch(
          Address.getMyUserInfo(),
          null,
          null,
          null,
        );
      } else {
        res = await httpManager.netFetch(
          Address.getUserInfo(userName),
          null,
          null,
          null,
        );
      }
      if (res != null && res.result) {
        String? starred = "---";
        if (res.data["type"] != "Organization") {
          var countRes = await getUserStaredCountNet(res.data["login"]);
          if (countRes.result) {
            starred = countRes.data;
          }
        }
        User user = User.fromJson(res.data);
        user.starred = starred;
        if (userName == null) {
          LocalStorage.save(Config.USER_INFO, json.encode(user.toJson()));
        } else {
          if (needDb) {
            provider.insert(userName, json.encode(user.toJson()));
          }
        }
        return DataResult(user, true);
      } else {
        return DataResult(res.data, false);
      }
    }

    if (needDb) {
      User? user = await provider.getUserInfo(userName);
      if (user == null) {
        return await next();
      }
      DataResult dataResult = DataResult(user, true, next: next);
      return dataResult;
    }
    return await next();
  }

  static clearAll(Store store) async {
    httpManager.clearAuthorization();
    LocalStorage.remove(Config.USER_INFO);
    store.dispatch(UpdateUserAction(User.empty()));
  }

  /// 在header中提起stared count
  static getUserStaredCountNet(String userName) async {
    String url = Address.userStar(userName, null) + "&per_page=1";
    var res = await httpManager.netFetch(url, null, null, null);
    if (res != null && res.result && res.headers != null) {
      try {
        StringList? link = res.headers['link'];
        if (link != null) {
          var [linkFirst] = link;
          int indexStart = linkFirst.lastIndexOf("page=") + 5;
          int indexEnd = linkFirst.lastIndexOf(">");
          if (indexStart >= 0 && indexEnd >= 0) {
            String count = linkFirst.substring(indexStart, indexEnd);
            return DataResult(count, true);
          }
        }
      } catch (e) {
        printLog(e);
      }
    }
    return DataResult(null, false);
  }

  /// 获取用户粉丝列表
  static getFollowerListRequest(String userName, page, {needDb = false}) async {
    UserFollowerDbProvider provider = UserFollowerDbProvider();

    next() async {
      String url =
          Address.getUserFollower(userName) + Address.getPageParams("?", page);
      var res = await httpManager.netFetch(url, null, null, null);
      if (res != null && res.result) {
        List<User> list = [];
        var data = res.data;
        if (data == null || data.length == 0) {
          return DataResult(null, false);
        }
        for (int i = 0; i < data.length; i++) {
          list.add(User.fromJson(data[i]));
        }
        if (needDb) {
          provider.insert(userName, json.encode(data));
        }
        return DataResult(list, true);
      } else {
        return DataResult(null, false);
      }
    }

    if (needDb) {
      List<User>? list = await provider.geData(userName);
      if (list == null) {
        return await next();
      }
      DataResult dataResult = DataResult(list, true, next: next);
      return dataResult;
    }
    return await next();
  }

  /// 获取用户关注列表
  static getFollowedListRequest(String userName, page, {needDb = false}) async {
    UserFollowedDbProvider provider = UserFollowedDbProvider();
    next() async {
      String url =
          Address.getUserFollow(userName) + Address.getPageParams("?", page);
      var res = await httpManager.netFetch(url, null, null, null);
      if (res != null && res.result) {
        List<User> list = [];
        var data = res.data;
        if (data == null || data.length == 0) {
          return DataResult(null, false);
        }
        for (int i = 0; i < data.length; i++) {
          list.add(User.fromJson(data[i]));
        }
        if (needDb) {
          provider.insert(userName, json.encode(data));
        }
        return DataResult(list, true);
      } else {
        return DataResult(null, false);
      }
    }

    if (needDb) {
      List<User>? list = await provider.geData(userName);
      if (list == null) {
        return await next();
      }
      DataResult dataResult = DataResult(list, true, next: next);
      return dataResult;
    }
    return await next();
  }

  /// 获取用户相关通知
  static getNotifyRequest(bool all, bool participating, page) async {
    String tag = (!all && !participating) ? '?' : "&";
    String url =
        Address.getNotifation(all, participating) +
        Address.getPageParams(tag, page);
    var res = await httpManager.netFetch(url, null, null, null);
    if (res != null && res.result) {
      List<Model.Notification> list = [];
      var data = res.data;
      if (data == null || data.length == 0) {
        return DataResult([], true);
      }
      for (int i = 0; i < data.length; i++) {
        list.add(Model.Notification.fromJson(data[i]));
      }
      return DataResult(list, true);
    } else {
      return DataResult(null, false);
    }
  }

  /// 设置单个通知已读
  static setNotificationAsReadRequest(id) async {
    String url = Address.setNotificationAsRead(id);
    var res = await httpManager.netFetch(
      url,
      null,
      null,
      Options(method: "PATCH"),
      noTip: true,
    );
    return res;
  }

  /// 归档单个通知（对应官方 App 的 "Done / mark as done"）
  /// GitHub API：DELETE /notifications/threads/{id}
  /// 返回 DataResult 让上层能区分成功/失败，UI 层可以按结果做提示或回滚。
  static archiveNotificationThreadRequest(id) async {
    String url = Address.archiveNotificationThread(id);
    var res = await httpManager.netFetch(
      url,
      null,
      null,
      Options(method: "DELETE"),
      noTip: true,
    );
    return DataResult(res?.data, res?.result ?? false);
  }

  /// 获取单个 thread 的订阅状态（GET，noTip 因为 404 也算正常）。
  /// 200 时 body 里 subscribed / ignored 反映当前状态。
  static getNotificationThreadSubscriptionRequest(id) async {
    String url = Address.notificationThreadSubscription(id);
    var res = await httpManager.netFetch(
      url,
      null,
      null,
      null,
      noTip: true,
    );
    return DataResult(res?.data, res?.result ?? false);
  }

  /// 订阅 thread（subscribed=true, ignored=false）。
  /// GitHub API：PUT /notifications/threads/{id}/subscription
  static subscribeNotificationThreadRequest(id) async {
    String url = Address.notificationThreadSubscription(id);
    var res = await httpManager.netFetch(
      url,
      {"subscribed": true, "ignored": false},
      null,
      Options(method: "PUT"),
      noTip: true,
    );
    return DataResult(res?.data, res?.result ?? false);
  }

  /// 取消订阅 thread（等价于恢复到 none 状态）。
  /// GitHub API：DELETE /notifications/threads/{id}/subscription
  static unsubscribeNotificationThreadRequest(id) async {
    String url = Address.notificationThreadSubscription(id);
    var res = await httpManager.netFetch(
      url,
      null,
      null,
      Options(method: "DELETE"),
      noTip: true,
    );
    return DataResult(res?.data, res?.result ?? false);
  }

  /// 设置所有通知已读
  static setAllNotificationAsReadRequest() async {
    String url = Address.setAllNotificationAsRead();
    var res = await httpManager.netFetch(
      url,
      null,
      null,
      Options(method: "PUT"),
    );
    return DataResult(res!.data, res.result);
  }

  /// 检查用户关注状态
  static checkFollowRequest(String name) async {
    String url = Address.doFollow(name);
    var res = await httpManager.netFetch(url, null, null, null, noTip: true);
    return DataResult(res!.data, res.result);
  }

  /// 关注用户
  static doFollowRequest(String name, bool followed) async {
    String url = Address.doFollow(name);
    var res = await httpManager.netFetch(
      url,
      null,
      null,
      Options(method: !followed ? "PUT" : "DELETE"),
      noTip: true,
    );
    return DataResult(res!.data, res.result);
  }

  /// 组织成员
  static getMemberRequest(String userName, page) async {
    String url = Address.getMember(userName) + Address.getPageParams("?", page);
    var res = await httpManager.netFetch(url, null, null, null);
    if (res != null && res.result) {
      List<User> list = [];
      var data = res.data;
      if (data == null || data.length == 0) {
        return DataResult(null, false);
      }
      for (int i = 0; i < data.length; i++) {
        list.add(User.fromJson(data[i]));
      }
      return DataResult(list, true);
    } else {
      return DataResult(null, false);
    }
  }

  /// 更新用户信息
  static updateUserRequest(params, Store store) async {
    String url = Address.getMyUserInfo();
    var res = await httpManager.netFetch(
      url,
      params,
      null,
      Options(method: "PATCH"),
    );
    if (res != null && res.result) {
      var localResult = await getUserInfoLocal();
      User newUser = User.fromJson(res.data);
      newUser.starred = localResult.data.starred;
      await LocalStorage.save(Config.USER_INFO, json.encode(newUser.toJson()));
      store.dispatch(UpdateUserAction(newUser));
      return DataResult(newUser, true);
    }
    return DataResult(null, false);
  }

  /// 获取用户组织
  static getUserOrgsRequest(String userName, page, {needDb = false}) async {
    UserOrgsDbProvider provider = UserOrgsDbProvider();
    next() async {
      String url =
          Address.getUserOrgs(userName) + Address.getPageParams("?", page);
      var res = await httpManager.netFetch(url, null, null, null);
      if (res != null && res.result) {
        List<UserOrg> list = [];
        var data = res.data;
        if (data == null || data.length == 0) {
          return DataResult(null, false);
        }
        for (int i = 0; i < data.length; i++) {
          list.add(UserOrg.fromJson(data[i]));
        }
        if (needDb) {
          provider.insert(userName, json.encode(data));
        }
        return DataResult(list, true);
      } else {
        return DataResult(null, false);
      }
    }

    if (needDb) {
      List<UserOrg>? list = await provider.geData(userName);
      if (list == null) {
        return await next();
      }
      DataResult dataResult = DataResult(list, true, next: next);
      return dataResult;
    }
    return await next();
  }

  /// 获取 user / organization 的 Pinned Repositories 原始 node 列表（最多 6 条）
  ///
  /// 这里刻意只返回 `List<Map>`：
  /// - pinned 只在 [PersonPage] 展示，模型 [UserPinnedItemViewModel] 也就近放在
  ///   [lib/page/user/widget/user_pinned.dart] 里；repository 不引入 widget 层类
  /// - GraphQL 层已在 [readUserPinnedItems] 里用 `types: REPOSITORY` 过滤，此处
  ///   遇到 null 或空节点直接返回空列表，让 UI 侧决定隐藏 or 展示占位
  ///
  /// 注意：GSY 定位是"只读+评论"（见 AGENTS.md 允许/禁止清单），这里只做读取，
  /// 不做置顶顺序编辑或 pinnedItems mutation。
  static getUserPinnedItemsRequest(String userName) async {
    var result = await getUserPinnedItems(userName);
    if (result == null || result.data == null) {
      return DataResult(<Map<String, dynamic>>[], false);
    }
    var user = result.data!["user"];
    if (user == null) {
      return DataResult(<Map<String, dynamic>>[], false);
    }
    var pinnedItems = user["pinnedItems"];
    if (pinnedItems == null || pinnedItems["nodes"] == null) {
      return DataResult(<Map<String, dynamic>>[], true);
    }
    List nodes = pinnedItems["nodes"] as List;
    // pinnedItems 允许 Gist，但 query 已限定 REPOSITORY；保险起见过滤掉空 map。
    List<Map<String, dynamic>> list = nodes
        .whereType<Map>()
        .where((e) => e.isNotEmpty)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    return DataResult(list, true);
  }

  /// 获取指定用户的 status（emoji / message / busy 三元组）
  ///
  /// 返回 `Map<String, dynamic>?`：
  /// - 成功且用户设置了 status: 返回类似 `{emoji, message, indicatesLimitedAvailability}`
  /// - 用户未设置 status（GraphQL 返回 null）: 返回 `null` + result=true
  /// - 请求失败: 返回 `null` + result=false
  ///
  /// UI 侧对 empty / error 统一按 [SizedBox.shrink] 处理，无需区分两种失败语义。
  /// 组织账号无 status 字段，本方法不做 type 过滤，由上层 provider 视用户类型
  /// 决定是否发起请求（GitHub 对 organization 也可能 200 返回 `user: null`）。
  static getUserStatusRequest(String userName) async {
    var result = await getUserStatus(userName);
    if (result == null || result.data == null) {
      return DataResult(null, false);
    }
    var user = result.data!["user"];
    if (user == null) {
      return DataResult(null, true);
    }
    var status = user["status"];
    if (status == null) {
      return DataResult(null, true);
    }
    return DataResult(Map<String, dynamic>.from(status as Map), true);
  }

  /// 获取指定用户 / 组织的前 5 位 sponsors + 总数
  ///
  /// 返回 `DataResult` 的 `data` 是一个 map：`{totalCount: int, nodes: List<Map>}`
  /// - 请求失败: `data=null` + result=false
  /// - 请求成功但 `user==null`（login 不存在 / 权限不足）：返回空态
  ///   `{totalCount:0, nodes:[]}` + result=true
  /// - 请求成功但用户未启用 Sponsors（GraphQL 侧表现为 `sponsors!=null`
  ///   且 `totalCount=0, nodes=[]`）：直接映射为同形状空态
  /// - 有 sponsors：`nodes` 里是过滤后的非空 Map（login/avatarUrl）
  ///
  /// UI 侧对 empty / error / totalCount=0 统一按 [SizedBox.shrink] 处理。
  /// GraphQL 层 `sponsors.nodes` 是 union of User | Organization，本方法只
  /// 剥掉 `... on X` 分支合并后的 map，不做类型识别；上层视图模型不区分。
  static getUserSponsorsRequest(String userName) async {
    var result = await getUserSponsors(userName);
    if (result == null || result.data == null) {
      return DataResult(null, false);
    }
    var user = result.data!["user"];
    if (user == null) {
      return DataResult(
          <String, dynamic>{"totalCount": 0, "nodes": <Map>[]}, true);
    }
    var sponsors = user["sponsors"];
    if (sponsors == null) {
      return DataResult(
          <String, dynamic>{"totalCount": 0, "nodes": <Map>[]}, true);
    }
    final int totalCount = (sponsors["totalCount"] as int?) ?? 0;
    final rawNodes = sponsors["nodes"];
    final List<Map<String, dynamic>> nodes = (rawNodes is List)
        ? rawNodes
            .whereType<Map>()
            .where((e) => e.isNotEmpty)
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];
    return DataResult(
        <String, dynamic>{"totalCount": totalCount, "nodes": nodes}, true);
  }

  /// 获取指定用户的贡献日历（近 12 个月）
  ///
  /// 返回 `DataResult` 的 `data` 是一个 map：
  /// `{totalContributions: int, weeks: List<Map>}`
  /// 其中 `weeks[i]` 形如 `{contributionDays: List<Map>}`，
  /// `contributionDays[j]` 形如 `{date: 'YYYY-MM-DD', contributionCount: int, color: '#hex'}`
  ///
  /// - 请求失败: `data=null` + result=false
  /// - 请求成功但 `user==null`（login 不存在 / Organization / 权限不足）：
  ///   返回空态 `{totalContributions:0, weeks:[]}` + result=true
  /// - 请求成功但 `contributionsCollection==null` / `contributionCalendar==null`：
  ///   同上空态处理
  ///
  /// UI 侧对 empty / error 统一按占位处理；结构透传给 provider 视图模型解析
  /// （避免 repository 层引入 domain model 类型，与 [getUserSponsorsRequest]
  /// 的做法保持一致：repo 层出 Map，provider 层出 view model）。
  static getUserContributionCalendarRequest(String userName) async {
    var result = await getUserContributionCalendar(userName);
    if (result == null || result.data == null) {
      return DataResult(null, false);
    }
    var user = result.data!["user"];
    if (user == null) {
      return DataResult(
          <String, dynamic>{"totalContributions": 0, "weeks": <Map>[]}, true);
    }
    var collection = user["contributionsCollection"];
    if (collection == null) {
      return DataResult(
          <String, dynamic>{"totalContributions": 0, "weeks": <Map>[]}, true);
    }
    var calendar = collection["contributionCalendar"];
    if (calendar == null) {
      return DataResult(
          <String, dynamic>{"totalContributions": 0, "weeks": <Map>[]}, true);
    }
    final int totalContributions =
        (calendar["totalContributions"] as int?) ?? 0;
    final rawWeeks = calendar["weeks"];
    final List<Map<String, dynamic>> weeks = (rawWeeks is List)
        ? rawWeeks
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];
    return DataResult(<String, dynamic>{
      "totalContributions": totalContributions,
      "weeks": weeks,
    }, true);
  }

  static searchTrendUserRequest(String location, {String? cursor}) async {
    var result = await getTrendUser(location, cursor: cursor);
    if (result != null && result.data != null) {
      var endCursor = result.data!["search"]["pageInfo"]["endCursor"];
      var dataList = result.data!["search"]["user"];
      if (dataList == null || dataList.length == 0) {
        return DataResult(null, false);
      }
      List<SearchUserQL> dataResult = [];
      dataList.forEach((item) {
        var userModel = SearchUserQL.fromMap(item["user"]);
        dataResult.add(userModel);
      });
      return DataResult((dataResult, endCursor), true);
    } else {
      return DataResult(null, false);
    }
  }
}
