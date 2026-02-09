import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'screens/root_screen.dart';
import 'services/auth_service.dart';
import 'services/category_service.dart';
import 'services/challenge_service.dart';
import 'services/goal_service.dart';
import 'services/user_service.dart';
import 'state/session_controller.dart';

class HeadsUpApp extends StatelessWidget {
  const HeadsUpApp({
    super.key,
    required this.authService,
    required this.goalService,
    required this.categoryService,
    required this.challengeService,
    required this.userService,
  });

  final AuthService authService;
  final GoalService goalService;
  final CategoryService categoryService;
  final ChallengeService challengeService;
  final UserService userService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        Provider<GoalService>.value(value: goalService),
        Provider<CategoryService>.value(value: categoryService),
        Provider<ChallengeService>.value(value: challengeService),
        Provider<UserService>.value(value: userService),
        ChangeNotifierProvider<SessionController>(
          create: (_) => SessionController(authService: authService)..bootstrap(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'HeadsUp Mobile',
        theme: AppTheme.build(),
        home: const RootScreen(),
      ),
    );
  }
}
