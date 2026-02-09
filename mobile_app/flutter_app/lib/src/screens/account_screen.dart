import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/network/api_exception.dart';
import '../core/theme/app_theme.dart';
import '../models/app_user.dart';
import '../models/challenge.dart';
import '../models/goal.dart';
import '../models/profile_stats.dart';
import '../services/challenge_service.dart';
import '../services/goal_service.dart';
import '../services/user_service.dart';
import '../state/session_controller.dart';
import 'goal_detail_screen.dart';

enum _AuthMode { login, register }

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();

  final TextEditingController _registerNameController = TextEditingController();
  final TextEditingController _registerUsernameController = TextEditingController();
  final TextEditingController _registerEmailController = TextEditingController();
  final TextEditingController _registerPasswordController = TextEditingController();
  final TextEditingController _registerBioController = TextEditingController();

  final TextEditingController _editNameController = TextEditingController();
  final TextEditingController _editBioController = TextEditingController();
  final TextEditingController _editAboutController = TextEditingController();

  SessionController? _session;
  _AuthMode _authMode = _AuthMode.login;

  bool _isLoadingProfile = false;
  String? _profileError;
  int? _loadedUserId;

  AppUser? _profileUser;
  UserPerformanceStats? _performanceStats;
  List<ActivityChartPoint> _chart = const <ActivityChartPoint>[];
  List<Goal> _myGoals = const <Goal>[];
  List<ChallengeSummary> _myChallenges = const <ChallengeSummary>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = context.read<SessionController>();
    if (_session == session) {
      return;
    }
    _session?.removeListener(_onSessionChanged);
    _session = session;
    _session?.addListener(_onSessionChanged);
    _onSessionChanged();
  }

  @override
  void dispose() {
    _session?.removeListener(_onSessionChanged);
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerUsernameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerBioController.dispose();
    _editNameController.dispose();
    _editBioController.dispose();
    _editAboutController.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    final session = _session;
    if (session == null || !mounted) return;

    if (!session.isAuthenticated) {
      setState(() {
        _loadedUserId = null;
        _profileUser = null;
        _performanceStats = null;
        _chart = const <ActivityChartPoint>[];
        _myGoals = const <Goal>[];
        _myChallenges = const <ChallengeSummary>[];
        _profileError = null;
        _isLoadingProfile = false;
      });
      return;
    }

    final userId = session.currentUser?.id;
    if (userId != null && _loadedUserId != userId) {
      _loadProfileData();
    }
  }

  Future<void> _loadProfileData() async {
    final session = _session;
    if (session == null || !session.isAuthenticated) return;

    final userId = session.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _isLoadingProfile = true;
      _profileError = null;
    });

    try {
      final userService = context.read<UserService>();
      final goalService = context.read<GoalService>();
      final challengeService = context.read<ChallengeService>();

      final userProfile = await userService.getUserProfile(userId);
      final goals = await goalService.listMyGoals();
      final challenges = await challengeService.listMyChallenges();

      UserPerformanceStats? stats;
      List<ActivityChartPoint> chart = const <ActivityChartPoint>[];

      try {
        stats = await userService.getUserStats(userId);
      } catch (_) {
        stats = null;
      }

      try {
        chart = await userService.getChartData(userId, year: DateTime.now().year);
      } catch (_) {
        chart = const <ActivityChartPoint>[];
      }

      if (!mounted) return;
      setState(() {
        _loadedUserId = userId;
        _profileUser = userProfile;
        _myGoals = goals;
        _myChallenges = challenges;
        _performanceStats = stats;
        _chart = chart;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _profileError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profileError = 'Failed to load profile data';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    final session = _session;
    if (session == null) return;

    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Email and password are required');
      return;
    }

    final success = await session.login(email: email, password: password);
    if (success) {
      _loginPasswordController.clear();
      await _loadProfileData();
    }
  }

  Future<void> _handleRegister() async {
    final session = _session;
    if (session == null) return;

    final name = _registerNameController.text.trim();
    final username = _registerUsernameController.text.trim();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text;
    final bio = _registerBioController.text.trim();

    if (name.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Name, username, email, and password are required');
      return;
    }

    final success = await session.register(
      name: name,
      username: username,
      email: email,
      password: password,
      bio: bio.isEmpty ? null : bio,
    );
    if (success) {
      _registerPasswordController.clear();
      await _loadProfileData();
    }
  }

  Future<void> _handleLogout() async {
    await _session?.logout();
  }

  Future<void> _showEditProfileSheet(AppUser user) async {
    _editNameController.text = user.name;
    _editBioController.text = user.bio ?? '';
    _editAboutController.text = user.about ?? '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, 20 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _editNameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _editBioController,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _editAboutController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'About'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveProfileEdits,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfileEdits() async {
    final session = _session;
    final currentUser = session?.currentUser;
    if (session == null || currentUser == null) return;

    final name = _editNameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Name is required');
      return;
    }

    try {
      final userService = context.read<UserService>();
      final updated = await userService.updateMyProfile(
        name: name,
        bio: _editBioController.text.trim(),
        about: _editAboutController.text.trim(),
      );

      if (!mounted) return;
      session.updateCurrentUser(updated);
      Navigator.of(context).pop();
      await _loadProfileData();
      _showMessage('Profile updated');
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Failed to update profile');
    }
  }

  void _openGoal(Goal goal) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GoalDetailScreen(goalId: goal.id),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();

    if (session.isLoading && !session.isAuthenticated) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!session.isAuthenticated) {
      return _AuthView(
        mode: _authMode,
        isLoading: session.isLoading,
        errorMessage: session.errorMessage,
        loginEmailController: _loginEmailController,
        loginPasswordController: _loginPasswordController,
        registerNameController: _registerNameController,
        registerUsernameController: _registerUsernameController,
        registerEmailController: _registerEmailController,
        registerPasswordController: _registerPasswordController,
        registerBioController: _registerBioController,
        onModeChange: (mode) => setState(() => _authMode = mode),
        onLogin: _handleLogin,
        onRegister: _handleRegister,
      );
    }

    final user = _profileUser ?? session.currentUser!;
    final stat = _performanceStats;

    return RefreshIndicator(
      onRefresh: _loadProfileData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
        children: [
          _ProfileHeroCard(user: user),
          const SizedBox(height: 14),
          _AboutCard(
            user: user,
            onEdit: () => _showEditProfileSheet(user),
          ),
          const SizedBox(height: 14),
          _LevelCard(stats: stat, fallbackLevel: user.level, fallbackXp: user.xp),
          const SizedBox(height: 14),
          _GoalsSection(goals: _myGoals, onOpenGoal: _openGoal),
          const SizedBox(height: 14),
          _ChallengesSection(challenges: _myChallenges),
          const SizedBox(height: 14),
          _CommitmentCard(
            stats: stat,
            chartPoints: _chart,
            isLoading: _isLoadingProfile,
          ),
          if ((_profileError ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  _profileError!,
                  style: const TextStyle(color: Color(0xFFB42318), fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: session.isLoading ? null : _handleLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

class _AuthView extends StatelessWidget {
  const _AuthView({
    required this.mode,
    required this.isLoading,
    required this.errorMessage,
    required this.loginEmailController,
    required this.loginPasswordController,
    required this.registerNameController,
    required this.registerUsernameController,
    required this.registerEmailController,
    required this.registerPasswordController,
    required this.registerBioController,
    required this.onModeChange,
    required this.onLogin,
    required this.onRegister,
  });

  final _AuthMode mode;
  final bool isLoading;
  final String? errorMessage;

  final TextEditingController loginEmailController;
  final TextEditingController loginPasswordController;
  final TextEditingController registerNameController;
  final TextEditingController registerUsernameController;
  final TextEditingController registerEmailController;
  final TextEditingController registerPasswordController;
  final TextEditingController registerBioController;

  final ValueChanged<_AuthMode> onModeChange;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final isLogin = mode == _AuthMode.login;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2F68E8), Color(0xFF5142E5)],
            ),
            borderRadius: BorderRadius.circular(34),
          ),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to HeadsUp',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30 / 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Sign in or create an account to manage goals, profile, and social progress.',
                style: TextStyle(
                  color: Color(0xFFDDE6FF),
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _modeButton(
                        text: 'Login',
                        selected: isLogin,
                        onTap: () => onModeChange(_AuthMode.login),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _modeButton(
                        text: 'Register',
                        selected: !isLogin,
                        onTap: () => onModeChange(_AuthMode.register),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (isLogin) ...[
                  TextField(
                    controller: loginEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: loginPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                ] else ...[
                  TextField(
                    controller: registerNameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: registerUsernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: registerEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: registerPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: registerBioController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Bio (optional)'),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isLoading ? null : (isLogin ? onLogin : onRegister),
                    child: Text(isLogin ? 'Log In' : 'Create Account'),
                  ),
                ),
                if ((errorMessage ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFB42318),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _modeButton({
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0E1A3A) : const Color(0xFFF3F6FC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF6D7B93),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({required this.user});

  final AppUser user;

  String _initials() {
    final source = user.name.trim().isEmpty ? user.username : user.name;
    final parts = source.trim().split(' ').where((part) => part.isNotEmpty).toList(growable: false);
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final stats = user.stats;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F68E8), Color(0xFF5142E5)],
        ),
        borderRadius: BorderRadius.circular(34),
      ),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 10,
            child: Icon(
              Icons.account_circle_outlined,
              size: 190,
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),
          Column(
            children: [
              Container(
                width: 124,
                height: 124,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: const Color(0xFF9AB9FF), width: 4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: user.imagePath != null && user.imagePath!.trim().isNotEmpty
                      ? Image.network(user.imagePath!, fit: BoxFit.cover)
                      : Container(
                          color: const Color(0xFF6A68EA),
                          alignment: Alignment.center,
                          child: Text(
                            _initials(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                user.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24 / 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@${user.username}',
                style: const TextStyle(
                  color: Color(0xFFDCE6FF),
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                (user.bio ?? '').trim().isEmpty ? 'No bio yet' : user.bio!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFDCE6FF),
                  fontSize: 17,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 24,
                runSpacing: 10,
                children: [
                  _counter('followers', stats?.followersCount ?? 0),
                  _counter('following', stats?.followingCount ?? 0),
                  _counter('friends', stats?.friendsCount ?? 0),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x66D7E5FF)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, color: Color(0xFFE2EAFF)),
                    const SizedBox(width: 8),
                    Text(
                      _privacyLabel(user.privacy),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Color(0xFFE2EAFF)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _privacyLabel(String value) {
    if (value.isEmpty) return 'Public';
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  Widget _counter(String label, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFDCE6FF), fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.user, required this.onEdit});

  final AppUser user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final about = (user.about ?? '').trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF2F68E8)),
                const SizedBox(width: 10),
                const Text(
                  'About',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24 / 1.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onEdit,
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      color: Color(0xFF2F68E8),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              about.isEmpty ? 'Tell others more about yourself.' : about,
              style: const TextStyle(
                color: Color(0xFF4D5F79),
                fontSize: 18,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.stats,
    required this.fallbackLevel,
    required this.fallbackXp,
  });

  final UserPerformanceStats? stats;
  final int? fallbackLevel;
  final int? fallbackXp;

  @override
  Widget build(BuildContext context) {
    final level = stats?.level ?? (fallbackLevel ?? 1);
    final xp = stats?.xp ?? (fallbackXp ?? 0);
    final next = stats?.nextLevelXp ?? 100;
    final progress = next <= 0 ? 0.0 : (xp / next).clamp(0, 1).toDouble();
    final xpToNext = math.max(next - xp, 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up_rounded, color: Color(0xFF2F68E8)),
                const SizedBox(width: 10),
                const Text(
                  'Level',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24 / 1.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '$xpToNext XP to next level',
                  style: const TextStyle(
                    color: Color(0xFF6D7B93),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Level $level',
                    style: const TextStyle(
                      color: Color(0xFF4338CA),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'XP $xp',
                  style: const TextStyle(
                    color: Color(0xFF6D7B93),
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 13,
                value: progress,
                backgroundColor: const Color(0xFFE8EDF7),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF585EEB)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  '0 XP',
                  style: TextStyle(color: Color(0xFF6D7B93), fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '$next XP',
                  style: const TextStyle(color: Color(0xFF6D7B93), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalsSection extends StatelessWidget {
  const _GoalsSection({required this.goals, required this.onOpenGoal});

  final List<Goal> goals;
  final ValueChanged<Goal> onOpenGoal;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goals (${goals.length})',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24 / 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            if (goals.isEmpty)
              const Text(
                'No goals yet',
                style: TextStyle(
                  color: Color(0xFF6D7B93),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              ...goals.map(
                (goal) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ProfileGoalCard(
                    goal: goal,
                    onTap: () => onOpenGoal(goal),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileGoalCard extends StatelessWidget {
  const _ProfileGoalCard({required this.goal, required this.onTap});

  final Goal goal;
  final VoidCallback onTap;

  String _targetDate() {
    final date = goal.targetDate;
    if (date == null) return 'Not set';
    final local = date.toLocal();
    final month = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ][local.month - 1];
    return '$month ${local.day}, ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final statusRaw = goal.status.toLowerCase();
    final statusLabel = statusRaw.isEmpty ? 'Unknown' : '${statusRaw[0].toUpperCase()}${statusRaw.substring(1)}';
    final isFailed = statusRaw == 'failed';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFDFEFF),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              child: SizedBox(
                height: 168,
                width: double.infinity,
                child: goal.imagePath != null && goal.imagePath!.trim().isNotEmpty
                    ? Image.network(
                        goal.imagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallbackPoster(),
                      )
                    : _fallbackPoster(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22 / 1.2,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _pill(
                        text: statusLabel,
                        background: isFailed ? const Color(0xFFFFECE9) : const Color(0xFFEAF7EE),
                        textColor: isFailed ? const Color(0xFFE54735) : const Color(0xFF17A34A),
                        icon: Icons.circle,
                        iconColor: isFailed ? const Color(0xFFE54735) : const Color(0xFF22C55E),
                      ),
                      _pill(
                        text: goal.privacy.isEmpty ? 'Public' : goal.privacy,
                        background: const Color(0xFFF0F4FB),
                        textColor: const Color(0xFF607089),
                        icon: Icons.public,
                        iconColor: const Color(0xFF607089),
                      ),
                      _pill(
                        text: goal.category?.name ?? 'General',
                        background: const Color(0xFFEAF0FF),
                        textColor: const Color(0xFF2F68E8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    goal.description ?? 'No description',
                    style: const TextStyle(
                      color: Color(0xFF4D5F79),
                      fontSize: 17,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, color: Color(0xFF92A1B8)),
                      const SizedBox(width: 8),
                      Text(
                        'Target: ${_targetDate()}',
                        style: const TextStyle(
                          color: Color(0xFF6D7B93),
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Goal Progress',
                        style: TextStyle(
                          color: Color(0xFF6D7B93),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${goal.progress}%',
                        style: const TextStyle(
                          color: Color(0xFF4F46E5),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 11,
                      value: (goal.progress.clamp(0, 100)) / 100,
                      backgroundColor: const Color(0xFFE8EDF6),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF585EEB)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _engagement(Icons.favorite_border, '${goal.likesCount}'),
                      const SizedBox(width: 18),
                      _engagement(Icons.remove_red_eye_outlined, '${goal.subscribersCount}'),
                      const SizedBox(width: 18),
                      _engagement(Icons.share_outlined, 'Share'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackPoster() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9AF45A), Color(0xFF15181F), Color(0xFF15181F)],
          stops: [0, 0.33, 1],
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: const Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          'SET YOUR GOALS AND\nSTART YOUR JOURNEY',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18 / 1.4,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
      ),
    );
  }

  Widget _pill({
    required String text,
    required Color background,
    required Color textColor,
    IconData? icon,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: iconColor ?? textColor),
            const SizedBox(width: 7),
          ],
          Text(
            text,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _engagement(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF7D8CA5)),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF6D7B93),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _ChallengesSection extends StatelessWidget {
  const _ChallengesSection({required this.challenges});

  final List<ChallengeSummary> challenges;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Challenges (${challenges.length})',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24 / 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            if (challenges.isEmpty)
              const Text(
                'No active challenges',
                style: TextStyle(color: Color(0xFF6D7B93), fontWeight: FontWeight.w600),
              )
            else
              ...challenges.map(
                (challenge) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F8FD),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3C78F4), Color(0xFF5142E5)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                challenge.title.isEmpty ? 'Untitled challenge' : challenge.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _chip(challenge.status),
                                  if ((challenge.durationDays ?? 0) > 0) _chip('${challenge.durationDays}d'),
                                  if ((challenge.type).isNotEmpty) _chip(challenge.type),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFF9EACC1)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF2F68E8),
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _CommitmentCard extends StatelessWidget {
  const _CommitmentCard({
    required this.stats,
    required this.chartPoints,
    required this.isLoading,
  });

  final UserPerformanceStats? stats;
  final List<ActivityChartPoint> chartPoints;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final trackedDays = chartPoints.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart_rounded, color: Color(0xFF2F68E8)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Commitment Chart',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24 / 1.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '$trackedDays days tracked',
                  style: const TextStyle(
                    color: Color(0xFF6D7B93),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FBFF),
                border: Border.all(color: const Color(0xFFE2E8F3)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Activity Chart',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your commitment over the past year',
                          style: TextStyle(
                            color: Color(0xFF6D7B93),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Heatmap(points: chartPoints),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Text('Less active', style: TextStyle(color: Color(0xFF6D7B93))),
                            SizedBox(width: 10),
                            _Legend(),
                            Spacer(),
                            Text('More active', style: TextStyle(color: Color(0xFF6D7B93))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _metricBox(
                          title: '${stats?.xp ?? 0}',
                          subtitle: 'Total XP',
                          note: 'Experience Points',
                          background: const Color(0xFFEEF5FF),
                          border: const Color(0xFFBFD8FF),
                          text: const Color(0xFF2455D3),
                        ),
                        const SizedBox(height: 10),
                        _metricBox(
                          title: '${stats?.level ?? 1}',
                          subtitle: 'Current Level',
                          note: stats?.levelName ?? 'Achievement Rank',
                          background: const Color(0xFFF2F1FF),
                          border: const Color(0xFFD1CCFF),
                          text: const Color(0xFF4A3FD4),
                        ),
                        const SizedBox(height: 10),
                        _metricBox(
                          title: '${stats?.currentStreak ?? 0}',
                          subtitle: 'Current Streak',
                          note: 'Consecutive Days',
                          background: const Color(0xFFECF8FF),
                          border: const Color(0xFFB9E6FF),
                          text: const Color(0xFF136CA6),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricBox({
    required String title,
    required String subtitle,
    required String note,
    required Color background,
    required Color border,
    required Color text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: text,
              fontSize: 44 / 1.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: text, fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            note,
            style: TextStyle(color: text.withValues(alpha: 0.85), fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.points});

  final List<ActivityChartPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F6FC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No chart data yet',
          style: TextStyle(color: Color(0xFF7F90A8), fontWeight: FontWeight.w600),
        ),
      );
    }

    final sorted = List<ActivityChartPoint>.from(points)
      ..sort((a, b) => a.date.compareTo(b.date));
    final visible = sorted.length > 224 ? sorted.sublist(sorted.length - 224) : sorted;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visible.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 28,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        final intensity = visible[index].intensity.clamp(0, 4);
        return Container(
          decoration: BoxDecoration(
            color: _colorByIntensity(intensity),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      },
    );
  }

  Color _colorByIntensity(int intensity) {
    switch (intensity) {
      case 0:
        return const Color(0xFFE9EDF4);
      case 1:
        return const Color(0xFFBFD8FF);
      case 2:
        return const Color(0xFF8CB8FF);
      case 3:
        return const Color(0xFF5D8BFA);
      default:
        return const Color(0xFF3159DC);
    }
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    const colors = <Color>[
      Color(0xFFE9EDF4),
      Color(0xFFBFD8FF),
      Color(0xFF8CB8FF),
      Color(0xFF5D8BFA),
      Color(0xFF3159DC),
    ];
    return Row(
      children: colors
          .map(
            (color) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
