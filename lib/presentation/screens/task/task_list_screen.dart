import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/enums.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/task.dart';
import '../../../domain/providers/repository_providers.dart';
import 'task_detail_screen.dart';
import 'task_create_screen.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  String _currentFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final taskRepo = ref.read(taskRepositoryProvider);
      if (_currentFilter == 'all') {
        _tasks = await taskRepo.getTasks();
      } else {
        _tasks = await taskRepo.getTasksByQuadrant(_currentFilter);
      }
    } catch (e) {
      // Handle error
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Color _getQuadrantColor(String quadrant) {
    final q = TaskQuadrant.values.firstWhere(
      (q) => q.value == quadrant,
      orElse: () => TaskQuadrant.notUrgentNotImportant,
    );
    return Color(q.color);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Все задачи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TaskCreateScreen()),
              );
              _loadTasks();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quadrant filter chips
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('all', 'Все', Colors.grey),
                const SizedBox(width: 8),
                _buildFilterChip(
                  TaskQuadrant.urgentImportant.value,
                  TaskQuadrant.urgentImportant.label,
                  Color(TaskQuadrant.urgentImportant.color),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  TaskQuadrant.importantNotUrgent.value,
                  TaskQuadrant.importantNotUrgent.label,
                  Color(TaskQuadrant.importantNotUrgent.color),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  TaskQuadrant.urgentNotImportant.value,
                  TaskQuadrant.urgentNotImportant.label,
                  Color(TaskQuadrant.urgentNotImportant.color),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  TaskQuadrant.notUrgentNotImportant.value,
                  TaskQuadrant.notUrgentNotImportant.label,
                  Color(TaskQuadrant.notUrgentNotImportant.color),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Task list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.task_alt,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Нет задач',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const TaskCreateScreen()),
                                );
                                _loadTasks();
                              },
                              child: const Text('Создать задачу'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTasks,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) =>
                              _buildTaskItem(_tasks[index], theme),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, Color color) {
    final isSelected = _currentFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _currentFilter = value;
        });
        _loadTasks();
      },
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      avatar: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildTaskItem(Task task, ThemeData theme) {
    final color = _getQuadrantColor(task.quadrant);
    final isCompleted = task.status == 'completed';
    final taskRepo = ref.read(taskRepositoryProvider);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(task: task),
            ),
          );
          _loadTasks();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Quadrant indicator
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.grey : color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Checkbox
              Checkbox(
                value: isCompleted,
                onChanged: (_) async {
                  await taskRepo.updateTask(
                    task.copyWith(
                      status: isCompleted ? 'pending' : 'completed',
                      completedAt: isCompleted ? null : DateTime.now(),
                    ),
                  );
                  _loadTasks();
                },
              ),
              const SizedBox(width: 8),
              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                        color:
                            isCompleted ? Colors.grey : theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildTag(
                            quadrantLabel(task.quadrant), color.withOpacity(0.1), color),
                        if (task.deadline != null) ...[
                          const SizedBox(width: 8),
                          _buildTag(
                            AppDateUtils.formatDate(task.deadline!),
                            AppDateUtils.isOverdue(task.deadline)
                                ? Colors.red.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            AppDateUtils.isOverdue(task.deadline)
                                ? Colors.red
                                : Colors.blue,
                          ),
                        ],
                        if (task.isSmartCompliant) ...[
                          const SizedBox(width: 8),
                          _buildTag(
                            'SMART',
                            Colors.green.withOpacity(0.1),
                            Colors.green,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Priority
              if (task.priority <= 2)
                Icon(Icons.flag, color: Colors.red, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w500),
      ),
    );
  }

  String quadrantLabel(String quadrant) {
    final q = TaskQuadrant.values.firstWhere(
      (q) => q.value == quadrant,
      orElse: () => TaskQuadrant.notUrgentNotImportant,
    );
    return q.label;
  }
}
