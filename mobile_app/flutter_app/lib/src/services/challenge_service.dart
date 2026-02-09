import '../core/network/api_client.dart';
import '../models/challenge.dart';

class ChallengeService {
  const ChallengeService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ChallengeSummary>> listMyChallenges({int page = 1, int perPage = 20}) async {
    final response = await _apiClient.get(
      '/api/challenges/my',
      query: {
        'page': page,
        'per_page': perPage,
      },
    );

    final data = response['data'];
    if (data is! List) {
      return const <ChallengeSummary>[];
    }

    return data
        .whereType<Map>()
        .map((item) => ChallengeSummary.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}
