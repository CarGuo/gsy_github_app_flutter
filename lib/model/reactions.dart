/// GitHub Reactions 汇总模型
/// 官方 8 种：+1, -1, laugh, hooray, confused, heart, rocket, eyes
/// 参考 REST API：https://docs.github.com/en/rest/reactions
class Reactions {
  final int totalCount;
  final int plusOne;
  final int minusOne;
  final int laugh;
  final int hooray;
  final int confused;
  final int heart;
  final int rocket;
  final int eyes;

  const Reactions({
    this.totalCount = 0,
    this.plusOne = 0,
    this.minusOne = 0,
    this.laugh = 0,
    this.hooray = 0,
    this.confused = 0,
    this.heart = 0,
    this.rocket = 0,
    this.eyes = 0,
  });

  factory Reactions.empty() => const Reactions();

  factory Reactions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Reactions();
    int pick(String key) => (json[key] as num?)?.toInt() ?? 0;
    return Reactions(
      totalCount: pick('total_count'),
      plusOne: pick('+1'),
      minusOne: pick('-1'),
      laugh: pick('laugh'),
      hooray: pick('hooray'),
      confused: pick('confused'),
      heart: pick('heart'),
      rocket: pick('rocket'),
      eyes: pick('eyes'),
    );
  }

  /// 支持点击后的本地增量刷新，避免必须走网络回流。
  Reactions increment(String content, int delta) {
    switch (content) {
      case '+1':
        return copyWith(plusOne: plusOne + delta, totalCount: totalCount + delta);
      case '-1':
        return copyWith(minusOne: minusOne + delta, totalCount: totalCount + delta);
      case 'laugh':
        return copyWith(laugh: laugh + delta, totalCount: totalCount + delta);
      case 'hooray':
        return copyWith(hooray: hooray + delta, totalCount: totalCount + delta);
      case 'confused':
        return copyWith(confused: confused + delta, totalCount: totalCount + delta);
      case 'heart':
        return copyWith(heart: heart + delta, totalCount: totalCount + delta);
      case 'rocket':
        return copyWith(rocket: rocket + delta, totalCount: totalCount + delta);
      case 'eyes':
        return copyWith(eyes: eyes + delta, totalCount: totalCount + delta);
    }
    return this;
  }

  Reactions copyWith({
    int? totalCount,
    int? plusOne,
    int? minusOne,
    int? laugh,
    int? hooray,
    int? confused,
    int? heart,
    int? rocket,
    int? eyes,
  }) {
    return Reactions(
      totalCount: totalCount ?? this.totalCount,
      plusOne: plusOne ?? this.plusOne,
      minusOne: minusOne ?? this.minusOne,
      laugh: laugh ?? this.laugh,
      hooray: hooray ?? this.hooray,
      confused: confused ?? this.confused,
      heart: heart ?? this.heart,
      rocket: rocket ?? this.rocket,
      eyes: eyes ?? this.eyes,
    );
  }

  /// 以官方顺序返回 (content, emoji, count)
  List<ReactionEntry> get entries => <ReactionEntry>[
        ReactionEntry('+1', '👍', plusOne),
        ReactionEntry('-1', '👎', minusOne),
        ReactionEntry('laugh', '😄', laugh),
        ReactionEntry('hooray', '🎉', hooray),
        ReactionEntry('confused', '😕', confused),
        ReactionEntry('heart', '❤️', heart),
        ReactionEntry('rocket', '🚀', rocket),
        ReactionEntry('eyes', '👀', eyes),
      ];
}

class ReactionEntry {
  final String content;
  final String emoji;
  final int count;
  const ReactionEntry(this.content, this.emoji, this.count);
}
