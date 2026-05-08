import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/enums.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/user_progress.dart';
import '../../../domain/providers/repository_providers.dart';
import '../../../domain/providers/service_providers.dart';

class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({super.key});

  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen> {
  LearningStage _currentStage = LearningStage.stage1;
  UserProgress? _progress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final learning = ref.read(learningServiceProvider);
      final progressRepo = ref.read(userProgressRepositoryProvider);
      final stage = await learning.getCurrentStage();
      final progress = await progressRepo.getUserProgress('default');
      setState(() {
        _currentStage = stage;
        _progress = progress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Обучение'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current stage card
          Card(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getStageColor(_currentStage).withOpacity(0.2),
                    _getStageColor(_currentStage).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getStageIcon(_currentStage),
                        color: _getStageColor(_currentStage),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Этап ${_currentStage.name.replaceAll('stage', '')}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _currentStage.label,
                              style: TextStyle(
                                color: _getStageColor(_currentStage),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getStageDescription(_currentStage),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getAiModeDescription(_currentStage),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Progress stages
          Text(
            'Прогресс обучения',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...LearningStage.values.map((stage) => _buildStageRow(stage)),
          const SizedBox(height: 32),

          // Stats
          if (_progress != null) ...[
            Text(
              'Ваша статистика',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatRow('Создано задач', _progress!.tasksCreated),
                    _buildStatRow('SMART-задач', _progress!.tasksSmartCompliant),
                    _buildStatRow('Баллов', _progress!.totalPoints),
                    _buildStatRow('Текущий стрик', '${_progress!.currentStreakDays} дней'),
                    _buildStatRow('Фокус (мин)', _progress!.focusTimeTotalMinutes),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStageRow(LearningStage stage) {
    final stageNum = int.parse(stage.name.replaceAll('stage', ''));
    final currentNum = int.parse(_currentStage.name.replaceAll('stage', ''));
    final isUnlocked = stageNum <= currentNum;
    final isCurrent = stage == _currentStage;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isCurrent ? _getStageColor(stage).withOpacity(0.1) : null,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isUnlocked
                ? _getStageColor(stage).withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            isUnlocked ? _getStageIcon(stage) : Icons.lock,
            color: isUnlocked ? _getStageColor(stage) : Colors.grey,
          ),
        ),
        title: Text(
          'Этап $stageNum: ${stage.label}',
          style: TextStyle(
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isUnlocked ? null : Colors.grey,
          ),
        ),
        subtitle: Text(
          _getStageCondition(stage),
          style: TextStyle(
            color: isUnlocked ? Colors.grey[600] : Colors.grey[400],
            fontSize: 12,
          ),
        ),
        trailing: isCurrent
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStageColor(stage),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Текущий',
                  style: TextStyle(
                    color: _getStageColor(stage).computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : isUnlocked
                ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                : null,
      ),
    );
  }

  Widget _buildStatRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            '$value',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStageColor(LearningStage stage) {
    switch (stage) {
      case LearningStage.stage1:
        return Colors.blue;
      case LearningStage.stage2:
        return Colors.teal;
      case LearningStage.stage3:
        return Colors.orange;
      case LearningStage.stage4:
        return Colors.purple;
      case LearningStage.stage5:
        return Colors.amber;
    }
  }

  IconData _getStageIcon(LearningStage stage) {
    switch (stage) {
      case LearningStage.stage1:
        return Icons.assistant;
      case LearningStage.stage2:
        return Icons.handshake;
      case LearningStage.stage3:
        return Icons.rate_review;
      case LearningStage.stage4:
        return Icons.flight_takeoff;
      case LearningStage.stage5:
        return Icons.school;
    }
  }

  String _getStageDescription(LearningStage stage) {
    switch (stage) {
      case LearningStage.stage1:
        return 'ИИ полностью управляет вашим планированием. Следуйте рекомендациям AI, чтобы освоить методики продуктивности.';
      case LearningStage.stage2:
        return 'Вы и ИИ работаете вместе. AI предлагает, вы корректируете. Учитесь принимать обоснованные решения.';
      case LearningStage.stage3:
        return 'Вы планируете самостоятельно, а ИИ проверяет и корректирует ваши задачи. Развивайте навык самоконтроля.';
      case LearningStage.stage4:
        return 'Вы действуете автономно. ИИ только наблюдает и даёт обратную связь в конце дня. Полная свобода действий.';
      case LearningStage.stage5:
        return 'Вы становитесь наставником. Делитесь опытом, помогайте другим. ИИ помогает анализировать ваши успехи.';
    }
  }

  String _getAiModeDescription(LearningStage stage) {
    switch (stage) {
      case LearningStage.stage1:
        return '🎯 Режим: ИИ полностью управляет (full_control)';
      case LearningStage.stage2:
        return '🤝 Режим: ИИ предлагает (suggest)';
      case LearningStage.stage3:
        return '✅ Режим: ИИ проверяет (validate)';
      case LearningStage.stage4:
        return '👀 Режим: ИИ наблюдает (observe)';
      case LearningStage.stage5:
        return '🎓 Режим: ИИ-наставник (mentor)';
    }
  }

  String _getStageCondition(LearningStage stage) {
    switch (stage) {
      case LearningStage.stage1:
        return 'Начальный этап';
      case LearningStage.stage2:
        return 'Требуется: 10 выполненных планов';
      case LearningStage.stage3:
        return 'Требуется: 2 недели + 300 баллов';
      case LearningStage.stage4:
        return 'Требуется: 20 SMART-задач';
      case LearningStage.stage5:
        return 'Требуется: 2 недели без вмешательства ИИ';
    }
  }
}
