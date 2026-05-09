import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../core/utils/date_utils.dart';
import '../../../data/models/user_progress.dart';
import '../../../domain/providers/repository_providers.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  UserProgress? _progress;
  bool _isLoading = true;
  int _selectedPeriod = 0; // 0: week, 1: month, 2: all

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userProgressRepo = ref.read(userProgressRepositoryProvider);
      _progress = await userProgressRepo.getUserProgress('default');
    } catch (e) {
      // Handle error
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Period selector
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Неделя')),
                      ButtonSegment(value: 1, label: Text('Месяц')),
                      ButtonSegment(value: 2, label: Text('Всё время')),
                    ],
                    selected: {_selectedPeriod},
                    onSelectionChanged: (set) =>
                        setState(() => _selectedPeriod = set.first),
                  ),
                  const SizedBox(height: 24),

                  // Points overview
                  _buildPointsCard(theme),
                  const SizedBox(height: 16),

                  // Tasks chart
                  _buildTasksCard(theme),
                  const SizedBox(height: 16),

                  // Focus time
                  _buildFocusCard(theme),
                  const SizedBox(height: 16),

                  // Learning progress
                  _buildLearningCard(theme),
                  const SizedBox(height: 16),

                  // Comparison summary
                  _buildComparisonCard(theme),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildPointsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Баллы и уровень',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Points circle
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_progress?.totalPoints ?? 0}',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Всего баллов',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: theme.colorScheme.outlineVariant,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _getLevelName(_progress?.totalPoints ?? 0),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Текущий уровень',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Задачи',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem(
                  theme,
                  '${_progress?.tasksCompleted ?? 0}',
                  'Выполнено',
                  Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  theme,
                  '${_progress?.tasksCreated ?? 0}',
                  'Создано',
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusCard(ThemeData theme) {
    final totalMinutes = _progress?.focusTimeTotalMinutes ?? 0;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Фокус-время',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.timer, size: 32, color: Colors.deepPurple),
                const SizedBox(width: 12),
                Text(
                  '${hours}ч ${minutes}мин',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Обучение',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.school, size: 32, color: Colors.amber.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Стадия ${_progress?.currentStage ?? 1}',
                        style: theme.textTheme.titleMedium,
                      ),
                      LinearProgressIndicator(
                        value: ((_progress?.tasksSmartCompliant ?? 0).clamp(0, 100)) / 100,
                        backgroundColor: Colors.amber.withOpacity(0.1),
                        color: Colors.amber,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Сравнение с прошлым периодом',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildComparisonItem(
                  theme,
                  Icons.trending_up,
                  'Задачи',
                  '${_progress?.tasksCompleted ?? 0}',
                  '+12%',
                  Colors.green,
                ),
                const SizedBox(width: 16),
                _buildComparisonItem(
                  theme,
                  Icons.timer,
                  'Фокус',
                  '${_progress?.focusTimeTotalMinutes ?? 0} мин',
                  '+5%',
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getLevelName(int points) {
    if (points >= 5000) return '🎓 Наставник';
    if (points >= 3000) return '👑 Автоном';
    if (points >= 1500) return '🏆 Мастер';
    if (points >= 800) return '🌳 Подмастерье';
    if (points >= 300) return '🌿 Ученик';
    return '🌱 Новичок';
  }

  Widget _buildStatItem(
      ThemeData theme, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(ThemeData theme, IconData icon, String label,
      String value, String change, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            change,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
