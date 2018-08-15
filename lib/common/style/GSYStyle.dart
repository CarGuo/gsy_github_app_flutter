import 'package:flutter/material.dart';

///颜色
class GSYColors {
  static const String primaryValueString = "#24292E";
  static const String primaryLightValueString = "#42464b";
  static const String primaryDarkValueString = "#121917";
  static const String miWhiteString = "#ececec";
  static const String actionBlueString = "#267aff";
  static const String webDraculaBackgroundColorString = "#282a36";

  static const int primaryValue = 0xFF24292E;
  static const int primaryLightValue = 0xFF42464b;
  static const int primaryDarkValue = 0xFF121917;

  static const int cardWhite = 0xFFFFFFFF;
  static const int textWhite = 0xFFFFFFFF;
  static const int miWhite = 0xffececec;
  static const int white = 0xFFFFFFFF;
  static const int actionBlue = 0xff267aff;
  static const int subTextColor = 0xff959595;
  static const int subLightTextColor = 0xffc4c4c4;

  static const int mainBackgroundColor = miWhite;

  static const int mainTextColor = primaryDarkValue;
  static const int textColorWhite = white;

  static const MaterialColor primarySwatch = const MaterialColor(
    primaryValue,
    const <int, Color>{
      50: const Color(primaryLightValue),
      100: const Color(primaryLightValue),
      200: const Color(primaryLightValue),
      300: const Color(primaryLightValue),
      400: const Color(primaryLightValue),
      500: const Color(primaryValue),
      600: const Color(primaryDarkValue),
      700: const Color(primaryDarkValue),
      800: const Color(primaryDarkValue),
      900: const Color(primaryDarkValue),
    },
  );
}

///文本样式
class GSYConstant {

  static const String app_default_share_url = "https://github.com/CarGuo/GSYGithubAppFlutter";

  static const lagerTextSize = 30.0;
  static const bigTextSize = 23.0;
  static const normalTextSize = 18.0;
  static const middleTextWhiteSize = 16.0;
  static const smallTextSize = 14.0;
  static const minTextSize = 12.0;

  static const minText = TextStyle(
    color: Color(GSYColors.subTextColor),
    fontSize: minTextSize,
  );

  static const smallTextWhite = TextStyle(
    color: Color(GSYColors.textColorWhite),
    fontSize: smallTextSize,
  );

  static const smallText = TextStyle(
    color: Color(GSYColors.mainTextColor),
    fontSize: smallTextSize,
  );

  static const smallTextBold = TextStyle(
    color: Color(GSYColors.mainTextColor),
    fontSize: smallTextSize,
    fontWeight: FontWeight.bold,
  );

  static const smallSubLightText = TextStyle(
    color: Color(GSYColors.subLightTextColor),
    fontSize: smallTextSize,
  );

  static const smallActionLightText = TextStyle(
    color: Color(GSYColors.actionBlue),
    fontSize: smallTextSize,
  );

  static const smallMiLightText = TextStyle(
    color: Color(GSYColors.miWhite),
    fontSize: smallTextSize,
  );

  static const smallSubText = TextStyle(
    color: Color(GSYColors.subTextColor),
    fontSize: smallTextSize,
  );

  static const middleText = TextStyle(
    color: Color(GSYColors.mainTextColor),
    fontSize: middleTextWhiteSize,
  );

  static const middleTextWhite = TextStyle(
    color: Color(GSYColors.textColorWhite),
    fontSize: middleTextWhiteSize,
  );

  static const middleSubText = TextStyle(
    color: Color(GSYColors.subTextColor),
    fontSize: middleTextWhiteSize,
  );

  static const middleSubLightText = TextStyle(
    color: Color(GSYColors.subLightTextColor),
    fontSize: middleTextWhiteSize,
  );

  static const middleTextBold = TextStyle(
    color: Color(GSYColors.mainTextColor),
    fontSize: middleTextWhiteSize,
    fontWeight: FontWeight.bold,
  );

  static const middleTextWhiteBold = TextStyle(
    color: Color(GSYColors.textColorWhite),
    fontSize: middleTextWhiteSize,
    fontWeight: FontWeight.bold,
  );

