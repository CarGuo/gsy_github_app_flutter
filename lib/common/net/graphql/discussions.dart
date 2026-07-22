// GitHub Discussions GraphQL 查询模板。
//
// 这个文件承接的是 roadmap §3.1 的第一项："Discussions 阅读页"的骨架阶段。
// 命名与 [repositories.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/net/graphql/repositories.dart)
// 保持一致：raw string + 顶层 const。
//
// 官方 schema 参考：https://docs.github.com/en/graphql/reference/objects#discussion

const String readDiscussion = r'''
query getDiscussionDetail($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    nameWithOwner
    discussion(number: $number) {
      id
      number
      title
      bodyHTML
      url
      createdAt
      updatedAt
      locked
      answerChosenAt
      upvoteCount
      author {
        login
        avatarUrl
        url
      }
      category {
        id
        name
        emoji
        description
      }
      answer {
        id
        bodyHTML
        author {
          login
          avatarUrl
        }
        createdAt
      }
      labels(first: 10) {
        nodes {
          name
          color
        }
      }
      comments(first: 30) {
        totalCount
        pageInfo {
          hasNextPage
          endCursor
        }
        nodes {
          id
          bodyHTML
          createdAt
          isAnswer
          upvoteCount
          author {
            login
            avatarUrl
          }
          replies(first: 10) {
            totalCount
            nodes {
              id
              bodyHTML
              createdAt
              author {
                login
                avatarUrl
              }
            }
          }
        }
      }
    }
  }
}
''';

/// 仓库下的 Discussions 列表分页查询。
///
/// - orderBy: 用 UPDATED_AT + DESC，与 GitHub Web `/discussions` 默认视图一致，
///   保证列表首条与用户在网页上看到的顺序对齐
/// - 列表 item 只取"卡片视觉"所需的最小字段：不拉 bodyHTML（列表页不展开正文）
/// - answered/upvote/commentCount 都放到 item 层，避免 UI 侧再多发一次请求
/// - $after 为 null 时拉第一页；有值时拉下一页，配合 pageInfo.endCursor 实现分页
/// - `comments(first: 1)`：只用它的 `totalCount`，first 传 1 而不是 0；GitHub GraphQL
///   对 connection 的 `first` 一般要求 `>= 1`，取 0 属"未文档化行为"，为规避某次
///   服务端收紧后整个列表 400 的风险，这里 fallback 到 1。多返回的 1 条 node 会被
///   直接丢弃（我们不选任何 comment 字段），payload 增量可忽略。
const String readDiscussionList = r'''
query getRepositoryDiscussions($owner: String!, $name: String!, $first: Int!, $after: String) {
  repository(owner: $owner, name: $name) {
    nameWithOwner
    hasDiscussionsEnabled
    discussions(first: $first, after: $after, orderBy: {field: UPDATED_AT, direction: DESC}) {
      totalCount
      pageInfo {
        hasNextPage
        endCursor
      }
      nodes {
        id
        number
        title
        url
        createdAt
        updatedAt
        locked
        upvoteCount
        answerChosenAt
        author {
          login
          avatarUrl
          url
        }
        category {
          id
          name
          emoji
        }
        comments(first: 1) {
          totalCount
        }
      }
    }
  }
}
''';
