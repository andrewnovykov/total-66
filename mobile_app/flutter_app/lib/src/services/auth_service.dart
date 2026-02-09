import '../core/network/api_client.dart';
import '../models/app_user.dart';

class AuthService {
  const AuthService(this._apiClient);

  final ApiClient _apiClient;

  Future<AppUser> register({
    required String email,
    required String password,
    required String name,
    required String username,
    String? bio,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/register',
      data: {
        'email': email,
        'password': password,
        'name': name,
        'user_name': username,
        if (bio != null && bio.trim().isNotEmpty) 'bio': bio.trim(),
      },
    );

    final userData = Map<String, dynamic>.from(response['data'] as Map);
    return AppUser.fromJson(userData);
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final userData = Map<String, dynamic>.from(response['data'] as Map);
    return AppUser.fromJson(userData);
  }

  Future<AppUser> me() async {
    final response = await _apiClient.get('/api/auth/me');
    final userData = Map<String, dynamic>.from(response['data'] as Map);
    return AppUser.fromJson(userData);
  }

  Future<void> logout() async {
    await _apiClient.delete('/api/auth/logout');
  }
}
