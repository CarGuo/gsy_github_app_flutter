enum CommonListDataType {
  follower("follower"),
  followed("followed"),
  userRepos('user_repos'),
  repoStar("repo_star"),
  userStar("user_star"),
  repoWatcher("repo_watcher"),
  repoFork("repo_fork"),
  repoRelease("repoRelease"),
  repoTag("repo_tag"),
  notify("notify"),
  history("history"),
  topics("topics"),
  userBeStared("user_be_stared"),
  userOrgs("user_orgs");

  final String value;

  const CommonListDataType(this.value);
}
