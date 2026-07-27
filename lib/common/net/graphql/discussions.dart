// GitHub Discussions GraphQL 查询模板。
//
// 这个文件承接的是 roadmap §3.1 的第一项："Discussions 阅读页"的骨架阶段。
// 命名与 [repositories.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/net/graphql/repositories.dart)
// 保持一致：raw string + 顶层 const。
//
// 官方 schema 参考：https://docs.github.com/en/graphql/reference/objects#discussion
//
// reactionGroups 的语义（本文件多处复用）：
//   - GraphQL `Reactable` interface 的标准字段（Discussion / DiscussionComment /
//     Issue / PullRequest / Comment / Release 都实现了它，未来复用无成本）
//   - `content` 是 `ReactionContent` 枚举：THUMBS_UP / THUMBS_DOWN / LAUGH /
//     HOORAY / CONFUSED / HEART / ROCKET / EYES（**共 8 类**）
//   - `viewerHasReacted` 是当前登录用户是否已经点过这类 reaction，用于本地
//     UI 高亮 chip + 决定"再点一次是 add 还是 remove"
//   - `reactors.totalCount` 是该类 reaction 的总人数；无人 reaction 时 GitHub
//     仍会返回该 group 但 totalCount=0，本地渲染时可以过滤掉 count=0 的分组

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
      reactionGroups {
        content
        viewerHasReacted
        reactors {
          totalCount
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
          reactionGroups {
            content
            viewerHasReacted
            reactors {
              totalCount
            }
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
              reactionGroups {
                content
                viewerHasReacted
                reactors {
                  totalCount
                }
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

/// Discussion 评论分页查询（loadMore 专用）。
///
/// - 只回读 `repository.discussion.comments` 段，避免每次翻页都重复拉 header/body
/// - 与 [readDiscussion] 里 `comments(first:30)` 结构 **完全对齐**（node 字段一致，
///   仍带 replies(first:10)），前端可以直接把新一批 nodes 追加到已渲染列表尾部
/// - `after` 走 GraphQL 的 endCursor，`first` 默认 30 与首屏一致
const String readDiscussionCommentsPage = r'''
query getDiscussionCommentsPage($owner: String!, $name: String!, $number: Int!, $first: Int!, $after: String) {
  repository(owner: $owner, name: $name) {
    discussion(number: $number) {
      comments(first: $first, after: $after) {
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
          reactionGroups {
            content
            viewerHasReacted
            reactors {
              totalCount
            }
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
              reactionGroups {
                content
                viewerHasReacted
                reactors {
                  totalCount
                }
              }
            }
          }
        }
      }
    }
  }
}
''';

/// 给一个 Reactable（Discussion / DiscussionComment / Issue / PR / Comment /
/// Release 等）加一类 reaction。
///
/// - 与 [mutationRemoveReaction] 配对使用；写操作严格对齐
///   [AGENTS.md 允许清单](file:///d:/workspace/project/gsy_github_app_flutter/AGENTS.md)
///   里"Issue / Comment 上加/取消 reaction"。Discussion 属于同族 Reactable，
///   落在允许范围内
/// - `subjectId` 是 GraphQL node id（形如 `D_kw...` / `DC_kw...`），不是
///   REST numeric id；由上层从 [readDiscussion] / [readDiscussionCommentsPage]
///   返回结构中直接透传
/// - `content` 是 `ReactionContent` 枚举字面量（未加引号，形如 `THUMBS_UP`），
///   由 Dart 侧调用方保证映射正确；服务端会对非法值直接 400
/// - 返回体只回 reactable.id 与更新后的 reactionGroups，前端拿到后可直接替换
///   本地缓存中该 subject 的 reactionGroups
const String mutationAddReaction = r'''
mutation addReactionToSubject($subjectId: ID!, $content: ReactionContent!) {
  addReaction(input: {subjectId: $subjectId, content: $content}) {
    subject {
      id
      reactionGroups {
        content
        viewerHasReacted
        reactors {
          totalCount
        }
      }
    }
  }
}
''';

/// 取消 [mutationAddReaction] 加过的一类 reaction。
///
/// 返回结构与 [mutationAddReaction] 完全对齐，方便上层用同一段代码处理
/// mutation 后的本地状态更新（拿最新 `reactionGroups` 覆盖本地）。
const String mutationRemoveReaction = r'''
mutation removeReactionFromSubject($subjectId: ID!, $content: ReactionContent!) {
  removeReaction(input: {subjectId: $subjectId, content: $content}) {
    subject {
      id
      reactionGroups {
        content
        viewerHasReacted
        reactors {
          totalCount
        }
      }
    }
  }
}
''';
