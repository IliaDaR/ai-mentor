import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/enums.dart';
import '../../../domain/providers/service_providers.dart';
import '../../../domain/providers/repository_providers.dart';
import '../../../data/models/task.dart';
import '../../../core/utils/logger.dart';

class DailyPlanScreen extends ConsumerStatefulWidget {
  const DailyPlanScreen({super.key});

  @override
  ConsumerState<DailyPlanScreen> createState() => _DailyPlanScreenState();
}

class _DailyPlanScreenState extends ConsumerState<DailyPlanScreen> {
  AIPlan? _plan;
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generatePlan();
  }

  Future<void> _generatePlan() async {
    setState(() {
      _isLoading = true;
      _isGenerating = true;
      _error = null;
    });

    try {
      final taskRepo = ref.read(taskRepositoryProvider);
      final sourceRepo = ref.read(sourceRepositoryProvider);
      final aiService = ref.read(aiServiceProvider);

      final yesterdayTasks = await taskRepo.getTasksByStatus('pending');
      final emails = await sourceRepo.getSources(isSpam: false);

      final plan = await aiService.generateDailyPlan(
        yesterdayTasks: yesterdayTasks,
        emails: [],
        notifications: [],
        meetings: [],
        userLevel: 'novice',
        learningStage: 'stage1',
        productiveHours: '09:00-12:00, 14:00-18:00',
        commonMistakes: '',
      );

      setState(() {
        _plan = plan;
        _isLoading = false;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось сгенерировать план: $e';
        _isLoading = false;
        _isGenerating = false;
      });
    }
  }

  Future<void> _acceptPlan() async {
    if (_plan == null) return;

    final taskRepo = ref.read(taskRepositoryProvider);

    for (final item in _plan!.plan) {
      final task = Task(
        id: '${DateTime.now().millisecondsSinceEpoch}_${item.title.hashCode}',
        title: item.title,
        quadrant: item.quadrant,
        priority: 1,
        status: 'pending',
        source: 'ai',
        createdAt: DateTime.now(),
        aiExplanation: item.explanation,
        learningStage: 'stage1',
        userId: 'default',
      );
      await taskRepo.insertTask(task);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('План принят! Добавлено ${_plan!.plan.length} задач'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('План на день'),
        actions: [
          if (_plan != null)
            TextButton(
              onPressed: _acceptPlan,
              child: const Text('Принять'),
            ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('ИИ анализирует ваши задачи...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generatePlan,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_plan == null) {
      return const Center(child: Text('Нет данных'));
    }

    return RefreshIndicator(
      onRefresh: _generatePlan,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Strategy
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb,
                          color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Text(
                        'Стратегия дня',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _plan!.overallStrategy,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Learning tip
          if (_plan!.learningTip.isNotEmpty)
            Card(
              color: Colors.amber.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.school, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _plan!.learningTip,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Plan items
          Text(
            'Рекомендованный порядок задач',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...(_plan!.plan.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildPlanItem(theme, index, item);
          })),

          // Accept button
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _acceptPlan,
            icon: const Icon(Icons.check),
            label: const Text('Принять план и создать задачи'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPlanItem(ThemeData theme, int index, AIPlanItem item) {
    final quadrant = TaskQuadrant.values.firstWhere(
      (q) => q.value == item.quadrant,
      orElse: () => TaskQuadrant.importantNotUrgent,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Number and quadrant
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(quadrant.color),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(quadrant.color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    quadrant.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(quadrant.color),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                if (item.timeBlock.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.access_time, size: 14),
                    label: Text(
                      item.timeBlock,
                      style: const TextStyle(fontSize: 11),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              item.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Explanation
            Text(
              item.explanation,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),

            // Why this quadrant
            Row(
              children: [
                Icon(Icons.help_outline,
                    size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.quadrantReason,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),

            // Learning point
            if (item.learningPoint.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.school,
                      size: 14, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '💡 ${item.learningPoint}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
