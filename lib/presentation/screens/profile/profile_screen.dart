import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/enums.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/user_progress.dart';
import '../../../domain/providers/repository_providers.dart';
import '../../screens/analytics/analytics_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/pro/pro_upgrade_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  UserProgress? _progress;
  List<Achievement> _achievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userProgressRepo = ref.read(userProgressRepositoryProvider);
      final achievementRepo = ref.read(achievementRepositoryProvider);
      _progress = await userProgressRepo.getUserProgress('default');
      _achievements = await achievementRepo.getAchievements('default');
    } catch (e) {
      // Handle error
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final level = _progress != null
        ? UserLevel.fromPoints(_progress!.totalPoints)
        : UserLevel.novice;
    final stage = _progress != null
        ? LearningStage.values.firstWhere(
            (s) => s.value == _progress!.currentStage,
            orElse: () => LearningStage.stage1)
        : LearningStage.stage1;

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar and level
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Пользователь',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${level.label} (${_progress?.totalPoints ?? 0} XP)',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStat(
                          theme,
                          '${_progress?.tasksCompleted ?? 0}',
                          'Задач выполнено',
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: theme.dividerColor,
                      ),
                      Expanded(
                        child: _buildStat(
                          theme,
                          '${_progress?.focusTimeTotalMinutes ?? 0}',
                          'Фокус (мин)',
                          Icons.timer,
                          Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStat(
                          theme,
                          '${_progress?.currentStreakDays ?? 0}',
                          'Дней подряд',
                          Icons.local_fire_department,
                          Colors.orange,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: theme.dividerColor,
                      ),
                      Expanded(
                        child: _buildStat(
                          theme,
                          stage.label,
                          'Стадия обучения',
                          Icons.school,
                          Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Achievements
          Text(
            'Достижения',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._achievements.map((a) => _buildAchievementCard(theme, a)),

          // Quick actions
          const SizedBox(height: 24),
          Text(
            'Быстрые действия',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            theme,
            Icons.analytics,
            'Аналитика',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
            ),
          ),
          _buildActionButton(
            theme,
            Icons.settings,
            'Настройки',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          _buildActionButton(
            theme,
            Icons.star,
            'AI-Ментор Pro',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProUpgradeScreen()),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStat(ThemeData theme, String value, String label,
      IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(ThemeData theme, Achievement a) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          a.unlockedAt != null ? Icons.emoji_events : Icons.lock_outline,
          color: a.unlockedAt != null ? Colors.amber : Colors.grey,
        ),
        title: Text(a.title),
        subtitle: Text(a.description ?? ''),
        trailing: a.unlockedAt != null
            ? Text(
                AppDateUtils.formatDate(a.unlockedAt!),
                style: theme.textTheme.labelSmall,
              )
            : null,
      ),
    );
  }

  Widget _buildActionButton(
      ThemeData theme, IconData icon, String label, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
