import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/enums.dart';
import '../../../data/models/source.dart';
import '../../../data/models/task.dart';
import '../../../domain/providers/service_providers.dart';
import '../../../domain/providers/repository_providers.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  List<Source> _sources = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  Future<void> _loadSources() async {
    setState(() => _isLoading = true);
    try {
      final sourceRepo = ref.read(sourceRepositoryProvider);
      _sources = await sourceRepo.getSources(isSpam: false);
    } catch (e) {
      // Handle error
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _classifySource(Source source) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final aiService = ref.read(aiServiceProvider);
      final sourceRepo = ref.read(sourceRepositoryProvider);
      final taskRepo = ref.read(taskRepositoryProvider);
      final gamificationService = ref.read(gamificationServiceProvider);

      final result = await aiService.classifyInbox(
        sourceType: source.type,
        sender: source.metadata ?? 'Неизвестно',
        subject: source.aiSummary ?? 'Без темы',
        body: source.rawContent ?? '',
      );

      if (!mounted) return;
      Navigator.pop(context);

      final category = result['category'] as String?;
      final isSpam = result['is_spam'] as bool? ?? false;

      if (isSpam) {
        await sourceRepo.insertSource(
          source.copyWith(isSpam: true, processedAt: DateTime.now()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Помечено как спам')),
        );
        _loadSources();
        return;
      }

      if (category != null) {
        // Create task from source
        final task = Task(
          id: '${DateTime.now().millisecondsSinceEpoch}',
          title: result['summary'] as String? ?? source.aiSummary ?? 'Задача из входящих',
          quadrant: category,
          priority: category == TaskQuadrant.urgentImportant.value ? 1 : 3,
          status: 'pending',
          source: 'notification',
          sourceId: source.id,
          createdAt: DateTime.now(),
          learningStage: 'stage1',
          userId: 'default',
        );
        await taskRepo.insertTask(task);

        await sourceRepo.insertSource(
          source.copyWith(
            aiCategory: category,
            aiConfidence: (result['confidence'] as num?)?.toDouble(),
            linkedTaskId: task.id,
            processedAt: DateTime.now(),
          ),
        );

        // Add points
        await gamificationService.addPoints('classified_inbox', 5);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Создана задача в квадранте "${_getQuadrantLabel(category)}"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }

    _loadSources();
  }

  String _getQuadrantLabel(String value) {
    final q = TaskQuadrant.values.firstWhere(
      (q) => q.value == value,
      orElse: () => TaskQuadrant.notUrgentNotImportant,
    );
    return q.label;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Входящие'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Очистить входящие?'),
                  content: const Text('Обработанные будут удалены'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Очистить'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                // Clear all processed
                _loadSources();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sources.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Входящие пусты',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Новые уведомления и сообщения\nпоявятся здесь',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSources,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _sources.length + 1, // +1 for header
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '${_sources.length} новых входящих',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      final source = _sources[index - 1];
                      return _buildSourceCard(theme, source);
                    },
                  ),
                ),
    );
  }

  Widget _buildSourceCard(ThemeData theme, Source source) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getSourceIcon(source.type),
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  source.type == 'email' ? 'Письмо' : 'Уведомление',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(source.createdAt),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              source.aiSummary ?? 'Новое сообщение',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (source.rawContent != null) ...[
              const SizedBox(height: 4),
              Text(
                source.rawContent!.length > 100
                    ? '${source.rawContent!.substring(0, 100)}...'
                    : source.rawContent!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _classifySource(source),
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Классифицировать'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSourceIcon(String type) {
    switch (type) {
      case 'email':
        return Icons.email_outlined;
      case 'notification':
        return Icons.notifications_outlined;
      case 'message':
        return Icons.message_outlined;
      case 'meeting':
        return Icons.mic_outlined;
      default:
        return Icons.article_outlined;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    return '${date.day}.${date.month}.${date.year}';
  }
}
