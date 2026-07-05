import 'package:gsy_github_app_flutter/common/config/config.dart';
import 'package:gsy_github_app_flutter/common/config/ignoreConfig.dart';

///地址数据
class Address {
  static const String host = "https://api.github.com/";
  static const String hostWeb = "https://github.com/";
  static const String graphicHost = 'https://ghchart.rshah.org/';
  static const String updateUrl = 'https://github.com/CarGuo/gsy_github_app_flutter/releases';

  ///获取授权  post
  static getAuthorization() {
    return "${host}authorizations";
  }

  ///搜索 get
  ///
  /// GitHub search q 参数**不是标准 URL query 语义**，而是 GitHub 自家的
  /// mini-DSL：`+` 表示 boolean AND，`:` 用于修饰符（`user:xxx` / `language:xxx`）。
  /// 因此不能用 [Uri.encodeQueryComponent]（会把 `+` → `%2B` 让 GitHub 解成
  /// 字面加号导致 total=0）。
  ///
  /// [_encodeGitHubQuery] 走 [Uri.encodeFull] 保留 `+` / `:` / `/` / `-` 等
  /// GitHub 语法字符字面，然后单独把 `#` 手工替换成 `%23` —— 因为 encodeFull
  /// 不 encode `#`（当 URL fragment 分隔符），但 GitHub language:C# 里的 `#`
  /// 必须字面上传。
  ///
  /// 调用方直接传原文（`flutter+user:CarGuo`、`language:C#`），
  /// 由本方法统一编码。
  static search(q, sort, order, type, page, [pageSize = Config.PAGE_SIZE]) {
    final String qEnc = _encodeGitHubQuery(q?.toString() ?? '');
    if (type == 'user') {
      return "${host}search/users?q=$qEnc&page=$page&per_page=$pageSize";
    }
    if (type == 'issue') {
      // GitHub 的 issue 搜索也会包含 PR。sort 支持 comments/reactions/created/updated；
      // 传入的 sort 目前和 repo 复用（stars/forks），对 issue 无意义，
      // 让 GitHub 走默认 best match，稳字为先。
      return "${host}search/issues?q=$qEnc&order=${order ?? 'desc'}&page=$page&per_page=$pageSize";
    }
    if (type == 'code') {
      // GitHub 的 /search/code 强制要 token 且只支持 relevance 排序,
      // 没有 sort/order 参数。要求 token 有 repo scope,
      // 未认证或权限不够时会 403,让上层 UI 感知空结果。
      return "${host}search/code?q=$qEnc&page=$page&per_page=$pageSize";
    }
    // sort 走 `best match` 原文，encodeFull 会把空格转 `%20`，
    // 避免直接写死 `best%20match` 这种半成品。
    sort ??= "best match";
    order ??= "desc";
    page ??= 1;
    pageSize ??= Config.PAGE_SIZE;
    final String sortEnc = Uri.encodeFull(sort.toString());
    return "${host}search/repositories?q=$qEnc&sort=$sortEnc&order=$order&page=$page&per_page=$pageSize";
  }

  ///搜索topic tag
  static searchTopic(topic) {
    // 与 [search] 走同一路径：[_encodeGitHubQuery] 保留 `:` 字面。
    final String qEnc = _encodeGitHubQuery("topic:$topic");
    return "${host}search/repositories?q=$qEnc&sort=stars&order=desc";
  }

  /// GitHub search q 参数的专用编码器。
  ///
  /// - `+` / `:` / `/` / `-` 是 GitHub 语法字符，encodeFull 天然保留字面
  /// - 空格、中文由 encodeFull 转成 `%20` / `%E4%B8%AD`
  /// - `#` encodeFull 不管（它是 URL fragment 分隔符），但 GitHub
  ///   `language:C#` 里的 `#` 必须字面上传，这里手工替换成 `%23`
  static String _encodeGitHubQuery(String raw) {
    return Uri.encodeFull(raw).replaceAll('#', '%23');
  }

