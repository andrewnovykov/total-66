import '../core/network/api_client.dart';
import '../models/app_user.dart';
import '../models/profile_stats.dart';

class UserService {
  const UserService(this._apiClient);

  final ApiClient _apiClient;

  Future<AppUser> getUserProfile(int userId) async {
    final response = await _apiClient.get('/api/users/$userId');
    final data = Map<String, dynamic>.from(response['data'] as Map);
    return AppUser.fromJson(data);
  }

  Future<AppUser> updateMyProfile({
    required String name,
    String? bio,
    String? about,
  }) async {
    final response = await _apiClient.put(
      '/api/users/me',
      data: {
        'user': {
          'name': name,
          if (bio != null) 'bio': bio,
          if (about != null) 'about': about,
        },
      },
    );

    final data = Map<String, dynamic>.from(response['data'] as Map);
    return AppUser.fromJson(data);
  }

  Future<UserPerformanceStats> getUserStats(int userId) async {
    final response = await _apiClient.get('/api/users/$userId/stats');
    final data = Map<String, dynamic>.from(response['data'] as Map);
    return UserPerformanceStats.fromJson(data);
  }

  Future<List<ActivityChartPoint>> getChartData(int userId, {int? year}) async {
    final response = await _apiClient.get(
      '/api/chart/$userId',
      query: year == null ? null : {'year': year},
    );

    final data = response['data'];
    if (data is! List) {
      return const <ActivityChartPoint>[];
    }

    return data
        .whereType<Map>()
        .map((item) => ActivityChartPoint.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}
