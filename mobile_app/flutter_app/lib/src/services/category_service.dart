import '../core/network/api_client.dart';
import '../models/category.dart';

class CategoryService {
  const CategoryService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Category>> listCategories() async {
    final response = await _apiClient.get('/api/categories');
    final data = response['data'];

    if (data is! List) {
      return const <Category>[];
    }

    return data
        .whereType<Map>()
        .map((item) => Category.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}