  static const middleSubTextBold = TextStyle(
    color: Color(GSYColors.subTextColor),
    fontSize: middleTextWhiteSize,
    fontWeight: FontWeight.bold,
  );

  static const normalText = TextStyle(
    color: Color(GSYColors.mainTextColor),
    fontSize: normalTextSize,
  );

  static const normalTextBold = TextStyle(
    color: Color(GSYColors.mainTextColor),
    fontSize: normalTextSize,
    fontWeight: FontWeight.bold,
  );

  static const normalSubText = TextStyle(
    color: Color(GSYColors.subTextColor),
    fontSize: normalTextSize,
  );

  static const normalTextWhite = TextStyle(
    color: Color(GSYColors.textColorWhite),
    fontSize: normalTextSize,
  );

  static const normalTextMitWhiteBold = TextStyle(
    color: Color(GSYColors.miWhite),
    fontSize: normalTextSize,
    fontWeight: FontWeight.bold,
  );

  static const normalTextActionWhiteBold = TextStyle(
    color: Color(GSYColors.actionBlue),
    fontSize: normalTextSize,
    fontWeight: FontWeight.bold,
  );

  static const normalTextLight = TextStyle(
    color: Color(GSYColors.primaryLightValue),
    fontSize: normalTextSize,
  );

  static const largeText = TextStyle(
    color: Color(GSYColors.mainTextColor),
    fontSize: bigTextSize,
  );

  static const largeTextBold = TextStyle(
    color: Color(GSYColors.mainTextColor),
    fontSize: bigTextSize,
    fontWeight: FontWeight.bold,
  );

  static const largeTextWhite = TextStyle(
    color: Color(GSYColors.textColorWhite),
    fontSize: bigTextSize,
  );

  static const largeTextWhiteBold = TextStyle(
    color: Color(GSYColors.textColorWhite),
    fontSize: bigTextSize,
    fontWeight: FontWeight.bold,
  );

  static const largeLargeTextWhite = TextStyle(
    color: Color(GSYColors.textColorWhite),
    fontSize: lagerTextSize,
    fontWeight: FontWeight.bold,
  );

  static const largeLargeText = TextStyle(
    color: Color(GSYColors.primaryValue),
    fontSize: lagerTextSize,
    fontWeight: FontWeight.bold,
  );
}

///字符文本
class GSYStrings {
  static const String welcomeMessage = "Welcome To Flutter";

  static const String app_name = "GSYGithubAppFlutter";

  static const String app_ok = "确定";
  static const String app_cancel = "取消";
  static const String app_empty = "目前什么也没有哟";
  static const String app_licenses = "协议";
  static const String app_close = "关闭";
  static const String app_version = "版本";
  static const String app_back_tip = "确定要退出应用？";

  static const String app_not_new_version = "当前没有新版本";
  static const String app_version_title = "版本更新";

  static const String nothing_now = "目前什么都没有。";
  static const String loading_text = "努力加载中···";

  static const String option_web = "浏览器打开";
  static const String option_copy = "复制链接";
  static const String option_share = "分享";
  static const String option_web_launcher_error = "url异常";
  static const String option_share_title = "分享自GSYGitHubFlutter： ";
  static const String option_share_copy_success = "已经复制到粘贴板";

  static const String login_text = "登录";

  static const String Login_out = "退出登录";

  static const String home_reply = "问题反馈";
  static const String home_about = "关于";
  static const String home_check_update = "检测更新";
  static const String home_history = "阅读历史";
  static const String home_user_info = "个人信息";
  static const String home_change_theme = "切换主题";

  static const String home_theme_default = "默认主题";
  static const String home_theme_1 = "主题1";
  static const String home_theme_2 = "主题2";
  static const String home_theme_3 = "主题3";
  static const String home_theme_4 = "主题4";
  static const String home_theme_5 = "主题5";
  static const String home_theme_6 = "主题6";

  static const String login_username_hint_text = "请输入github用户名";
  static const String login_password_hint_text = "请输入密码";
  static const String login_success = "登录成功";

