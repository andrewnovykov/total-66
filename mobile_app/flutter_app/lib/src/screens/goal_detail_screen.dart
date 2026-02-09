import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/network/api_exception.dart';
import '../core/theme/app_theme.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';

class GoalDetailScreen extends StatefulWidget {
  const GoalDetailScreen({super.key, required this.goalId});

  final int goalId;

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  Goal? _goal;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGoal());
  }

  Future<void> _loadGoal() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final goal = await context.read<GoalService>().getGoal(widget.goalId);
      if (!mounted) return;
      setState(() {
        _goal = goal;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load goal details';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _ErrorCard(message: _errorMessage!, onRetry: _loadGoal)
                : _goal == null
                    ? const Center(child: Text('Goal not found'))
                    : RefreshIndicator(
                        onRefresh: _loadGoal,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 30),
                          children: [
                            _GoalHero(goal: _goal!),
                            const SizedBox(height: 14),
                            _ProgressCard(progress: _goal!.progress),
                            const SizedBox(height: 14),
                            _AboutCard(goal: _goal!),
                            const SizedBox(height: 14),
                            _StepsCard(steps: _goal!.steps),
                            const SizedBox(height: 14),
                            const Text(
                              'Goal Feed',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 28 / 1.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_goal!.recentPosts.isEmpty)
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text('No feed posts yet'),
                                ),
                              )
                            else
                              ..._goal!.recentPosts.map(
                                (post) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _GoalPostCard(post: post),
                                ),
                              ),
                          ],
                        ),
                      ),
      ),
    );
  }
}

class _GoalHero extends StatelessWidget {
  const _GoalHero({required this.goal});

  final Goal goal;

