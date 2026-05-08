import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/enums.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/task.dart';
import '../../../data/models/user_progress.dart';
import '../../../domain/providers/service_providers.dart';
import '../../../domain/providers/repository_providers.dart';
import '../focus/focus_screen.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  late Task _task;
  bool _showExplanation = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  Color _getQuadrantColor() {
    final q = TaskQuadrant.values.firstWhere(
      (q) => q.value == _task.quadrant,
      orElse: () => TaskQuadrant.notUrgentNotImportant,
    );
    return Color(q.color);
  }

  Future<void> _toggleStatus() async {
    final isCompleted = _task.status == 'completed';
    final updated = _task.copyWith(
      status: isCompleted ? 'pending' : 'completed',
      completedAt: isCompleted ? null : DateTime.now(),
    );
    final taskRepo = ref.read(taskRepositoryProvider);
    await taskRepo.updateTask(updated);
    setState(() => _task = updated);

    if (!isCompleted) {
      // Add points
      final gamificationService = ref.read(gamificationServiceProvider);
      await gamificationService.addPoints('task_completed', 10);

      // Update progress
      final userProgressRepo = ref.read(userProgressRepositoryProvider);
      final progress = await userProgressRepo.getUserProgress('default');
      if (progress != null) {
        await userProgressRepo.insertOrUpdateUserProgress(
          progress.copyWith(tasksCompleted: progress.tasksCompleted + 1),
        );
      }
    }
  }

  void _startFocus() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FocusScreen(
          initialTaskId: _task.id,
          initialTaskTitle: _task.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getQuadrantColor();
    final isCompleted = _task.status == 'completed';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Задача'),
        actions: [
          IconButton(
            icon: Icon(isCompleted ? Icons.undo : Icons.check_circle_outline),
            onPressed: _toggleStatus,
            tooltip: isCompleted ? 'Отменить выполнение' : 'Завершить задачу',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Удалить задачу?'),
                  content: const Text('Это действие нельзя отменить'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Удалить'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                final taskRepo = ref.read(taskRepositoryProvider);
                await taskRepo.deleteTask(_task.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status & Quadrant
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    TaskQuadrant.values
                        .firstWhere((q) => q.value == _task.quadrant)
                        .label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_task.isSmartCompliant)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'SMART',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                const Spacer(),
                if (_task.priority <= 2)
                  Icon(Icons.flag, color: Colors.red, size: 20),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              _task.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_task.description != null && _task.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _task.description!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Info cards
            _buildInfoRow(theme, Icons.access_time, 'Создано',
                AppDateUtils.formatDateTime(_task.createdAt)),
            if (_task.deadline != null)
              _buildInfoRow(
                theme,
                Icons.event,
                'Дедлайн',
                AppDateUtils.formatDate(_task.deadline!),
                valueColor: AppDateUtils.isOverdue(_task.deadline)
                    ? Colors.red
                    : null,
              ),
            if (_task.estimatedTimeMinutes != null)
              _buildInfoRow(
                theme,
                Icons.timer_outlined,
                'Оценка времени',
                AppDateUtils.formatDuration(_task.estimatedTimeMinutes!),
              ),
            if (_task.timeBlockStart != null)
              _buildInfoRow(
                theme,
                Icons.schedule,
                'Временной блок',
                '${AppDateUtils.formatTime(_task.timeBlockStart!)} - ${_task.timeBlockEnd != null ? AppDateUtils.formatTime(_task.timeBlockEnd!) : '...'}',
              ),
            if (_task.delegatedTo != null)
              _buildInfoRow(
                theme,
                Icons.person_outline,
                'Делегировано',
                _task.delegatedTo!,
              ),
            if (_task.tags != null && _task.tags!.isNotEmpty)
              _buildInfoRow(theme, Icons.label_outline, 'Теги', _task.tags!),
            const SizedBox(height: 24),

            // AI Explanation
            if (_task.aiExplanation != null) ...[
              InkWell(
                onTap: () => setState(() => _showExplanation = !_showExplanation),
                child: Card(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            color: theme.colorScheme.primary,
                            size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Объяснение ИИ',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _showExplanation
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_showExplanation) ...[
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _task.aiExplanation!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],

            // Focus button
            if (!isCompleted) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startFocus,
                  icon: const Icon(Icons.self_improvement),
                  label: const Text('Фокус на этой задаче'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, IconData icon, String label,
      String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
