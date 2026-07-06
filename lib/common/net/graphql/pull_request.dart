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
