import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'src/app.dart';
import 'src/core/config/app_config.dart';
import 'src/core/network/api_client.dart';
import 'src/services/auth_service.dart';
import 'src/services/category_service.dart';
import 'src/services/challenge_service.dart';
import 'src/services/goal_service.dart';
import 'src/services/user_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final apiClient = ApiClient(baseUrl: AppConfig.apiBaseUrl);
  final authService = AuthService(apiClient);
  final goalService = GoalService(apiClient);
  final categoryService = CategoryService(apiClient);
  final challengeService = ChallengeService(apiClient);
  final userService = UserService(apiClient);

  runApp(
    HeadsUpApp(
      authService: authService,
      goalService: goalService,
      categoryService: categoryService,
      challengeService: challengeService,
      userService: userService,
    ),
  );
}
