// GitHub Discussions GraphQL 查询模板。
//
// 这个文件承接的是 roadmap §3.1 的第一项："Discussions 阅读页"的骨架阶段。
// 当前只包含单条 discussion 的最小读取字段，comments 分页等交互能力留给后续
// 子任务。命名与 [repositories.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/net/graphql/repositories.dart)
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
