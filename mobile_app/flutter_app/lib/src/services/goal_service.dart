import '../core/network/api_client.dart';
import '../models/goal.dart';

class GoalService {
  const GoalService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Goal>> listPublicGoals({
    String? status,
    String? search,
    String? sort,
    int page = 1,
    int perPage = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (status != null && status.isNotEmpty) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
      if (sort != null && sort.isNotEmpty) 'sort': sort,
    };

    final response = await _apiClient.get('/api/goals', query: query);
    return _readGoalList(response);
  }

  Future<List<Goal>> listMyGoals({int page = 1, int perPage = 20}) async {
    final response = await _apiClient.get(
      '/api/goals/my',
      query: {
        'page': page,
        'per_page': perPage,
      },
    );
    return _readGoalList(response);
  }

  Future<Goal> getGoal(int goalId) async {
    final response = await _apiClient.get('/api/goals/$goalId');
    return Goal.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  Future<Goal> createGoal({
    required String title,
    String? description,
    String? bigDescription,
    required int groupId,
    required String privacy,
    required DateTime targetDate,
  }) async {
    final response = await _apiClient.post(
      '/api/goals',
      data: {
        'goal': {
          'title': title,
          'description': description,
          'big_description': bigDescription,
          'group_id': groupId,
          'privacy': privacy,
          'target_date': targetDate.toUtc().toIso8601String(),
        }
      },
    );

    return Goal.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  Future<void> likeGoal(int goalId) async {
    await _apiClient.post('/api/goals/$goalId/like');
  }

  Future<void> unlikeGoal(int goalId) async {
    await _apiClient.delete('/api/goals/$goalId/like');
  }

  Future<void> subscribeToGoal(int goalId) async {
    await _apiClient.post('/api/goals/$goalId/subscribe');
  }

  Future<void> unsubscribeFromGoal(int goalId) async {
    await _apiClient.delete('/api/goals/$goalId/subscribe');
  }

  List<Goal> _readGoalList(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! List) {
      return const <Goal>[];
    }

    return data
        .whereType<Map>()
        .map((item) => Goal.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}