  static const String network_error_401 = "[401错误可能: 未授权 \\ 授权登录失败 \\ 登录过期]";
  static const String network_error_403 = "403权限错误";
  static const String network_error_404 = "404错误";
  static const String network_error_timeout = "请求超时";
  static const String network_error_unknown = "其他异常";
  static const String network_error = "网络错误";

  static const String load_more_not = "没有更多数据";
  static const String load_more_text = "正在加载更多";

  static const String home_dynamic = "动态";
  static const String home_trend = "趋势";
  static const String home_my = "我的";

  static const String trend_day = '今日';
  static const String trend_week = '本周';
  static const String trend_month = '本月';
  static const String trend_all = '全部';

  static const String user_tab_repos = "仓库";
  static const String user_tab_fans = "粉丝";
  static const String user_tab_focus = "关注";
  static const String user_tab_star = "星标";
  static const String user_tab_honor = "荣耀";
  static const String user_dynamic_group = "组织成员";
  static const String user_dynamic_title = "个人动态";
  static const String user_focus = "已关注";
  static const String user_un_focus = "关注";
  static const String user_focus_no_support = "不支持关注组织。";
  static const String user_create_at = "创建于：";
  static const String user_orgs_title = "所在组织";

  static const String repos_tab_readme = "详情";
  static const String repos_tab_info = "动态";
  static const String repos_tab_file = "文件";
  static const String repos_tab_issue = "ISSUE";
  static const String repos_tab_activity = "动态";
  static const String repos_tab_commits = "提交";
  static const String repos_tab_issue_all = "所有";
  static const String repos_tab_issue_open = "打开";
  static const String repos_tab_issue_closed = "关闭";
  static const String repos_option_release = "版本";
  static const String repos_fork_at = "Fork于 ";
  static const String repos_create_at = "创建于 ";
  static const String repos_last_commit = "最后提交于 ";
  static const String repos_all_issue_count = "所有Issue数：";
  static const String repos_open_issue_count = "开启Issue数：";
  static const String repos_close_issue_count = "关闭Issue数：";

  static const String repos_issue_search = "搜索";

  static const String issue_reply = "回复";
  static const String issue_edit = "编辑";
  static const String issue_open = "打开";
  static const String issue_close = "关闭";
  static const String issue_lock = "锁定";
  static const String issue_unlock = "解锁";
  static const String issue_reply_issue = "回复Issue";
  static const String issue_commit_issue = "提交Issue";
  static const String issue_edit_issue = "编译Issue";
  static const String issue_edit_issue_commit = "编译回复";
  static const String issue_edit_issue_edit_commit = "编辑";
  static const String issue_edit_issue_delete_commit = "删除";
  static const String issue_edit_issue_copy_commit = "复制";
  static const String issue_edit_issue_content_not_be_null = "内容不能为空";
  static const String issue_edit_issue_title_not_be_null = "标题不能为空";
  static const String issue_edit_issue_title_tip = "请输入标题";
  static const String issue_edit_issue_content_tip = "请输入内容";

  static const String notify_title = "通知";
  static const String notify_tab_all = "所有";
  static const String notify_tab_part = "参与";
  static const String notify_tab_unread = "未读";
  static const String notify_unread = "未读";
  static const String notify_readed = "已读";
  static const String notify_status = "状态";
  static const String notify_type = "类型";

  static const String search_title = "搜索";
  static const String search_tab_repos = "仓库";
  static const String search_tab_user = "用户";

  static const String release_tab_release = "版本";
  static const String release_tab_tag = "标记";

  static const String user_profile_name = "名字";
  static const String user_profile_email = "邮箱";
  static const String user_profile_link = "链接";
  static const String user_profile_org = "公司";
  static const String user_profile_location = "位置";
  static const String user_profile_info = "简介";
}

class GSYICons {
  static const String FONT_FAMILY = 'wxcIconFont';

  static const String DEFAULT_USER_ICON = 'static/images/logo.png';
  static const String DEFAULT_IMAGE = 'static/images/default_img.png';
  static const String DEFAULT_REMOTE_PIC = 'https://raw.githubusercontent.com/CarGuo/GSYGithubAppFlutter/master/static/images/logo.png';

