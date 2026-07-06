class PullRequestReviewThread {
  final String? id;
  final bool? isResolved;
  final List<int> commentDatabaseIds;

  PullRequestReviewThread({
    this.id,
    this.isResolved,
    this.commentDatabaseIds = const [],
  });

  static PullRequestReviewThread? fromGraphql(Map? map) {
    if (map == null) {
      return null;
    }
    final List<int> ids = [];
    final Map? comments = map["comments"];
    if (comments != null && comments["nodes"] is List) {
      for (var item in (comments["nodes"] as List)) {
        if (item is Map && item["databaseId"] is int) {
          ids.add(item["databaseId"] as int);
        }
      }
    }
    return PullRequestReviewThread(
      id: map["id"],
      isResolved: map["isResolved"],
      commentDatabaseIds: ids,
    );
  }
}
