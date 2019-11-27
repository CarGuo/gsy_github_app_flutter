class SearchUserQL {
  final int followers;
  final String name;
  final String avatarUrl;
  final String bio;
  final String login;
  final String lang;

  SearchUserQL({
    this.followers,
    this.name,
    this.avatarUrl,
    this.bio,
    this.login,
    this.lang,
  });

  static fromMap(Map map) {
    String lang;
    if (map["lang"] != null &&
        map["lang"]["nodes"] != null &&
        map["lang"]["nodes"].length > 0 &&
        map["lang"]["nodes"][0]["languages"] != null &&
        map["lang"]["nodes"][0]["languages"]["nodes"] != null &&
        map["lang"]["nodes"][0]["languages"]["nodes"].length > 0) {
      lang = map["lang"]["nodes"][0]["languages"]["nodes"][0]["name"];
    }
    return SearchUserQL(
      followers: map["followers"]["totalCount"],
      name: map["name"],
      avatarUrl: map["avatarUrl"],
      bio: map["bio"],
      login: map["login"],
      lang: lang,
    );
  }
}
