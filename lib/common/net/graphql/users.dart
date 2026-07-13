const String readTrendUser = r'''
query getTrendUser($location: String!){
  search(type: USER, query: $location, first: 100) {
    pageInfo {
      endCursor
    }
    user: edges {
      user: node {
      		... on User {
            name,
            avatarUrl,
            followers {
              totalCount
            },
            bio,
            login,
            lang: repositories(orderBy: {field: STARGAZERS, direction: DESC}, first:1) {
              nodes{
                name
                languages(first:1)  {
                  nodes {
                    name
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


const String readTrendUserByCursor = r'''
query getTrendUser($location: String!,  $after: String!){
  search(type: USER, query: $location, first: 100, after: $after) {
    pageInfo {
      endCursor
    }
    user: edges {
      user: node {
      		... on User {
            name,
            avatarUrl,
            followers {
              totalCount
            },
            bio,
            login,
            lang: repositories(orderBy: {field: STARGAZERS, direction: DESC}, first:1) {
              nodes{
                name
                languages(first:1)  {
                  nodes {
                    name
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

/// 读取一个 user / organization 的 Pinned Repositories（最多 6 个）
///
/// 官方 profile 页顶部一等公民能力，REST 无对等端点，只能走 GraphQL。
/// 只取渲染 pinned 卡片所需的最小字段，不复用 [readRepository] 里的重字段集
/// （issues/topics/watchers/languages 全 fragment），避免为 pinned 场景把请求撑大。
///
/// 只查 `... on Repository`：pinnedItems 也可能是 Gist，这里 GSY 现阶段只展示仓库。
const String readUserPinnedItems = r'''
query getUserPinnedItems($login: String!) {
  user(login: $login) {
    pinnedItems(first: 6, types: REPOSITORY) {
      nodes {
        ... on Repository {
          name
          nameWithOwner
          description
          url
          isFork
          isPrivate
          stargazerCount
          forkCount
          primaryLanguage {
            name
            color
          }
          owner {
            login
            avatarUrl
          }
        }
      }
    }
  }
}
''';
