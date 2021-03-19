class RepositoryQL {
  final int? issuesClosed;
  final int? issuesOpen;
  final int? issuesTotal;
  final String? reposName;
  final String? reposFullName;
  final String? ownerName;
  final String? ownerAvatarUrl;
  final String? license;
  final int? forkCount;
  final int? starCount;
  final int? watcherCount;
  final bool? isFork;
  final bool? isStared;
  final bool? hasIssuesEnabled;
  final String? defaultBranch;
  final String? isSubscription;
  final String? language;
  final int? size;
  final String? createdAt;
  final String? pushAt;
  final String? sshUrl;
  final String? htmlUrl;
  final String? shortDescriptionHTML;
  final List<String?>? topics;
  final RepositoryQL? parent;

  RepositoryQL({
    this.issuesClosed,
    this.issuesOpen,
    this.issuesTotal,
    this.reposName,
    this.reposFullName,
    this.ownerName,
    this.ownerAvatarUrl,
    this.license,
    this.forkCount,
    this.starCount,
    this.watcherCount,
    this.isFork,
    this.isStared,
    this.hasIssuesEnabled,
    this.defaultBranch,
    this.isSubscription,
    this.language,
    this.size,
    this.createdAt,
    this.pushAt,
    this.sshUrl,
    this.htmlUrl,
    this.shortDescriptionHTML,
    this.topics,
    this.parent,
  });

  static fromMap(Map? map) {
    List<String?> topics = [];
    if (map == null) {
      return null;
    }
    Map? repositoryTopics = map["repositoryTopics"];
    if (repositoryTopics != null) {
      List topicList = repositoryTopics["nodes"];
      topicList.forEach((item) {
        topics.add(item["topic"]["name"]);
      });
    }
    return RepositoryQL(
      issuesClosed: map["issuesClosed"]["totalCount"],
      issuesOpen: map["issuesOpen"]["totalCount"],
      issuesTotal: map["issues"]["totalCount"],
      defaultBranch: map["defaultBranchRef"] != null ? map["defaultBranchRef"]["name"] : null,
      reposName: map["name"],
      hasIssuesEnabled: map["hasIssuesEnabled"],
      reposFullName: map["nameWithOwner"],
      ownerName: map["owner"]["login"],
      ownerAvatarUrl: map["owner"]["avatarUrl"],
      license: map["licenseInfo"] != null ? map["licenseInfo"]["name"] : null,
      forkCount: map["forkCount"],
      watcherCount: map["watchers"]["totalCount"],
      isFork: map["isFork"],
      starCount: map["stargazers"]["totalCount"],
      isStared: map["viewerHasStarred"],
      isSubscription: map["viewerSubscription"],
      language: (map["languages"] != null &&
              map["languages"]["nodes"] != null &&
              map["languages"]["nodes"].length > 0)
          ? map["languages"]["nodes"][0]["name"]
          : null,
      size: map["languages"]["totalSize"],
      createdAt: map["createdAt"],
      pushAt: map["pushedAt"],
      sshUrl: map["sshUrl"],
      htmlUrl: map["url"],
      shortDescriptionHTML: map["shortDescriptionHTML"],
      topics: topics,
      parent: RepositoryQL.fromMap(map["parent"]),
    );
  }

  static toMap(RepositoryQL? repositoryQL) {
    var topics = {};
    if (repositoryQL == null) {
      return null;
    }
    if (repositoryQL.topics != null) {
      var list = [];
      repositoryQL.topics!.forEach((item) {
        list.add({"topic": item});
      });
      topics["nodes"] = list;
    }
    var map = {
      "issuesClosed": {
        "totalCount": repositoryQL.issuesClosed,
      },
      "issuesOpen": {
        "totalCount": repositoryQL.issuesOpen,
      },
      "issuesTotal": {
        "totalCount": repositoryQL.issuesTotal,
      },
      "defaultBranchRef": {
        "name": repositoryQL.defaultBranch,
      },
      "name": repositoryQL.reposName,
      "hasIssuesEnabled": repositoryQL.hasIssuesEnabled,
      "nameWithOwner": repositoryQL.reposFullName,
      "owner": {
        "login": repositoryQL.ownerName,
        "avatarUrl": repositoryQL.ownerAvatarUrl,
      },
      "languages": {
        "nodes": [
          {
            "name": repositoryQL.language,
          }
        ],
        "totalSize": repositoryQL.size,
      },
      "licenseInfo": {
        "name": repositoryQL.license,
      },
      "forkCount": repositoryQL.forkCount,
      "stargazers": {"totalSize": repositoryQL.starCount},
      "watcherCount": {
        "watchers": repositoryQL.watcherCount,
      },
      "isFork": repositoryQL.isFork,
      "viewerHasStarred": repositoryQL.isStared,
      "viewerSubscription": repositoryQL.isSubscription,
      "createdAt": repositoryQL.createdAt,
      "pushedAt": repositoryQL.pushAt,
      "sshUrl": repositoryQL.sshUrl,
      "url": repositoryQL.htmlUrl,
      "shortDescriptionHTML": repositoryQL.shortDescriptionHTML,
      "topic": topics,
      "parent": toMap(repositoryQL.parent),
    };

    return map;
  }
}
