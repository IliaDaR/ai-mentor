import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/enums.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/task.dart';
import '../../../data/models/user_progress.dart';
import '../../../domain/services/gamification_service.dart';
import '../../../domain/providers/service_providers.dart';
import '../../../domain/providers/repository_providers.dart';
import 'daily_plan_screen.dart';
import '../task/task_list_screen.dart';
import '../task/task_create_screen.dart';
import '../inbox/inbox_screen.dart';
import '../meeting/meeting_recorder_screen.dart';
import '../focus/focus_screen.dart';
import '../debrief/debrief_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  UserProgress? _progress;
  List<Task> _todayTasks = [];
  List<Task> _focusTasks = [];
  int _inboxCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userProgressRepo = ref.read(userProgressRepositoryProvider);
      final taskRepo = ref.read(taskRepositoryProvider);
      final sourceRepo = ref.read(sourceRepositoryProvider);
      final gamification = ref.read(gamificationServiceProvider);

      _progress = await userProgressRepo.getUserProgress('default');
      final tasks = await taskRepo.getTasks(onlyToday: true);
      _todayTasks = tasks.where((t) => t.status != 'completed').toList();
      _focusTasks = tasks
          .where((t) =>
              t.status != 'completed' &&
              t.quadrant == TaskQuadrant.urgentImportant.value)
          .toList();
      _inboxCount = (await sourceRepo.getSources(isSpam: false)).length;

      await gamification.updateStreak();
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

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome header
          _buildWelcomeHeader(theme),
          const SizedBox(height: 16),

          // Streak & Stats
          _buildStatsRow(theme),
          const SizedBox(height: 16),

          // Quick actions
          _buildQuickActions(theme),
          const SizedBox(height: 16),

          // Daily plan button
          _buildDailyPlanCard(theme),
          const SizedBox(height: 16),

          // Focus tasks
          if (_focusTasks.isNotEmpty) ...[
            _buildSectionTitle(theme, 'Приоритетные задачи', Icons.priority_high),
            const SizedBox(height: 8),
            ..._focusTasks.take(3).map((task) => _buildTaskCard(theme, task)),
            const SizedBox(height: 16),
          ],

          // Today's tasks
          if (_todayTasks.isNotEmpty) ...[
            _buildSectionTitle(theme, 'Задачи на сегодня', Icons.today),
            const SizedBox(height: 8),
            ..._todayTasks.take(5).map((task) => _buildTaskCard(theme, task)),
            const SizedBox(height: 16),
          ],

          // Inbox count
          if (_inboxCount > 0)
            _buildInboxBanner(theme),

          // Focus mode
          _buildFocusCard(theme),

          const SizedBox(height: 16),

          // Daily debrief
          _buildDebriefCard(theme),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(ThemeData theme) {
    final level = _progress != null
        ? UserLevel.fromPoints(_progress!.totalPoints)
        : UserLevel.novice;
    final stage = _progress != null
        ? LearningStage.values.firstWhere(
            (s) => s.value == _progress!.currentStage,
            orElse: () => LearningStage.stage1)
        : LearningStage.stage1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                level.label.split(' ').first,
                style: TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Доброе утро!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${level.label} • Этап: ${stage.label}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: _progress != null
                        ? GamificationService.getProgressToNextLevel(
                                _progress!.totalPoints) /
                            100
                        : 0,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_progress?.totalPoints ?? 0} баллов',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            Icons.local_fire_department,
            'Стрик',
            '${_progress?.currentStreakDays ?? 0} дн',
            Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            theme,
            Icons.check_circle_outline,
            'Выполнено',
            '${_progress?.tasksCompleted ?? 0}',
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            theme,
            Icons.timer_outlined,
            'Фокус',
            AppDateUtils.formatDuration(
                _progress?.focusTimeTotalMinutes ?? 0),
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      ThemeData theme, IconData icon, String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            theme,
            Icons.add_task,
            'Новая задача',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TaskCreateScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            theme,
            Icons.mic,
            'Запись',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MeetingRecorderScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            theme,
            Icons.list_alt,
            'Задачи',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TaskListScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      ThemeData theme, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(ThemeData theme, Task task) {
    final quadrant = TaskQuadrant.values.firstWhere(
      (q) => q.value == task.quadrant,
      orElse: () => TaskQuadrant.notUrgentNotImportant,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 4,
          height: 48,
          decoration: BoxDecoration(
            color: Color(quadrant.color),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          task.title,
          style: theme.textTheme.bodyMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: task.deadline != null
            ? Text(
                'Дедлайн: ${AppDateUtils.formatDate(task.deadline!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppDateUtils.isOverdue(task.deadline)
                      ? Colors.red
                      : theme.colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: Checkbox(
          value: task.status == 'completed',
          onChanged: (_) async {
            final taskRepo = ref.read(taskRepositoryProvider);
            await taskRepo.updateTask(
              task.copyWith(
                status: 'completed',
                completedAt: DateTime.now(),
              ),
            );
            _loadData();
          },
        ),
        onTap: () {
          // Open task detail
        },
      ),
    );
  }

  Widget _buildDailyPlanCard(ThemeData theme) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const DailyPlanScreen(),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'План на день',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ИИ составит оптимальный план\nс учётом ваших задач и приоритетов',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInboxBanner(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: theme.colorScheme.secondaryContainer,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const InboxScreen(),
            ),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.inbox,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$_inboxCount новых входящих',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFocusCard(ThemeData theme) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const FocusScreen(),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.self_improvement, color: Colors.deepPurple),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Режим Монах',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Глубокая работа без отвлечений',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebriefCard(ThemeData theme) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const DebriefScreen(),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.analytics, color: Colors.teal),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Разбор дня',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Вечерний анализ и рекомендации ИИ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
