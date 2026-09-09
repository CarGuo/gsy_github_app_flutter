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
        __typename
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
          __typename
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
            __typename
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
                __typename
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
            __typename
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
                __typename
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

/// 查询指定仓库当前可用的 discussion category 列表。
///
/// - `createDiscussion` mutation 强制要求 `categoryId`，服务端不接受 `null`
///   （见 https://docs.github.com/en/graphql/reference/mutations#creatediscussion）
/// - GitHub Web 的 "New discussion" 页也是先让用户在几个 category 里选一个
///   （Announcements / General / Ideas / Q&A / ...），本查询就是给 UI 侧提供
///   这份选项数据
/// - 只取"卡片选择器"必要字段：id / name / emoji / description /
///   isAnswerable（Q&A 类目为 true，方便未来 UI 上给"提问"的 tab 打标）
/// - `first: 20`：GitHub 目前一个仓库的 discussion category 总数不多（默认
///   6-8 个），20 已经能一次拉全，无需分页
const String readRepoDiscussionCategories = r'''
query getRepoDiscussionCategories($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    id
    nameWithOwner
    hasDiscussionsEnabled
    discussionCategories(first: 20) {
      totalCount
      nodes {
        id
        name
        emoji
        description
        isAnswerable
      }
    }
  }
}
''';

/// 在指定仓库下新建一个 discussion。
///
/// - 严格对齐 GraphQL schema `CreateDiscussionInput`：`repositoryId`、
///   `categoryId`、`title`、`body` 四个字段全部必填（body 可为空字符串但字段
///   不能省，服务端会报 `Argument 'body' on InputObject 'CreateDiscussionInput'
///   is required`）
/// - 权限：token 需要 `repo` scope（或 fine-grained token 的
///   "Discussions: Read and write"）；对目标仓库要有 write 或 triage 权限
/// - 允许口径：见 [AGENTS.md](file:///d:/workspace/project/gsy_github_app_flutter/AGENTS.md#L193-L215)
///   §允许 / 禁止的写操作清单（2026-09-08 订正）——这条 mutation 对应"用户
///   对**有权限**的仓库发 discussion"这一 GSY 产品能力；**AI/开发者做冒烟测试
///   时不允许指向 `CarGuo/*` 主仓或第三方非授权仓库**，必须挑自己名下的测试仓库
/// - 返回体只回 discussion.id / number / url / title / createdAt，UI 侧收到后
///   可以直接把新 discussion 塞到列表头部乐观刷新，或者跳转到详情页
const String mutationCreateDiscussion = r'''
mutation createDiscussion($repositoryId: ID!, $categoryId: ID!, $title: String!, $body: String!) {
  createDiscussion(input: {repositoryId: $repositoryId, categoryId: $categoryId, title: $title, body: $body}) {
    discussion {
      id
      number
      url
      title
      createdAt
    }
  }
}
''';

/// 给一条 discussion 追加一级评论（回复主贴，不是 reply 二级）。
///
/// - 对应 GraphQL schema `AddDiscussionCommentInput`：`discussionId` + `body`
///   两字段必填；如需二级 reply，需要额外传 `replyToId`，本轮不做
/// - 权限：与 [mutationCreateDiscussion] 相同：token `repo` scope + 目标仓库
///   read 以上权限（评论 discussion 不需要 write）
/// - 允许口径：AGENTS.md §允许 / 禁止的写操作清单里"Issue / PR / Discussion
///   下发评论"这条早已允许（不是本轮新加）
/// - 返回体带最新的 comment id/body/createdAt，UI 侧成功后可就地插入到
///   `_commentsPage.nodes` 尾部或触发 `_load()` 重拉
const String mutationAddDiscussionComment = r'''
mutation addDiscussionComment($discussionId: ID!, $body: String!) {
  addDiscussionComment(input: {discussionId: $discussionId, body: $body}) {
    comment {
      id
      bodyHTML
      createdAt
      author {
        login
        avatarUrl
        __typename
      }
    }
  }
}
''';
