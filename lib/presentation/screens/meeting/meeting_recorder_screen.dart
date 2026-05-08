import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/enums.dart';
import '../../../data/models/source.dart';
import '../../../data/models/task.dart';
import '../../../domain/providers/service_providers.dart';
import '../../../domain/providers/repository_providers.dart';
import '../../../core/utils/logger.dart';

class MeetingRecorderScreen extends ConsumerStatefulWidget {
  const MeetingRecorderScreen({super.key});

  @override
  ConsumerState<MeetingRecorderScreen> createState() => _MeetingRecorderScreenState();
}

class _MeetingRecorderScreenState extends ConsumerState<MeetingRecorderScreen> {
  final _titleController = TextEditingController();
  final _participantsController = TextEditingController();
  final _transcriptController = TextEditingController();
  bool _isRecording = false;
  bool _isProcessing = false;
  Map<String, dynamic>? _analysisResult;

  @override
  void dispose() {
    _titleController.dispose();
    _participantsController.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  void _toggleRecording() {
    setState(() => _isRecording = !_isRecording);

    if (_isRecording) {
      // Start audio recording via native channel
      // For now, simulate
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Запись начата'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Stop recording
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запись остановлена')),
      );
    }
  }

  Future<void> _processMeeting() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название совещания')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final aiService = ref.read(aiServiceProvider);
      final taskRepo = ref.read(taskRepositoryProvider);
      final sourceRepo = ref.read(sourceRepositoryProvider);

      final result = await aiService.analyzeMeeting(
        meetingTitle: _titleController.text,
        meetingDate: DateTime.now(),
        participants: _participantsController.text,
        transcriptText: _transcriptController.text,
      );

      setState(() => _analysisResult = result);

      // Create tasks from action items
      final actionItems = result['action_items'] as List? ?? [];
      for (final item in actionItems) {
        if (item is Map<String, dynamic>) {
          final task = Task(
            id: '${DateTime.now().millisecondsSinceEpoch}_${actionItems.indexOf(item)}',
            title: item['task'] as String? ?? 'Задача из совещания',
            description: item['context'] as String?,
            quadrant: item['quadrant'] as String? ??
                TaskQuadrant.importantNotUrgent.value,
            priority: 3,
            status: 'pending',
            source: 'meeting',
            deadline: item['deadline'] != null
                ? DateTime.tryParse(item['deadline'] as String)
                : null,
            createdAt: DateTime.now(),
            learningStage: 'stage1',
            userId: 'default',
          );
          await taskRepo.insertTask(task);
        }
      }

      // Save source
      final source = Source(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        type: 'meeting',
        rawContent: _transcriptController.text,
        aiSummary: result['summary'] as String?,
        aiCategory: 'meeting',
        processedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await sourceRepo.insertSource(source);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Совещание обработано! Создано ${actionItems.length} задач'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обработки: $e')),
        );
      }
    }

    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Запись совещания'),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : _processMeeting,
            child: const Text('Обработать'),
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
                labelText: 'Название совещания',
                prefixIcon: Icon(Icons.meeting_room),
              ),
            ),
            const SizedBox(height: 12),

            // Participants
            TextField(
              controller: _participantsController,
              decoration: const InputDecoration(
                labelText: 'Участники (через запятую)',
                prefixIcon: Icon(Icons.people),
              ),
            ),
            const SizedBox(height: 16),

            // Record button
            Center(
              child: Column(
                children: [
                  InkWell(
                    onTap: _toggleRecording,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording
                            ? Colors.red
                            : theme.colorScheme.primary,
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRecording ? 'Остановить запись' : 'Начать запись',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Transcript
            Text('Транскрипт', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _transcriptController,
              decoration: const InputDecoration(
                hintText: 'Или введите текст вручную...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16),
              ),
              maxLines: 10,
              minLines: 5,
            ),
            const SizedBox(height: 16),

            // Process button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _processMeeting,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                    _isProcessing ? 'Анализ...' : 'Проанализировать совещание'),
              ),
            ),

            // Analysis result
            if (_analysisResult != null) ...[
              const SizedBox(height: 24),
              _buildAnalysisResult(theme),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResult(ThemeData theme) {
    return Card(
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
                  'Результаты анализа',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Summary
            Text(
              'Краткое содержание',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _analysisResult!['summary'] as String? ?? 'Нет данных',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),

            // Decisions
            _buildListSection(theme, 'Принятые решения',
                _analysisResult!['decisions'] as List?),
            const SizedBox(height: 8),

            // Action items
            _buildActionItems(theme,
                _analysisResult!['action_items'] as List?),
            const SizedBox(height: 8),

            // Open questions
            _buildListSection(theme, 'Открытые вопросы',
                _analysisResult!['open_questions'] as List?),
          ],
        ),
      ),
    );
  }

  Widget _buildListSection(
      ThemeData theme, String title, List? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        ...items.take(5).map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(
                      child: Text(
                        item is Map ? (item['text'] ?? item.toString()) : item.toString(),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildActionItems(ThemeData theme, List? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Задачи к исполнению',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        ...items.take(5).map(
              (item) {
                final task = item is Map ? item['task'] ?? item.toString() : item.toString();
                final owner =
                    item is Map ? item['owner'] ?? '' : '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 14, color: Colors.teal),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$task${owner.isNotEmpty ? ' (@$owner)' : ''}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      ],
    );
  }
}
