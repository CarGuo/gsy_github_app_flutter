// GitHub Pull Request GraphQL 查询模板。
//
// 这个文件承接的是 roadmap §4.1 里 2026-07-06 转正的
// "PR review thread mark as resolved / unresolved" 允许项：仅读取当前 PR 下
// review thread 的最小字段（id、isResolved、以及每条 thread 内 comment 的
// databaseId），供上层做 resolve / unresolve 操作时定位 thread 使用。
// 计数仪表盘、批量解决、以及未来可能的 mutation 都不在本轮范围。
//
// 命名与 [discussions.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/net/graphql/discussions.dart)
// 保持一致：raw string + 顶层 const。
//
// 官方 schema 参考：https://docs.github.com/en/graphql/reference/objects#pullrequestreviewthread

const String readPullRequestReviewThreads = r'''
query getPullRequestReviewThreads($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    nameWithOwner
    pullRequest(number: $number) {
      id
      number
      reviewThreads(first: 50) {
        nodes {
          id
          isResolved
          comments(first: 100) {
            nodes {
              databaseId
            }
          }
        }
      }
    }
  }
}
''';

/// 把一条 review thread 标记为 resolved（GitHub GraphQL mutation）
///
/// - 输入 `threadId` = [PullRequestReviewThread.id]（形如 `PRRT_kw...`），
///   不是 REST 的 numeric id
/// - 返回体只取回 `thread.id` + `thread.isResolved`，供 UI 侧就地 patch
///   [_resolvedMap] 而无需重新拉全量 threads
/// - 权限要求：token 需要 `repo` scope（GSY 现有登录已具备）
const String mutationResolveReviewThread = r'''
mutation resolveReviewThread($threadId: ID!) {
  resolveReviewThread(input: {threadId: $threadId}) {
    thread {
      id
      isResolved
    }
  }
}
''';

/// 把一条已 resolved 的 review thread 撤回到 unresolved
///
/// 参数与返回结构与 [mutationResolveReviewThread] 完全对称。
const String mutationUnresolveReviewThread = r'''
mutation unresolveReviewThread($threadId: ID!) {
  unresolveReviewThread(input: {threadId: $threadId}) {
    thread {
      id
      isResolved
    }
  }
}
''';
