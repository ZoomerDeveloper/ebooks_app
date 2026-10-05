class Stats {
  final int poemsRead;
  final int favoritesCount;
  final int totalPoems;
  final double progressPercent;
  final int poemsLearned;

  Stats({
    required this.poemsRead,
    required this.favoritesCount,
    required this.totalPoems,
    required this.progressPercent,
    this.poemsLearned = 0,
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      poemsRead: json['poems_read'] ?? 0,
      favoritesCount: json['favorites_count'] ?? 0,
      totalPoems: json['total_poems'] ?? 0,
      progressPercent: (json['progress_percent'] ?? 0.0).toDouble(),
      poemsLearned: json['poems_learned'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'poems_read': poemsRead,
      'favorites_count': favoritesCount,
      'total_poems': totalPoems,
      'progress_percent': progressPercent,
      'poems_learned': poemsLearned,
    };
  }
}