  ///用户的仓库 get
  static userRepos(userName, sort) {
    sort ??= 'pushed';
    return "${host}users/$userName/repos?sort=$sort";
  }

  ///仓库详情 get
  static getReposDetail(reposOwner, reposName) {
    return "${host}repos/$reposOwner/$reposName";
  }

  ///仓库活动 get
  static getReposEvent(reposOwner, reposName) {
    return "${host}networks/$reposOwner/$reposName/events";
  }

  ///仓库Fork get
  static getReposForks(reposOwner, reposName) {
    return "${host}repos/$reposOwner/$reposName/forks";
  }

  ///仓库Star get
  static getReposStar(reposOwner, reposName) {
    return "${host}repos/$reposOwner/$reposName/stargazers";
  }

  ///仓库Watch get
  static getReposWatcher(reposOwner, reposName) {
    return "${host}repos/$reposOwner/$reposName/subscribers";
  }

  ///仓库提交 get
  static getReposCommits(reposOwner, reposName) {
    return "${host}repos/$reposOwner/$reposName/commits";
  }

  ///仓库提交详情 get
  static getReposCommitsInfo(reposOwner, reposName, sha) {
    return "${host}repos/$reposOwner/$reposName/commits/$sha";
  }

  ///仓库提交比较 get
  static getReposCompare(reposOwner, reposName, base, head) {
    return "${host}repos/$reposOwner/$reposName/compare/$base...$head";
  }

  ///仓库Issue get
  ///
  /// [labels] 为逗号拼接的 label 名字符串，例如 "bug,help wanted"，GitHub REST
  /// 会做 AND 匹配（同时具备这些 label 的 issue）。传空串等价于不加 label 过滤。
  static getReposIssue(String reposOwner, String reposName, state, sort, direction,
      [String? labels]) {
    state ??= 'all';
    sort ??= 'created';
    direction ??= 'desc';
    final base =
        "${host}repos/$reposOwner/$reposName/issues?state=$state&sort=$sort&direction=$direction";
    if (labels == null || labels.isEmpty) {
      return base;
    }
    return "$base&labels=${Uri.encodeQueryComponent(labels)}";
  }

  ///仓库labels get
  static getReposLabels(reposOwner, reposName) {
    return "${host}repos/$reposOwner/$reposName/labels";
  }

  ///PR 详情 get
  ///
  /// GitHub REST：GET /repos/:o/:r/pulls/:number 会返回 issue payload 里没有的
  /// merged/mergeable/draft/base/head/additions/deletions/... 字段。
  static getRepoPull(String reposOwner, String reposName, int number) {
    return "${host}repos/$reposOwner/$reposName/pulls/$number";
  }

  ///PR 变更文件列表 get
  ///
  /// GitHub REST：GET /repos/:o/:r/pulls/:number/files
  /// 返回每个文件的 filename/status/additions/deletions/changes/patch/blob_url。
  /// payload 与 CommitFile schema 完全一致，可直接复用 [CommitFile] model。
  /// 默认分页 30，最大 100；大 PR 通过分页拉取。
  static getRepoPullFiles(String reposOwner, String reposName, int number) {
    return "${host}repos/$reposOwner/$reposName/pulls/$number/files";
  }

  ///PR 行级评审评论列表 get
  ///
  /// GitHub REST：GET /repos/:o/:r/pulls/:number/comments
  /// 返回每条 review comment：path/position/line/original_line/body/user/html_url。
  /// position 是 hunk 内行索引（从 hunk header 后开始数）。
  /// 与 issue comments（/issues/:n/comments）不同，那个是整条 PR 的对话，
  /// 这个是行级评审评论。
  static getRepoPullReviewComments(
      String reposOwner, String reposName, int number) {
    return "${host}repos/$reposOwner/$reposName/pulls/$number/comments";
  }

  ///仓release get
  static getReposRelease(reposOwner, reposName) {
    return "${host}repos/$reposOwner/$reposName/releases";
  }

