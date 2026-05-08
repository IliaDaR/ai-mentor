import '../../core/constants/enums.dart';
import '../../data/models/user_progress.dart';
import '../../data/repositories/user_progress_repository.dart';
import '../../data/repositories/task_repository.dart';

class LearningService {
  final UserProgressRepository _userProgressRepository;
  final TaskRepository _taskRepository;

  LearningService({
    required UserProgressRepository userProgressRepository,
    required TaskRepository taskRepository,
  })  : _userProgressRepository = userProgressRepository,
        _taskRepository = taskRepository;

  /// Определить текущий этап обучения
  Future<LearningStage> getCurrentStage() async {
    final progress = await _userProgressRepository.getUserProgress('default');
    if (progress == null) return LearningStage.stage1;

    return _stageFromString(progress.currentStage);
  }

  /// Проверить, нужно ли перейти на следующий этап
  Future<LearningStage?> checkStageTransition() async {
    final progress = await _userProgressRepository.getUserProgress('default');
    if (progress == null) return null;

    final currentStage = _stageFromString(progress.currentStage);
    final tasks = await _taskRepository.getTasks();

    switch (currentStage) {
      case LearningStage.stage1:
        // Stage 1 → 2: 10 plans accepted
        final plansAccepted = tasks
            .where((t) => t.aiExplanation != null && t.status == 'completed')
            .length;
        if (plansAccepted >= 10) {
          await _advanceStage(progress, LearningStage.stage2);
          return LearningStage.stage2;
        }
        break;

      case LearningStage.stage2:
        // Stage 2 → 3: 1 week of collaborative work
        final joinedAt = progress.joinedAt;
        final weeksSinceJoin =
            DateTime.now().difference(joinedAt).inDays ~/ 7;
        if (weeksSinceJoin >= 2 && progress.totalPoints >= 300) {
          await _advanceStage(progress, LearningStage.stage3);
          return LearningStage.stage3;
        }
        break;

      case LearningStage.stage3:
        // Stage 3 → 4: 20 tasks without AI corrections
        if (progress.tasksSmartCompliant >= 20) {
          await _advanceStage(progress, LearningStage.stage4);
          return LearningStage.stage4;
        }
        break;

      case LearningStage.stage4:
        // Stage 4 → 5: 2 weeks without intervention
        final twoWeeksAgo =
            DateTime.now().subtract(const Duration(days: 14));
        if (progress.lastActiveAt != null &&
            progress.lastActiveAt!.isBefore(twoWeeksAgo)) {
          await _advanceStage(progress, LearningStage.stage5);
          return LearningStage.stage5;
        }
        break;

      case LearningStage.stage5:
        break;
    }

    return null;
  }

  Future<void> _advanceStage(
      UserProgress progress, LearningStage newStage) async {
    await _userProgressRepository.insertOrUpdateUserProgress(
      progress.copyWith(currentStage: newStage.value),
    );
  }

  /// Получить режим ИИ для текущего этапа
  String getAiMode(LearningStage stage) {
    switch (stage) {
      case LearningStage.stage1:
        return 'full_control';
      case LearningStage.stage2:
        return 'suggest';
      case LearningStage.stage3:
        return 'validate';
      case LearningStage.stage4:
        return 'observe';
      case LearningStage.stage5:
        return 'mentor';
    }
  }

  /// Может ли пользователь редактировать задачи ИИ?
  bool canEditAiTasks(LearningStage stage) {
    return stage.index >= LearningStage.stage2.index;
  }

  /// Нужна ли проверка SMART?
  bool needSmartCheck(LearningStage stage) {
    return stage.index <= LearningStage.stage3.index;
  }

  LearningStage _stageFromString(String stage) {
    return LearningStage.values.firstWhere(
      (s) => s.value == stage,
      orElse: () => LearningStage.stage1,
    );
  }
}
