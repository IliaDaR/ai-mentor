import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/database/database_helper.dart';
import '../../../data/models/task.dart';
import '../../../data/models/user_progress.dart';
import '../../../domain/providers/service_providers.dart';
import '../../../domain/providers/repository_providers.dart';

class DebriefScreen extends ConsumerStatefulWidget {
  const DebriefScreen({super.key});

  @override
  ConsumerState<DebriefScreen> createState() => _DebriefScreenState();
}

class _DebriefScreenState extends ConsumerState<DebriefScreen> {
  Map<String, dynamic>? _debrief;
  bool _isLoading = false;
  bool _isDone = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Разбор дня'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily stats
            _buildDailyStats(theme),

            const SizedBox(height: 16),

            // Debrief button
            if (!_isDone)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _doDebrief,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                      _isLoading ? 'Анализ...' : 'Провести разбор дня'),
                ),
              ),

            if (_debrief != null) ...[
              const SizedBox(height: 24),
              _buildDebriefResult(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDailyStats(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статистика за сегодня',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCircle(theme, 'Выполнено', '0', Colors.green),
                const SizedBox(width: 8),
                _buildStatCircle(
                    theme, 'Перенесено', '0', Colors.orange),
                const SizedBox(width: 8),
                _buildStatCircle(theme, 'Пропущено', '0', Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow(
                Icons.timer_outlined, 'Время фокуса', '0 мин', Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCircle(
      ThemeData theme, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _buildStatRow(
      IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _doDebrief() async {
    setState(() => _isLoading = true);

    try {
      final taskRepo = ref.read(taskRepositoryProvider);
      final aiService = ref.read(aiServiceProvider);

      final tasks = await taskRepo.getTasks();
      final done = tasks.where((t) => t.status == 'completed').length;
      final postponed = tasks
          .where((t) =>
              t.status == 'pending' &&
              t.deadline != null &&
              AppDateUtils.isOverdue(t.deadline))
          .length;

      // Use AI to debrief
      try {
        final result = await aiService.dailyDebrief(
          planned: tasks.length,
          done: done,
          postponed: postponed,
          missed: tasks.length - done - postponed,
          focusMinutes: 0,
          emailsProcessed: 0,
          meetingsCount: 0,
          tasksList: tasks.take(5).map((t) => t.title).join('\n'),
          focusHistory: '',
          mistakesToday: '',
          userLevel: 'novice',
          learningStage: 'stage1',
        );
        setState(() => _debrief = result);
      } catch (e) {
        // Fallback debrief
        setState(() {
          _debrief = {
            'summary': 'День прошёл продуктивно!',
            'good': 'Ты выполнил $done задач — продолжай в том же духе',
            'improve': 'Попробуй завтра начать с самой сложной задачи',
            'exercise': 'Техника "Помидора": 25 мин работы, 5 мин отдыха',
            'plan_tomorrow': ['Главная задача', 'Вторая задача', 'Третья задача'],
            'points_earned': done * 10,
          };
        });
      }

      _isDone = true;
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDebriefResult(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text(
                      'Итог дня',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _debrief!['summary'] as String? ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Good
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Что получилось',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_debrief!['good'] as String? ?? ''),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Improve
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.trending_up, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Что улучшить',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_debrief!['improve'] as String? ?? ''),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Exercise
        Card(
          color: Colors.amber.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.fitness_center, color: Colors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Упражнение на завтра',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_debrief!['exercise'] as String? ?? ''),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Plan for tomorrow
        if (_debrief!['plan_tomorrow'] != null) ...[
          Text(
            'План на завтра',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...(_debrief!['plan_tomorrow'] as List).take(5).map(
                (item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        '${(_debrief!['plan_tomorrow'] as List).indexOf(item) + 1}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    title: Text(item.toString()),
                  ),
                ),
              ),
        ],

        // Points earned
        if (_debrief!['points_earned'] != null) ...[
          const SizedBox(height: 16),
          Center(
            child: Chip(
              avatar: const Icon(Icons.star, color: Colors.amber),
              label: Text('+${_debrief!['points_earned']} баллов'),
              backgroundColor: Colors.amber.withOpacity(0.1),
            ),
          ),
        ],
      ],
    );
  }
}
