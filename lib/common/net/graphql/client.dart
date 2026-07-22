import 'package:graphql/client.dart';
import 'package:gsy_github_app_flutter/common/net/graphql/discussions.dart';
import 'package:gsy_github_app_flutter/common/net/graphql/pull_request.dart';
import 'package:gsy_github_app_flutter/common/net/graphql/repositories.dart';
import 'package:gsy_github_app_flutter/common/net/graphql/users.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';

Future<GraphQLClient> _client(token) async {
  final HttpLink httpLink = HttpLink(
    'https://api.github.com/graphql',
  );

  final AuthLink authLink = AuthLink(
    getToken: () => '$token',
  );

  final Link link = authLink.concat(httpLink);
  var path = await CommonUtils.getApplicationDocumentsPath();
  final store = await HiveStore.open(path: path);
  return GraphQLClient(
    cache: GraphQLCache(store: store),
    link: link,
  );
}

GraphQLClient? _innerClient;

initClient(token) async {
  _innerClient ??= await _client(token);
}

releaseClient() {
  _innerClient = null;
}

Future<QueryResult>? getRepository(String owner, String? name) async {
  final QueryOptions options = QueryOptions(
      document: gql(readRepository),
      variables: <String, dynamic>{
        'owner': owner,
        'name': name,
      },
      fetchPolicy: FetchPolicy.noCache);
  return await _innerClient!.query(options);
}

/// 读取单个 GitHub Discussion 的全文 + 评论前 30 条。
///
/// 这是 roadmap §3.1 "Discussions 阅读页"骨架阶段的唯一网络入口。
/// 分页加载评论 / mutation（写评论、投票、标记回答）都不在本轮范围。
Future<QueryResult>? getDiscussion(
    String owner, String name, int number) async {
  final QueryOptions options = QueryOptions(
      document: gql(readDiscussion),
      variables: <String, dynamic>{
        'owner': owner,
        'name': name,
        'number': number,
      },
      fetchPolicy: FetchPolicy.noCache);
  return await _innerClient!.query(options);
}

/// 读取指定仓库的 Discussions 列表（按 UPDATED_AT DESC 排序）。
///
/// - roadmap §3.1 "内容渲染阶段 + 仓库详情 tab" 第一步，为新增的
///   [DiscussionListPage] 提供数据源
/// - `after` 为 null 时拉第一页，非空时拉下一页（配合 pageInfo.endCursor）
/// - `first` 默认 20：与既有 issue 列表 pageSize 保持一致，方便真机对照
/// - 走 [FetchPolicy.noCache]：Discussions 列表变化快（评论、upvote），不希望
///   用户下拉刷新还看到过期缓存
Future<QueryResult>? getRepositoryDiscussions(
    String owner, String name,
    {String? after, int first = 20}) async {
  final QueryOptions options = QueryOptions(
      document: gql(readDiscussionList),
      variables: <String, dynamic>{
        'owner': owner,
        'name': name,
        'first': first,
        'after': after,
      },
      fetchPolicy: FetchPolicy.noCache);
  return await _innerClient!.query(options);
}

/// 读取指定 PR 下的 review threads（首层 50 条，每条内 comment 首层 100 条）。
///
/// 只承载 roadmap §4.1 中"mark as resolved / unresolved"允许项定位 thread 所需的
/// 最小字段，不做未 resolved thread 计数、也不做 mutation。
Future<QueryResult>? getPullRequestReviewThreads(
    String owner, String name, int number) async {
  final QueryOptions options = QueryOptions(
      document: gql(readPullRequestReviewThreads),
      variables: <String, dynamic>{
        'owner': owner,
        'name': name,
        'number': number,
      },
      fetchPolicy: FetchPolicy.noCache);
  return await _innerClient!.query(options);
}

