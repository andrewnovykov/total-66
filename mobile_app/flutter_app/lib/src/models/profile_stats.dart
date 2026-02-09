class UserPerformanceStats {
  const UserPerformanceStats({
    required this.xp,
    required this.level,
    required this.levelName,
    required this.nextLevelXp,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalGoals,
    required this.completedGoals,
    required this.totalPosts,
    required this.totalLikesReceived,
    required this.totalLikesGiven,
    required this.completionRate,
  });

  final int xp;
  final int level;
  final String levelName;
  final int nextLevelXp;
  final int currentStreak;
  final int longestStreak;
  final int totalGoals;
  final int completedGoals;
  final int totalPosts;
  final int totalLikesReceived;
  final int totalLikesGiven;
  final double completionRate;

  factory UserPerformanceStats.fromJson(Map<String, dynamic> json) {
    return UserPerformanceStats(
      xp: _asInt(json['xp']),
      level: _asInt(json['level']),
      levelName: (json['level_name'] ?? 'Rookie').toString(),
      nextLevelXp: _asInt(json['next_level_xp']),
      currentStreak: _asInt(json['current_streak']),
      longestStreak: _asInt(json['longest_streak']),
      totalGoals: _asInt(json['total_goals']),
      completedGoals: _asInt(json['completed_goals']),
      totalPosts: _asInt(json['total_posts']),
      totalLikesReceived: _asInt(json['total_likes_received']),
      totalLikesGiven: _asInt(json['total_likes_given']),
      completionRate: _asDouble(json['completion_rate']),
    );
  }

  int get xpToNextLevel => (nextLevelXp - xp).clamp(0, nextLevelXp);

  double get progress {
    if (nextLevelXp <= 0) return 0;
    return (xp / nextLevelXp).clamp(0, 1);
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ActivityChartPoint {
  const ActivityChartPoint({
    required this.date,
    required this.activityCount,
    required this.intensity,
    required this.totalXp,
  });

  final DateTime date;
  final int activityCount;
  final int intensity;
  final int totalXp;

  factory ActivityChartPoint.fromJson(Map<String, dynamic> json) {
    return ActivityChartPoint(
      date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime(1970),
      activityCount: _asInt(json['activity_count']),
      intensity: _asInt(json['intensity']),
      totalXp: _asInt(json['total_xp']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
