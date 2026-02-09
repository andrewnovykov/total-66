class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.username,
    required this.name,
    required this.role,
    required this.privacy,
    required this.subscriptionType,
    this.bio,
    this.about,
    this.imagePath,
    this.level,
    this.xp,
    this.stats,
  });

  final int id;
  final String email;
  final String username;
  final String name;
  final String role;
  final String privacy;
  final String subscriptionType;
  final String? bio;
  final String? about;
  final String? imagePath;
  final int? level;
  final int? xp;
  final AppUserStats? stats;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final statsMap = _asMap(json['stats']);

    return AppUser(
      id: _asInt(json['id']),
      email: (json['email'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      role: (json['role'] ?? 'user').toString(),
      privacy: (json['privacy'] ?? 'public').toString(),
      subscriptionType: (json['subscription_type'] ?? 'free').toString(),
      bio: json['bio']?.toString(),
      about: json['about']?.toString(),
      imagePath: json['image_path']?.toString(),
      level: json['level'] == null ? null : _asInt(json['level']),
      xp: json['xp'] == null ? null : _asInt(json['xp']),
      stats: statsMap == null ? null : AppUserStats.fromJson(statsMap),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }
}

class AppUserStats {
  const AppUserStats({
    required this.followersCount,
    required this.followingCount,
    required this.friendsCount,
    required this.goalsCount,
  });

  final int followersCount;
  final int followingCount;
  final int friendsCount;
  final int goalsCount;

  factory AppUserStats.fromJson(Map<String, dynamic> json) {
    return AppUserStats(
      followersCount: _asInt(json['followers_count']),
      followingCount: _asInt(json['following_count']),
      friendsCount: _asInt(json['friends_count']),
      goalsCount: _asInt(json['goals_count']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