/// 将一条 review thread 标记为 resolved
///
/// - `threadId` 必须是 GraphQL node id（形如 `PRRT_kw...`），不是 REST numeric id
/// - GraphQL cache 走 noCache：不希望旧的 [readPullRequestReviewThreads]
///   查询结果被写脏；UI 侧成功后就地 patch 本地状态即可
Future<QueryResult>? resolveReviewThread(String threadId) async {
  final MutationOptions options = MutationOptions(
      document: gql(mutationResolveReviewThread),
      variables: <String, dynamic>{
        'threadId': threadId,
      },
      fetchPolicy: FetchPolicy.noCache);
  return await _innerClient!.mutate(options);
}

/// 将一条已 resolved 的 review thread 撤回到 unresolved
Future<QueryResult>? unresolveReviewThread(String threadId) async {
  final MutationOptions options = MutationOptions(
      document: gql(mutationUnresolveReviewThread),
      variables: <String, dynamic>{
        'threadId': threadId,
      },
      fetchPolicy: FetchPolicy.noCache);
  return await _innerClient!.mutate(options);
}

/// 读取指定用户 / 组织的 Pinned Repositories（最多 6 个，仅仓库类型）
///
/// - 用于 profile 页新增 pinned 卡片区域
/// - 走 [FetchPolicy.noCache]：与 [getRepository] 等其他查询保持一致，避免用户
///   在 GitHub 上更新 pinned 后本地长期缓存旧数据
Future<QueryResult>? getUserPinnedItems(String login) async {
  final QueryOptions options = QueryOptions(
      document: gql(readUserPinnedItems),
      variables: <String, dynamic>{
        'login': login,
      },
      fetchPolicy: FetchPolicy.noCache);
  return await _innerClient!.query(options);
}

/// 读取指定用户的 status（emoji / message / busy）
///
/// - 用于 profile 头部下方一行"状态 chip"
/// - 与 [getUserPinnedItems] 一致走 [FetchPolicy.noCache]：status 常变，且不希望
///   出现"上一次别的用户 profile 的 status 串到当前用户"
Future<QueryResult>? getUserStatus(String login) async {
  final QueryOptions options = QueryOptions(
      document: gql(readUserStatus),
      variables: <String, dynamic>{
        'login': login,
      },
      fetchPolicy: FetchPolicy.noCache);
  return await _innerClient!.query(options);
}

/// 读取指定用户 / 组织的前 5 位 sponsors + 总数
///
/// - 用于 profile 页 Pinned 下方"Sponsors"横向头像区
/// - 与 [getUserPinnedItems] / [getUserStatus] 一致走 [FetchPolicy.noCache]：
///   避免跨用户切换时 sponsor 列表相互串扰
Future<QueryResult>? getUserSponsors(String login) async {
  final QueryOptions options = QueryOptions(
      document: gql(readUserSponsors),
      variables: <String, dynamic>{
        'login': login,
      },
      fetchPolicy: FetchPolicy.noCache);
  return await _innerClient!.query(options);
}

/// 读取指定用户的 Contribution Calendar
///
/// - 用于替换第三方 ghchart.rshah.org 的静态 SVG：GraphQL 返回结构化
///   `weeks[].contributionDays[]`（date + count + color），前端可自绘
///   heatmap + 给 cell 挂点击回调（Tooltip 显示当日 contribution 数）
/// - 走 [FetchPolicy.noCache] 与 [getUserPinnedItems] / [getUserSponsors] 一致：
///   避免跨用户切换时上一份日历串到当前 profile
Future<QueryResult>? getUserContributionCalendar(String login) async {
  final QueryOptions options = QueryOptions(
      document: gql(readUserContributionCalendar),
      variables: <String, dynamic>{
        'login': login,
      },
      fetchPolicy: FetchPolicy.noCache);
  return await _innerClient!.query(options);
}

Future<QueryResult>? getTrendUser(String location, {String? cursor}) async {
  var variables = cursor == null
      ? <String, dynamic>{
          'location': "location:$location sort:followers",
        }
      : <String, dynamic>{
          'location': "location:$location sort:followers",
          'after': cursor,
        };
  final QueryOptions options = QueryOptions(
      document: gql(cursor == null ? readTrendUser : readTrendUserByCursor),
      variables: variables,
      fetchPolicy: FetchPolicy.noCache);
  return await _innerClient!.query(options);
}