  ///仓Tag get
  static getReposTag(reposOwner, reposName) {
    return "${host}repos/$reposOwner/$reposName/tags";
  }

  ///仓Contributors get
  static getReposContributors(reposOwner, reposName) {
    return "${host}repos/$reposOwner/$reposName/contributors";
  }

  ///仓库Issue评论 get
  static getIssueComment(reposOwner, reposName, issueNumber) {
    return "${host}repos/$reposOwner/$reposName/issues/$issueNumber/comments";
  }

  ///仓库Issue get
  static getIssueInfo(reposOwner, reposName, issueNumber) {
    return "${host}repos/$reposOwner/$reposName/issues/$issueNumber";
  }

  ///增加issue评论 post

  static addIssueComment(reposOwner, reposName, issueNumber) {
    return "${host}repos/$reposOwner/$reposName/issues/$issueNumber/comments";
  }

  ///编辑issue put
  static editIssue(reposOwner, reposName, issueNumber) {
    return "${host}repos/$reposOwner/$reposName/issues/$issueNumber";
  }

  ///锁定issue put
  static lockIssue(reposOwner, reposName, issueNumber) {
    return "${host}repos/$reposOwner/$reposName/issues/$issueNumber/lock";
  }

  ///创建issue post
  static createIssue(reposOwner, reposName) {
    return "${host}repos/$reposOwner/$reposName/issues";
  }

  ///搜索issue
  ///
  /// 与 [search] 同一策略：q 走 [_encodeGitHubQuery]，保留 GitHub 语法字符
  /// （`+` AND / `:` 修饰符 / `/` 仓库名分隔）字面语义。调用方传原文。
  static repositoryIssueSearch(q) {
    final String qEnc = _encodeGitHubQuery(q?.toString() ?? '');
    return "${host}search/issues?q=$qEnc";
  }

  ///仓库Issue timeline get
  static getIssueTimeline(reposOwner, reposName, issueNumber) {
    return "${host}repos/$reposOwner/$reposName/issues/$issueNumber/timeline";
  }

  ///issue reactions get/post
  static getIssueReactions(reposOwner, reposName, issueNumber) {
    return "${host}repos/$reposOwner/$reposName/issues/$issueNumber/reactions";
  }

  ///删除 issue reaction delete
  static deleteIssueReaction(reposOwner, reposName, issueNumber, reactionId) {
    return "${host}repos/$reposOwner/$reposName/issues/$issueNumber/reactions/$reactionId";
  }

  ///issue comment reactions get/post
  static getIssueCommentReactions(reposOwner, reposName, commentId) {
    return "${host}repos/$reposOwner/$reposName/issues/comments/$commentId/reactions";
  }

  ///删除 issue comment reaction delete
  static deleteIssueCommentReaction(
      reposOwner, reposName, commentId, reactionId) {
    return "${host}repos/$reposOwner/$reposName/issues/comments/$commentId/reactions/$reactionId";
  }


  ///编辑评论 patch, delete
  static editComment(reposOwner, reposName, commentId) {
    return "${host}repos/$reposOwner/$reposName/issues/comments/$commentId";
  }

  ///自己的star get
  static myStar(sort) {
    sort ??= 'updated';

    return "${host}users/starred?sort=$sort";
  }

  ///用户的star get
  static userStar(userName, sort) {
    sort ??= 'updated';

    return "${host}users/$userName/starred?sort=$sort";
  }

  ///关注仓库 put
  static resolveStarRepos(reposOwner, repos) {
    return "${host}user/starred/$reposOwner/$repos";
  }

  ///订阅仓库 put
  static resolveWatcherRepos(reposOwner, repos) {
    return "${host}user/subscriptions/$reposOwner/$repos";
  }

  ///仓库内容数据 get
  static reposData(reposOwner, repos) {
    return "${host}repos/$reposOwner/$repos/contents";
  }

  ///仓库路径下的内容 get
  static reposDataDir(reposOwner, repos, path, [branch = 'master']) {
    return "${host}repos/$reposOwner/$repos/contents/$path${(branch == null || branch == "") ? "" : ("?ref=$branch")}";
  }

