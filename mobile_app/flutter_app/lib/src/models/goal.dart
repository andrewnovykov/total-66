class Goal {
  const Goal({
    required this.id,
    required this.title,
    required this.status,
    required this.privacy,
    required this.progress,
    required this.likesCount,
    required this.subscribersCount,
    required this.postsCount,
    required this.steps,
    required this.recentPosts,
    this.description,
    this.bigDescription,
    this.targetDate,
    this.imagePath,
    this.failureReason,
    this.createdAt,
    this.updatedAt,
    this.failedAt,
    this.isFrozen,
    this.creator,
    this.category,
    this.userInteractions,
  });

  final int id;
  final String title;
  final String status;
  final String privacy;
  final int progress;
  final int likesCount;
  final int subscribersCount;
  final int postsCount;
  final List<GoalStep> steps;
  final List<GoalPost> recentPosts;
  final String? description;
  final String? bigDescription;
  final DateTime? targetDate;
  final String? imagePath;
  final String? failureReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? failedAt;
  final bool? isFrozen;
  final GoalCreator? creator;
  final GoalCategory? category;
  final GoalUserInteractions? userInteractions;

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: _asInt(json['id']),
      title: (json['title'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      privacy: (json['privacy'] ?? '').toString(),
      progress: _asInt(json['progress']),
      likesCount: _asInt(json['likes_count']),
      subscribersCount: _asInt(json['subscribers_count']),
      postsCount: _readPostsCount(json),
      steps: _readList(json['steps']).map(GoalStep.fromJson).toList(growable: false),
      recentPosts:
          _readList(json['recent_posts']).map(GoalPost.fromJson).toList(growable: false),
      description: json['description']?.toString(),
      bigDescription: json['big_description']?.toString(),
      targetDate: _asDate(json['target_date']),
      imagePath: json['image_path']?.toString(),
      failureReason: json['failure_reason']?.toString(),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
      failedAt: _asDate(json['failed_at']),
      isFrozen: _asBoolNullable(json['is_frozen']),
      creator: _asMap(json['creator']) == null
          ? null
          : GoalCreator.fromJson(_asMap(json['creator'])!),
      category: _asMap(json['category']) == null
          ? null
          : GoalCategory.fromJson(_asMap(json['category'])!),
      userInteractions: _asMap(json['user_interactions']) == null
          ? null
          : GoalUserInteractions.fromJson(_asMap(json['user_interactions'])!),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }

  static int _readPostsCount(Map<String, dynamic> json) {
    final explicit = json['post_count'];
    if (explicit != null) {
      return _asInt(explicit);
    }

    final recentPosts = json['recent_posts'];
    if (recentPosts is List) {
      return recentPosts.length;
    }

    return 0;
  }

  static List<Map<String, dynamic>> _readList(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  static bool? _asBoolNullable(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    final raw = value.toString().toLowerCase();
    if (raw == 'true') return true;
    if (raw == 'false') return false;
    return null;
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

class GoalCreator {
  const GoalCreator({
    required this.id,
    required this.name,
    required this.username,
    this.bio,
    this.level,
    this.imagePath,
  });

  final int id;
  final String name;
  final String username;
  final String? bio;
  final int? level;
  final String? imagePath;

  factory GoalCreator.fromJson(Map<String, dynamic> json) {
    return GoalCreator(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      bio: json['bio']?.toString(),
      level: json['level'] == null ? null : _asInt(json['level']),
      imagePath: json['image_path']?.toString(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class GoalCategory {
  const GoalCategory({
    required this.id,
    required this.name,
    this.description,
    this.imagePath,
  });

  final int id;
  final String name;
  final String? description;
  final String? imagePath;

  factory GoalCategory.fromJson(Map<String, dynamic> json) {
    return GoalCategory(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      imagePath: json['image_path']?.toString(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class GoalUserInteractions {
  const GoalUserInteractions({
    required this.isLiked,
    required this.isSubscribed,
    required this.isOwner,
  });

  final bool isLiked;
  final bool isSubscribed;
  final bool isOwner;

  factory GoalUserInteractions.fromJson(Map<String, dynamic> json) {
    return GoalUserInteractions(
      isLiked: _asBool(json['is_liked']),
      isSubscribed: _asBool(json['is_subscribed']),
      isOwner: _asBool(json['is_owner']),
    );
  }

  static bool _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    return value?.toString().toLowerCase() == 'true';
  }
}

class GoalStep {
  const GoalStep({
    required this.id,
    required this.title,
    required this.completed,
    this.order,
  });

  final int id;
  final String title;
  final bool completed;
  final int? order;

  factory GoalStep.fromJson(Map<String, dynamic> json) {
    return GoalStep(
      id: Goal._asInt(json['id']),
      title: (json['title'] ?? '').toString(),
      completed: Goal._asBoolNullable(json['completed']) ?? false,
      order: json['order'] == null ? null : Goal._asInt(json['order']),
    );
  }
}

class GoalPost {
  const GoalPost({
    required this.id,
    required this.content,
    required this.postType,
    this.imagePath,
    this.createdAt,
    this.author,
  });

  final int id;
  final String content;
  final String postType;
  final String? imagePath;
  final DateTime? createdAt;
  final GoalCreator? author;

  factory GoalPost.fromJson(Map<String, dynamic> json) {
    final authorMap = Goal._asMap(json['author']);

    return GoalPost(
      id: Goal._asInt(json['id']),
      content: (json['content'] ?? '').toString(),
      postType: (json['post_type'] ?? 'update').toString(),
      imagePath: json['image_path']?.toString(),
      createdAt: Goal._asDate(json['created_at']),
      author: authorMap == null ? null : GoalCreator.fromJson(authorMap),
    );
  }
}