  String _statusLabel(String raw) {
    if (raw.isEmpty) return 'Unknown';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  String _privacyLabel(String raw) {
    if (raw == 'friends') return 'Friends';
    if (raw == 'private') return 'Private';
    return 'Public';
  }

  @override
  Widget build(BuildContext context) {
    final categoryName = goal.category?.name ?? 'General';
    final statusRaw = goal.status.toLowerCase();
    final statusLabel = _statusLabel(goal.status);
    final statusBackgroundColor = statusRaw == 'failed'
        ? const Color(0xFFFFE9E7)
        : const Color(0xFFEAF7EE);
    final statusDotColor = statusRaw == 'failed'
        ? const Color(0xFFF04438)
        : statusRaw == 'active'
            ? const Color(0xFF22C55E)
            : const Color(0xFF64748B);
    final statusTextColor = statusRaw == 'failed'
        ? const Color(0xFFF04438)
        : statusRaw == 'active'
            ? const Color(0xFF16A34A)
            : const Color(0xFF475569);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F68E8), Color(0xFF5142E5)],
        ),
        borderRadius: BorderRadius.circular(34),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Stack(
        children: [
          Positioned(
            right: 6,
            top: 90,
            child: Icon(
              Icons.flag_outlined,
              size: 170,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFFCCDAFF), size: 25),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFCCDAFF),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _GoalMiniPoster(imagePath: goal.imagePath),
              const SizedBox(height: 16),
              Text(
                goal.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 50 / 2,
                  fontWeight: FontWeight.w800,
                  height: 1.22,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _statusChip(
                    statusLabel,
                    backgroundColor: statusBackgroundColor,
                    dotColor: statusDotColor,
                    textColor: statusTextColor,
                  ),
                  _infoChip(icon: Icons.public, text: _privacyLabel(goal.privacy)),
                  _infoChip(icon: Icons.sell_outlined, text: categoryName),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  _statItem(Icons.favorite_border, '${goal.likesCount} likes'),
                  _statItem(Icons.remove_red_eye_outlined, '${goal.subscribersCount} subscribers'),
                  _statItem(Icons.chat_bubble_outline, '${goal.postsCount} post${goal.postsCount == 1 ? '' : 's'}'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(
    String text, {
    required Color backgroundColor,
    required Color dotColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFDDE6FF)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFDDE6FF),
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFDCE5FF), size: 21),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFFDCE5FF),
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _GoalMiniPoster extends StatelessWidget {
  const _GoalMiniPoster({this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 165,
      height: 112,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x99BFD3FF), width: 4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: imagePath != null && imagePath!.trim().isNotEmpty
            ? Image.network(
                imagePath!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9AF45A), Color(0xFF15181F), Color(0xFF15181F)],
          stops: [0, 0.33, 1],
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(10),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Text(
            'SET YOUR GOALS\nSTART YOUR JOURNEY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16 / 1.3,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0, 100) / 100;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
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
                  '$progress%',
                  style: const TextStyle(
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 13,
                value: value,
                backgroundColor: const Color(0xFFE6EBF4),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF5D63EA)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final short = (goal.description ?? '').trim();
    final detailed = (goal.bigDescription ?? '').trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About This Goal',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 26 / 1.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              short.isEmpty ? 'No short description.' : short,
              style: const TextStyle(
                color: Color(0xFF4E5E77),
                fontSize: 17,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              detailed.isEmpty ? 'No detailed description yet.' : detailed,
              style: TextStyle(
                color: detailed.isEmpty ? const Color(0xFFA1AEC3) : const Color(0xFF5D6D84),
                fontSize: 17,
                height: 1.45,
                fontWeight: FontWeight.w500,
                fontStyle: detailed.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  const _StepsCard({required this.steps});

  final List<GoalStep> steps;

  @override
  Widget build(BuildContext context) {
    final completed = steps.where((step) => step.completed).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Goal Steps',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26 / 1.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '$completed/${steps.length} completed',
                  style: const TextStyle(
                    color: Color(0xFF8EA0BB),
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (steps.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAF0F8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.content_paste_outlined, color: Color(0xFF9AAAC1), size: 38),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'No steps yet',
                        style: TextStyle(
                          color: Color(0xFF8FA0BA),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...steps.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(
                        step.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                        color: step.completed ? const Color(0xFF22C55E) : const Color(0xFFA0AFC4),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          step.title,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            decoration: step.completed ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GoalPostCard extends StatelessWidget {
  const _GoalPostCard({required this.post});

  final GoalPost post;

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    final month = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][local.month - 1];
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    return '$month ${local.day.toString().padLeft(2, '0')} at $hour:$minute $ampm';
  }

  String _label(String raw) {
    if (raw.isEmpty) return 'Update';
    final words = raw.split('_');
    return words
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final author = post.author;
    final authorName = author?.name.isNotEmpty == true ? author!.name : 'Unknown User';
    final initials = authorName.isEmpty ? 'U' : authorName.substring(0, 1).toUpperCase();
    final label = _label(post.postType);
    final isMilestone = post.postType.toLowerCase() == 'milestone';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFF6D8C4),
                  foregroundImage: author?.imagePath == null ? null : NetworkImage(author!.imagePath!),
                  child: author?.imagePath == null
                      ? Text(
                          initials,
                          style: const TextStyle(
                            color: Color(0xFF324259),
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
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
                        authorName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22 / 1.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isMilestone ? const Color(0xFFE8F7ED) : const Color(0xFFEAF0FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                color: isMilestone ? const Color(0xFF16A34A) : const Color(0xFF3D6BF0),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _formatDate(post.createdAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF8EA0BB),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              post.content.isEmpty ? 'No content.' : post.content,
              style: const TextStyle(
                color: Color(0xFF3C4C65),
                fontSize: 17,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
            if (post.imagePath != null && post.imagePath!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 1.9,
                  child: Image.network(
                    post.imagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.favorite, color: Color(0xFFEF4444), size: 24),
                SizedBox(width: 8),
                Text(
                  '0',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                SizedBox(width: 24),
                Icon(Icons.chat_bubble_outline, color: Color(0xFF8EA0BB), size: 24),
                SizedBox(width: 8),
                Text(
                  '0 comments',
                  style: TextStyle(
                    color: Color(0xFF8EA0BB),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
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