  ///README 文件地址 get
  static readmeFile(reposNameFullName, curBranch) {
    // ignore: prefer_interpolation_to_compose_strings
    return "${"${host}repos/" +
        reposNameFullName}/readme${(curBranch == null || curBranch == "" ) ? "" : ("?ref=$curBranch")}";

  }

  ///我的用户信息 GET
  static getMyUserInfo() {
    return "${host}user";
  }

  ///用户信息 get
  static getUserInfo(userName) {
    return "${host}users/$userName";
  }

  /// get 是否关注
  static doFollow(name) {
    return "${host}user/following/$name";
  }

  ///用户关注 get
  static getUserFollow(userName) {
    return "${host}users/$userName/following";
  }

  ///我的关注者 get
  static getMyFollower() {
    return "${host}user/followers";
  }

  ///用户的关注者 get
  static getUserFollower(userName) {
    return "${host}users/$userName/followers";
  }

  ///create fork post
  static createFork(reposOwner, reposName) {
    return "${host}repos/$reposOwner/$reposName/forks";
  }

  ///branch get
  static getbranches(reposOwner, reposName) {
    return "${host}repos/$reposOwner/$reposName/branches";
  }

  ///fork get
  static getForker(reposOwner, reposName, sort) {
    sort ??= 'newest';
    return "${host}repos/$reposOwner/$reposName/forks?sort=$sort";
  }

  ///readme get
  static getReadme(reposOwner, reposName) {
    return "${host}repos/$reposOwner/$reposName/readme";
  }

  ///用户收到的事件信息 get
  static getEventReceived(userName) {
    return "${host}users/$userName/received_events";
  }

  ///用户相关的事件信息 get
  static getEvent(userName) {
    return "${host}users/$userName/events";
  }

  ///组织成员
  static getMember(orgs) {
    return "${host}orgs/$orgs/members";
  }

  ///获取用户组织
  static getUserOrgs(userName) {
    return "${host}users/$userName/orgs";
  }

  ///通知 get
  static getNotifation(all, participating) {
    if ((all == null && participating == null) ||
        (all == false && participating == false)) {
      return "${host}notifications";
    }
    all ??= false;
    participating ??= false;
    return "${host}notifications?all=$all&participating=$participating";
  }

  ///patch
  static setNotificationAsRead(threadId) {
    return "${host}notifications/threads/$threadId";
  }

  ///delete 同一个 URL：GitHub 的"归档/mark-as-done"就是 DELETE thread
  static archiveNotificationThread(threadId) {
    return "${host}notifications/threads/$threadId";
  }

  ///get / put / delete 都用这个 URL，做 thread 订阅管理
  static notificationThreadSubscription(threadId) {
    return "${host}notifications/threads/$threadId/subscription";
  }

  ///put
  static setAllNotificationAsRead() {
    return "${host}notifications";
  }

  static getOAuthUrl() {
    return "https://github.com/login/oauth/authorize?client_id"
        "=${NetConfig.CLIENT_ID}&state=app&"
        "scope=user,repo,gist,notifications,read:org,workflow&"
        "redirect_uri=gsygithubapp://authed";
  }

  ///趋势 get
  static trending(since, languageType) {
    if (languageType != null) {
      return "https://github.com/trending/$languageType?since=$since";
    }
    return "https://github.com/trending?since=$since";
  }

  ///趋势 get
  static trendingApi(since, languageType) {
    if (languageType != null) {
      return "https://guoshuyu.cn/github/trend/list?languageType=$languageType&since=$since";
    }
    return "https://guoshuyu.cn/github/trend/list?since=$since";
  }

  ///处理分页参数
  static getPageParams(tab, page, [pageSize = Config.PAGE_SIZE]) {
    if (page != null) {
      if (pageSize != null) {
        return "${tab}page=$page&per_page=$pageSize";
      } else {
        return "${tab}page=$page";
      }
    } else {
      return "";
    }
  }
}
