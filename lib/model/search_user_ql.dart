class SearchUserQL({
  final int? followers,
  final String? name,
  final String? avatarUrl,
  final String? bio,
  final String? login,
  final String? lang,
}) {
  static SearchUserQL fromMap(Map? map) {
    if (map == null) {
      return SearchUserQL();
    }
    String? lang;
    final langNode = map['lang'];
    if (langNode is Map) {
      final nodes = langNode['nodes'];
      if (nodes is List && nodes.isNotEmpty && nodes.first is Map) {
        final languages = (nodes.first as Map)['languages'];
        if (languages is Map) {
          final langNodes = languages['nodes'];
          if (langNodes is List &&
              langNodes.isNotEmpty &&
              langNodes.first is Map) {
            lang = (langNodes.first as Map)['name'] as String?;
          }
        }
      }
    }

    int? followers;
    final followersNode = map['followers'];
    if (followersNode is Map) {
      followers = (followersNode['totalCount'] as num?)?.toInt();
    }

    return SearchUserQL(
      followers: followers,
      name: map['name'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      bio: map['bio'] as String?,
      login: map['login'] as String?,
      lang: lang,
    );
  }
}
