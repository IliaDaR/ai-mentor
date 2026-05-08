import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/enums.dart';
import '../../../data/models/task.dart';
import '../../../domain/providers/service_providers.dart';
import '../../../domain/providers/repository_providers.dart';
import '../../../core/utils/logger.dart';

class TaskCreateScreen extends ConsumerStatefulWidget {
  const TaskCreateScreen({super.key});

  @override
  ConsumerState<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends ConsumerState<TaskCreateScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedQuadrant = TaskQuadrant.importantNotUrgent.value;
  int _priority = 3;
  DateTime? _deadline;
  int? _estimatedMinutes;
  String _delegatedTo = '';
  String _tags = '';

  bool _isSmartChecking = false;
  SmartCheckResult? _smartResult;
  String? _selectedImprovedVersion;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _checkSmart() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _isSmartChecking = true);

    try {
      final aiService = ref.read(aiServiceProvider);
      final result = await aiService.checkSmart(
        title: _titleController.text,
        description: _descriptionController.text,
        quadrant: _selectedQuadrant,
        deadline: _deadline,
        userLevel: 'novice',
      );
      setState(() {
        _smartResult = result;
        _selectedImprovedVersion = result.improvedVersion;
        _isSmartChecking = false;
      });
    } catch (e) {
      setState(() => _isSmartChecking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка проверки: $e')),
        );
      }
    }
  }

  Future<void> _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название задачи')),
      );
      return;
    }

    final title = _selectedImprovedVersion ?? _titleController.text.trim();

    final task = Task(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      quadrant: _selectedQuadrant,
      priority: _priority,
      deadline: _deadline,
      estimatedTimeMinutes: _estimatedMinutes,
      status: 'pending',
      source: 'manual',
      delegatedTo: _delegatedTo.isEmpty ? null : _delegatedTo,
      isSmartCompliant: _smartResult?.isValid ?? false,
      smartScore: _smartResult?.score ?? 0,
      tags: _tags.isEmpty ? null : _tags,
      createdAt: DateTime.now(),
      learningStage: 'stage1',
      userId: 'default',
    );

    final taskRepo = ref.read(taskRepositoryProvider);
    await taskRepo.insertTask(task);

    // Add points for creating task
    final gamificationService = ref.read(gamificationServiceProvider);
    await gamificationService.addPoints('task_created', 5);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Задача создана!'),
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
        title: const Text('Новая задача'),
        actions: [
          TextButton(
            onPressed: _saveTask,
            child: const Text('Сохранить'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Название задачи *',
                hintText: 'Например: "Согласовать бюджет на Q3"',
                prefixIcon: Icon(Icons.title),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                hintText: 'Добавьте детали...',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Quadrant
            Text('Квадрант', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _buildQuadrantSelector(),
            const SizedBox(height: 16),

            // Priority
            Text('Приоритет', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('🔥 Высокий'), icon: Icon(Icons.flag)),
                ButtonSegment(value: 3, label: Text('Средний')),
                ButtonSegment(value: 5, label: Text('Низкий')),
              ],
              selected: {_priority},
              onSelectionChanged: (set) => setState(() => _priority = set.first),
            ),
            const SizedBox(height: 16),

            // Deadline
            ListTile(
              leading: const Icon(Icons.event),
              title: Text(_deadline != null
                  ? 'Дедлайн: ${_deadline!.day}.${_deadline!.month}.${_deadline!.year}'
                  : 'Установить дедлайн'),
              trailing: _deadline != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _deadline = null),
                    )
                  : null,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _deadline = date);
              },
            ),
            const SizedBox(height: 8),

            // Estimated time
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(
                _estimatedMinutes != null
                    ? 'Время: $_estimatedMinutes мин'
                    : 'Оценить время',
              ),
              trailing: _estimatedMinutes != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _estimatedMinutes = null),
                    )
                  : null,
              onTap: () => _showTimePicker(),
            ),
            const SizedBox(height: 8),

            // Delegated to
            TextField(
              decoration: const InputDecoration(
                labelText: 'Делегировать (имя)',
                prefixIcon: Icon(Icons.person_outline),
              ),
              onChanged: (v) => _delegatedTo = v,
            ),
            const SizedBox(height: 16),

            // Tags
            TextField(
              decoration: const InputDecoration(
                labelText: 'Теги (через запятую)',
                prefixIcon: Icon(Icons.label_outline),
              ),
              onChanged: (v) => _tags = v,
            ),
            const SizedBox(height: 24),

            // SMART Check
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSmartChecking ? null : _checkSmart,
                icon: _isSmartChecking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                    _isSmartChecking ? 'Проверка...' : 'Проверить по SMART'),
              ),
            ),

            if (_smartResult != null) ...[
              const SizedBox(height: 16),
              _buildSmartResult(theme),
            ],

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveTask,
                icon: const Icon(Icons.check),
                label: const Text('Создать задачу'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuadrantSelector() {
    return Column(
      children: TaskQuadrant.values.map((q) {
        final selected = _selectedQuadrant == q.value;
        return RadioListTile<String>(
          value: q.value,
          groupValue: _selectedQuadrant,
          onChanged: (v) => setState(() => _selectedQuadrant = v!),
          title: Text(q.label),
          subtitle: Text(_getQuadrantHint(q)),
          activeColor: Color(q.color),
          secondary: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Color(q.color),
              shape: BoxShape.circle,
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getQuadrantHint(TaskQuadrant q) {
    switch (q) {
      case TaskQuadrant.urgentImportant:
        return 'Кризисы, горящие дедлайны — делай сейчас';
      case TaskQuadrant.importantNotUrgent:
        return 'Стратегия, развитие — запланируй';
      case TaskQuadrant.urgentNotImportant:
        return 'Перерывы, чужие просьбы — делегируй';
      case TaskQuadrant.notUrgentNotImportant:
        return 'Бесполезное — удали';
    }
  }

  Widget _buildSmartResult(ThemeData theme) {
    return Card(
      color: _smartResult!.isValid
          ? Colors.green.withOpacity(0.05)
          : Colors.orange.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _smartResult!.isValid
                      ? Icons.check_circle
                      : Icons.warning_amber,
                  color: _smartResult!.isValid ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'SMART: ${_smartResult!.score}/100',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_smartResult!.praise != null) ...[
                  const Spacer(),
                  Text(
                    _smartResult!.praise!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.green,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _buildSmartItem('S — Конкретность', _smartResult!.specific),
            _buildSmartItem('M — Измеримость', _smartResult!.measurable),
            _buildSmartItem('A — Достижимость', _smartResult!.achievable),
            _buildSmartItem('R — Актуальность', _smartResult!.relevant),
            _buildSmartItem('T — Время', _smartResult!.timeBound),

            // Improved version
            if (_smartResult!.improvedVersion != _titleController.text) ...[
              const Divider(),
              Text(
                'Улучшенная формулировка:',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 4),
              Card(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _smartResult!.improvedVersion,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _selectedImprovedVersion =
                              _smartResult!.improvedVersion;
                          _titleController.text =
                              _smartResult!.improvedVersion;
                        },
                        child: const Text('Использовать'),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Learning points
            if (_smartResult!.learningPoints.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Советы:',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.amber.shade700,
                ),
              ),
              ..._smartResult!.learningPoints.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Colors.amber)),
                      Expanded(
                        child: Text(
                          p,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSmartItem(String label, SmartCheckItem item) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            item.valid ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 16,
            color: item.valid ? Colors.green : Colors.red.shade300,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(text: item.comment),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTimePicker() async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Время на задачу'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Минуты',
            hintText: 'Например: 30',
            suffixText: 'мин',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              Navigator.pop(ctx, val);
            },
            child: const Text('ОК'),
          ),
        ],
      ),
    );
    if (result != null && result > 0) {
      setState(() => _estimatedMinutes = result);
    }
  }
}
