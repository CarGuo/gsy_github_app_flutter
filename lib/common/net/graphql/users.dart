/// Trend 用户列表 GraphQL query
///
/// GitHub 语义澄清：
/// `search(type: USER, ...)` 的 `edges[i].node` 是 `SearchResultItem` union，
/// **`type: USER` 语义上就包含 Organization**——GH 官方把 User 和 Organization
/// 统称为 "Account"。`sort:followers` 场景下 China 榜顶部字节 / 腾讯 / 阿里 /
/// PaddlePaddle 等 org 帐号必然混入。
///
/// 因此这里同时写 `... on User { ... }` 和 `... on Organization { ... }`
/// 两个 fragment，让 org 命中时也能拿到 login/avatar/description 等字段。
///
/// 字段对齐（User vs Organization）：
/// - `name`：都有
/// - `login`：都有（Organization.login 一定 non-null）
/// - `avatarUrl`：都有
/// - `bio`：Organization 无 → 用 `description`，Repository 层映射时统一到 `bio`
/// - `followers`：Organization 无 → 组织的"关注度"用 `membersWithRole.totalCount`
///   近似（成员数），Repository 层映射到 `followers` 字段以复用 UI
/// - `lang`：User / Organization 都取最高星标仓库的 `primaryLanguage`。
///   2026-10-24 / FPR-120：语言组成连接的首项不能代表主语言；首屏与游标
///   两份查询保持相同语义，不改变最高星标仓库的选择范围。
///
/// 加 `__typename` 让 Repository 层用 `node['__typename']` 做严格判据，区分
/// User / Organization 分支映射（比 `login == null` 兜底更清晰），并把
/// isOrganization 传递到 UI 层加"组织"徽标。
const String readTrendUser = r'''
query getTrendUser($location: String!){
  search(type: USER, query: $location, first: 100) {
    pageInfo {
      endCursor
    }
    user: edges {
      user: node {
      		__typename
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
                primaryLanguage {
                  name
                }
              }
            }
          }
      		... on Organization {
            name,
            avatarUrl,
            login,
            description,
            membersWithRole {
              totalCount
            },
            lang: repositories(orderBy: {field: STARGAZERS, direction: DESC}, first:1) {
              nodes{
                name
                primaryLanguage {
                  name
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
      		__typename
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
                primaryLanguage {
                  name
                }
              }
            }
          }
      		... on Organization {
            name,
            avatarUrl,
            login,
            description,
            membersWithRole {
              totalCount
            },
            lang: repositories(orderBy: {field: STARGAZERS, direction: DESC}, first:1) {
              nodes{
                name
                primaryLanguage {
                  name
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
