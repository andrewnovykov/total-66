import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/network/api_exception.dart';
import '../core/theme/app_theme.dart';
import '../models/category.dart';
import '../models/goal.dart';
import '../services/category_service.dart';
import '../services/goal_service.dart';
import 'goal_detail_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<Goal> _goals = const <Goal>[];
  List<Category> _categories = const <Category>[];
  bool _isLoading = true;
  String? _errorMessage;
  String _feedMode = 'trending';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadScreenData());
  }

  Future<void> _loadScreenData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final goalService = context.read<GoalService>();
      final categoryService = context.read<CategoryService>();

      final goals = await goalService.listPublicGoals(
        sort: _feedMode == 'trending' ? 'progress_desc' : 'created_desc',
      );
      final categories = await categoryService.listCategories();

      if (!mounted) return;
      setState(() {
        _goals = goals;
        _categories = categories;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load Home screen data';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<GoalCreator> get _topSetters {
    final seen = <int>{};
    final creators = <GoalCreator>[];
    for (final goal in _goals) {
      final creator = goal.creator;
      if (creator == null) continue;
      if (seen.add(creator.id)) {
        creators.add(creator);
      }
    }
    return creators.take(8).toList(growable: false);
  }

  List<Category> get _challengeCategories {
    return _categories.take(8).toList(growable: false);
  }

  Future<void> _switchFeed(String mode) async {
    if (_feedMode == mode) return;
    setState(() {
      _feedMode = mode;
    });
    await _loadScreenData();
  }

  void _openGoal(Goal goal) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GoalDetailScreen(goalId: goal.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _ErrorCard(message: _errorMessage!, onRetry: _loadScreenData);
    }

    return RefreshIndicator(
      onRefresh: _loadScreenData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          _HeroCard(
            onCreatePressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Use Create tab to make a goal')),
            ),
          ),
          const SizedBox(height: 18),
          _SectionHeader(title: 'Goal Categories', onViewAll: () {}),
          const SizedBox(height: 10),
          _HorizontalCategories(categories: _categories),
          const SizedBox(height: 18),
          _SectionHeader(title: 'Challenge Categories', onViewAll: () {}),
          const SizedBox(height: 10),
          _HorizontalChallengeCategories(categories: _challengeCategories),
          const SizedBox(height: 18),
          const Text(
            'Top Goal-Setters',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _TopSettersRow(setters: _topSetters),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Active Goals',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _FeedToggle(
                selected: _feedMode,
                onChanged: _switchFeed,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_goals.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No active goals yet'),
              ),
            )
          else
            ..._goals.map(
              (goal) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ActiveGoalCard(
                  goal: goal,
                  onOpen: () => _openGoal(goal),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onCreatePressed});

  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2F68E8), Color(0xFF5142E5)]),
        borderRadius: BorderRadius.circular(34),
      ),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
      child: Stack(
        children: [
          Positioned(
            right: 8,
            top: 68,
            child: Icon(
              Icons.star_border_rounded,
              size: 170,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'NEW CHALLENGE',
                  style: TextStyle(
                    color: Color(0xFFDCE5FF),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const SizedBox(
                width: 300,
                child: Text(
                  'Set fewer goals. Finish more.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 58 / 2,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const SizedBox(
                width: 310,
                child: Text(
                  'A goal-first social network with structure, accountability, and real progress.',
                  style: TextStyle(
                    color: Color(0xFFDCE5FF),
                    fontSize: 20 / 1.2,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2F68E8),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: onCreatePressed,
                child: const Text(
                  'Create Your Goal  →',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onViewAll});

  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          child: const Text(
            'View All',
            style: TextStyle(
              color: Color(0xFF2F68E8),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _HorizontalCategories extends StatelessWidget {
  const _HorizontalCategories({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length.clamp(0, 12).toInt(),
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = categories[index];
          return Container(
            width: 240,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.local_fire_department, color: Color(0xFF3D6BF0)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF283548),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HorizontalChallengeCategories extends StatelessWidget {
  const _HorizontalChallengeCategories({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length.clamp(0, 10).toInt(),
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = categories[index];
          return Container(
            width: index == 0 ? 130 : 250,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.local_fire_department, color: Color(0xFF3D6BF0)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    index == 0 ? '30n' : 'Seed Challenge ${item.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF283548),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopSettersRow extends StatelessWidget {
  const _TopSettersRow({required this.setters});

  final List<GoalCreator> setters;

  String _initial(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'U';
    return text.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (setters.isEmpty) {
      return const Text('No top setters yet');
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: setters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final setter = setters[index];
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF3D6BF0),
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: const Color(0xFFFFE7D4),
                  foregroundImage:
                      setter.imagePath == null ? null : NetworkImage(setter.imagePath!),
                  child: setter.imagePath == null
                      ? Text(
                          _initial(setter.name),
                          style: const TextStyle(
                            color: Color(0xFF353535),
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 90,
                child: Text(
                  setter.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FeedToggle extends StatelessWidget {
  const _FeedToggle({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _toggleButton(
          text: 'Trending',
          isSelected: selected == 'trending',
          onTap: () => onChanged('trending'),
        ),
        const SizedBox(width: 8),
        _toggleButton(
          text: 'Recent',
          isSelected: selected == 'recent',
          onTap: () => onChanged('recent'),
        ),
      ],
    );
  }

  Widget _toggleButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0E1A3A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF6D7B93),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ActiveGoalCard extends StatelessWidget {
  const _ActiveGoalCard({required this.goal, required this.onOpen});

  final Goal goal;
  final VoidCallback onOpen;

  String _initials(String text) {
    final value = text.trim();
    if (value.isEmpty) return 'U';
    final parts = value.split(' ').where((part) => part.isNotEmpty).toList(growable: false);
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final status = goal.status.toLowerCase();
    final isActive = status == 'active';
    final isFailed = status == 'failed';
    final statusLabel = status.isEmpty ? 'Unknown' : status[0].toUpperCase() + status.substring(1);
    final badgeColor = isFailed
        ? const Color(0xFFF04438)
        : isActive
            ? const Color(0xFF22C55E)
            : const Color(0xFF6D7B93);
    final badgeBg = isFailed ? const Color(0xFFFFE9E7) : const Color(0xFFE8F7ED);

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(34),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFF6D8C4),
                  foregroundImage: goal.creator?.imagePath == null
                      ? null
                      : NetworkImage(goal.creator!.imagePath!),
                  child: goal.creator?.imagePath == null
                      ? Text(
                          _initials(goal.creator?.name ?? 'U'),
                          style: const TextStyle(
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.creator?.name ?? 'Unknown User',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        goal.category?.name ?? 'General',
                        style: const TextStyle(
                          color: Color(0xFF8A9AB2),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: badgeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              goal.title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 23,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              goal.description ?? 'No description',
              style: const TextStyle(
                color: Color(0xFF4B5C77),
                fontSize: 17,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            _PosterPreview(imagePath: goal.imagePath),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  'Goal Progress',
                  style: TextStyle(
                    color: Color(0xFF6D7B93),
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const Spacer(),
                Text(
                  '${goal.progress}%',
                  style: const TextStyle(
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: (goal.progress.clamp(0, 100)) / 100,
                backgroundColor: const Color(0xFFE8EDF6),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF585EEB)),
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _engageItem(Icons.favorite_border, '${goal.likesCount} likes', const Color(0xFFFF5DA9)),
                _engageItem(Icons.remove_red_eye_outlined, '${goal.subscribersCount} subscribers', const Color(0xFF4C9EFF)),
                _engageItem(Icons.chat_bubble_outline, '${goal.postsCount} posts', const Color(0xFF95A3B8)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _engageItem(IconData icon, String label, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 21, color: iconColor),
        const SizedBox(width: 7),
        Text(
          label,
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

class _PosterPreview extends StatelessWidget {
  const _PosterPreview({this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    if (imagePath != null && imagePath!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 2.1,
          child: Image.network(
            imagePath!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _fallbackPoster(),
          ),
        ),
      );
    }

    return _fallbackPoster();
  }

  Widget _fallbackPoster() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9AF45A), Color(0xFF15181F), Color(0xFF15181F)],
          stops: [0, 0.33, 1],
        ),
      ),
      child: Stack(
        children: const [
          Positioned(
            left: 24,
            top: 24,
            child: Text(
              'FUTURE YOU',
              style: TextStyle(
                color: Color(0xFF9AF45A),
                fontWeight: FontWeight.w800,
                fontSize: 22 / 1.2,
              ),
            ),
          ),
          Positioned(
            left: 24,
            top: 58,
            right: 20,
            child: Text(
              'SET YOUR GOALS AND\nSTART YOUR JOURNEY',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 34 / 2,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(height: 10),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
