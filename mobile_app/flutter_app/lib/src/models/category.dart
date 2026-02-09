class Category {
  const Category({
    required this.id,
    required this.name,
    this.description,
    this.imagePath,
    this.status,
    this.parentId,
  });

  final int id;
  final String name;
  final String? description;
  final String? imagePath;
  final String? status;
  final int? parentId;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      imagePath: json['image_path']?.toString(),
      status: json['status']?.toString(),
      parentId: json['parent_id'] == null ? null : _asInt(json['parent_id']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
