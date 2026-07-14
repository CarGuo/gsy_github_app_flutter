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

/// 读取一个 user 的 status（emoji / message / 是否忙碌）
///
/// GitHub 官方 profile 右侧头像下方的一行"状态胶囊"，是用户表达"正在做什么/
/// 忙碌中"的一等公民能力。REST v3 无对等端点，只能走 GraphQL v4 的
/// `user(login).status`。
///
/// 字段选取原则：
/// - 只取渲染 chip 需要的最小 3 项（emoji / message / indicatesLimitedAvailability），
///   不取 `expiresAt` 以避免多语言相对时间描述带来的额外文案与时区抖动
/// - `... on Organization` 无 status 字段，query 名义限定 `User`：真正的
///   `type=Organization` 短路发生在页面层（[BasePersonState] 挂载条件、
///   [PersonPage] 的 `_refreshStatus`），repository 层只做 `user==null` /
///   `status==null` 兜底；如果未来调用侧短路被拿掉，organization login
///   仍会走到这里请求 GraphQL 得到 `user: null`，被兜底为返回 null 而不会崩
const String readUserStatus = r'''
query getUserStatus($login: String!) {
  user(login: $login) {
    status {
      emoji
      message
      indicatesLimitedAvailability
    }
  }
}
''';

/// 读取一个 user / organization 的 Sponsors（最多 5 位）
///
/// GitHub Sponsors 一等公民能力：官方 profile 页 pinned 附近展示"支持者"栏。
/// REST 无对等端点，只能走 GraphQL v4 的 `user(login).sponsors`。
///
/// 字段选取原则：
/// - 只取 `totalCount` + 前 5 位 sponsor 的 login/avatarUrl，够渲染头像圆图 + 总数小字
/// - `sponsors.nodes` 类型是 `Sponsor`（union of User | Organization），必须写
///   `... on User` + `... on Organization` 双分支才能拿到 login/avatarUrl
/// - `user(login: ...)` 可命中 User 也可命中 Organization：GraphQL v4 层面 User 和
///   Organization 都支持 `sponsors` 字段（Sponsors 面向 org 也开放），无需
///   `... on User` 兜底，unset sponsor 用户会得到 `nodes: []` 且 `totalCount: 0`
const String readUserSponsors = r'''
query getUserSponsors($login: String!) {
  user(login: $login) {
    sponsors(first: 5) {
      totalCount
      nodes {
        ... on User {
          login
          avatarUrl
        }
        ... on Organization {
          login
          avatarUrl
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

/// 读取一个 user 的 Contribution Calendar（近 12 个月贡献日历）
///
/// GitHub 官方 profile 页顶部的贡献热力图，能力对齐说明：
/// - 官方 SVG 只能拿到"整块图片"，无法给具体 cell 挂点击回调；这份 GraphQL
///   query 直接返回结构化 `weeks[].contributionDays[]`（date + contributionCount
///   + color），前端自绘 heatmap 后 cell 可挂 GestureDetector + Tooltip
/// - 只取渲染 heatmap 所需的最小字段：不取 issueContributions /
///   commitContributions / pullRequestReviewContributions 明细，那些属于
///   "点击 cell 后展开当日事件"的进阶需求，本次不做
/// - `totalContributions` 保留：GSY UI 会显示"共 N 次贡献"小字，与 Sponsors
///   "共 N 位"标题风格一致
/// - `... on Organization` 无 contributionsCollection 字段，query 名义限定
///   `User`：Organization 短路由页面层（[BasePersonState] 挂载条件、
///   [PersonPage] 的 `_refreshContributionCalendar`）处理，repository 层只做
///   `user==null` / `contributionsCollection==null` 兜底
const String readUserContributionCalendar = r'''
query getUserContributionCalendar($login: String!) {
  user(login: $login) {
    contributionsCollection {
      contributionCalendar {
        totalContributions
        weeks {
          contributionDays {
            date
            contributionCount
            color
          }
        }
      }
    }
  }
}
''';
