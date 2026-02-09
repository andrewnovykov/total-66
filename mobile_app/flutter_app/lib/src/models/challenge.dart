class ChallengeSummary {
  const ChallengeSummary({
    required this.id,
    required this.title,
    required this.status,
    required this.type,
    required this.visibility,
    this.description,
    this.imagePath,
    this.durationDays,
    this.participantCount,
    this.categoryName,
  });

  final int id;
  final String title;
  final String status;
  final String type;
  final String visibility;
  final String? description;
  final String? imagePath;
  final int? durationDays;
  final int? participantCount;
  final String? categoryName;

  factory ChallengeSummary.fromJson(Map<String, dynamic> json) {
    return ChallengeSummary(
      id: _asInt(json['id']),
      title: (json['title'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      visibility: (json['visibility'] ?? '').toString(),
      description: json['description']?.toString(),
      imagePath: json['image_path']?.toString(),
      durationDays: json['duration_days'] == null ? null : _asInt(json['duration_days']),
      participantCount: json['participant_count'] == null ? null : _asInt(json['participant_count']),
      categoryName: _readCategoryName(json['category']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _readCategoryName(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value['name']?.toString();
    }
    if (value is Map) {
      return value['name']?.toString();
    }
    return null;
  }
}