  static const IconData HOME = const IconData(0xe624, fontFamily: GSYICons.FONT_FAMILY);
  static const IconData MORE = const IconData(0xe674, fontFamily: GSYICons.FONT_FAMILY);
  static const IconData SEARCH = const IconData(0xe61c, fontFamily: GSYICons.FONT_FAMILY);

  static const IconData MAIN_DT = const IconData(0xe684, fontFamily: GSYICons.FONT_FAMILY);
  static const IconData MAIN_QS = const IconData(0xe818, fontFamily: GSYICons.FONT_FAMILY);
  static const IconData MAIN_MY = const IconData(0xe6d0, fontFamily: GSYICons.FONT_FAMILY);
  static const IconData MAIN_SEARCH = const IconData(0xe61c, fontFamily: GSYICons.FONT_FAMILY);

  static const IconData LOGIN_USER = const IconData(0xe666, fontFamily: GSYICons.FONT_FAMILY);
  static const IconData LOGIN_PW = const IconData(0xe60e, fontFamily: GSYICons.FONT_FAMILY);

  static const IconData REPOS_ITEM_USER = const IconData(0xe63e, fontFamily: GSYICons.FONT_FAMILY);
  static const IconData REPOS_ITEM_STAR = const IconData(0xe643, fontFamily: GSYICons.FONT_FAMILY);
  static const IconData REPOS_ITEM_FORK = const IconData(0xe67e, fontFamily: GSYICons.FONT_FAMILY);
  static const IconData REPOS_ITEM_ISSUE = const IconData(0xe661, fontFamily: GSYICons.FONT_FAMILY);

  static const IconData REPOS_ITEM_STARED = const IconData(0xe698, fontFamily: GSYICons.FONT_FAMILY);
  static const IconData REPOS_ITEM_WATCH = const IconData(0xe681, fontFamily: GSYICons.FONT_FAMILY);
  static const IconData REPOS_ITEM_WATCHED = const IconData(0xe629, fontFamily: GSYICons.FONT_FAMILY);
  static const IconData REPOS_ITEM_DIR = Icons.folder;
  static const IconData REPOS_ITEM_FILE = const IconData(0xea77, fontFamily: GSYICons.FONT_FAMILY);
  static const IconData REPOS_ITEM_NEXT = const IconData(0xe610, fontFamily: GSYICons.FONT_FAMILY);

  static const IconData USER_ITEM_COMPANY = const IconData(0xe63e, fontFamily: GSYICons.FONT_FAMILY);
  static const IconData USER_ITEM_LOCATION = const IconData(0xe7e6, fontFamily: GSYICons.FONT_FAMILY);
  static const IconData USER_ITEM_LINK = const IconData(0xe670, fontFamily: GSYICons.FONT_FAMILY);
  static const IconData USER_NOTIFY = const IconData(0xe600, fontFamily: GSYICons.FONT_FAMILY);

  static const IconData ISSUE_ITEM_ISSUE = const IconData(0xe661, fontFamily: GSYICons.FONT_FAMILY);
  static const IconData ISSUE_ITEM_COMMENT = const IconData(0xe6ba, fontFamily: GSYICons.FONT_FAMILY);
  static const IconData ISSUE_ITEM_ADD = const IconData(0xe662, fontFamily: GSYICons.FONT_FAMILY);

  static const IconData ISSUE_EDIT_H1 = Icons.filter_1;
  static const IconData ISSUE_EDIT_H2 = Icons.filter_2;
  static const IconData ISSUE_EDIT_H3 = Icons.filter_3;
  static const IconData ISSUE_EDIT_BOLD = Icons.format_bold;
  static const IconData ISSUE_EDIT_ITALIC = Icons.format_italic;
  static const IconData ISSUE_EDIT_QUOTE = Icons.format_quote;
  static const IconData ISSUE_EDIT_CODE = Icons.format_shapes;
  static const IconData ISSUE_EDIT_LINK = Icons.insert_link;

  static const IconData NOTIFY_ALL_READ = const IconData(0xe62f, fontFamily: GSYICons.FONT_FAMILY);

  static const IconData PUSH_ITEM_EDIT = Icons.mode_edit;
  static const IconData PUSH_ITEM_ADD = Icons.add_box;
  static const IconData PUSH_ITEM_MIN = Icons.indeterminate_check_box;
}
