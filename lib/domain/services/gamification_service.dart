import '../../data/repositories/user_progress_repository.dart';
import '../../data/repositories/achievement_repository.dart';
import '../../data/repositories/daily_stats_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../core/constants/enums.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/user_progress.dart';

class GamificationService {
  final UserProgressRepository _userProgressRepository;
  final AchievementRepository _achievementRepository;
  final DailyStatsRepository _dailyStatsRepository;
  final TaskRepository _taskRepository;

  GamificationService({
    required UserProgressRepository userProgressRepository,
    required AchievementRepository achievementRepository,
    required DailyStatsRepository dailyStatsRepository,
    required TaskRepository taskRepository,
  })  : _userProgressRepository = userProgressRepository,
        _achievementRepository = achievementRepository,
        _dailyStatsRepository = dailyStatsRepository,
        _taskRepository = taskRepository;

  /// Начислить баллы за действие
  Future<int> addPoints(String action, int points) async {
    await _userProgressRepository.addPoints('default', points);
    final progress = await _userProgressRepository.getUserProgress('default');
    if (progress != null) {
      // Update level based on points
      final newLevel = UserLevel.fromPoints(progress.totalPoints + points);
      if (newLevel.value != progress.currentLevel) {
        await _userProgressRepository.insertOrUpdateUserProgress(
          progress.copyWith(
            totalPoints: progress.totalPoints + points,
            currentLevel: newLevel.value,
          ),
        );
      } else {
        await _userProgressRepository.insertOrUpdateUserProgress(
          progress.copyWith(totalPoints: progress.totalPoints + points),
        );
      }

      // Update daily stats
      final today = AppDateUtils.formatDate(DateTime.now());
      final dailyStats = await _dailyStatsRepository.getDailyStats('default', today);
      if (dailyStats != null) {
        await _dailyStatsRepository.updateDailyStats(
          dailyStats.copyWith(
            pointsEarned: dailyStats.pointsEarned + points,
          ),
        );
      }
    }
    return points;
  }

  /// Проверить и открыть достижения
  Future<List<Achievement>> checkAchievements() async {
    final progress = await _userProgressRepository.getUserProgress('default');
    if (progress == null) return [];

    final achievements = await _achievementRepository.getAchievements('default');
    final existingKeys = achievements.map((a) => a.achievementKey).toSet();
    final newAchievements = <Achievement>[];

    // Check each achievement condition
    for (final entry in _achievementDefinitions.entries) {
      if (existingKeys.contains(entry.key)) continue;

      final cond = entry.value;
      final stats = await _collectStats(progress);
      if (cond.check(stats)) {
        final achievement = Achievement(
          id: '${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
          userId: 'default',
          achievementKey: entry.key,
          title: cond.title,
          description: cond.description,
          pointsReward: cond.points,
          unlockedAt: DateTime.now(),
          isNew: true,
        );
        await _achievementRepository.insertAchievement(achievement);
        await addPoints(entry.key, cond.points);
        newAchievements.add(achievement);
      }
    }

    return newAchievements;
  }

  Future<Map<String, dynamic>> _collectStats(UserProgress progress) async {
    final tasks = await _taskRepository.getTasks();
    final achievements = await _achievementRepository.getAchievements('default');

    return {
      'plans_accepted': _countActions('plan_accepted'),
      'smart_tasks': progress.tasksSmartCompliant,
      'tasks_completed': progress.tasksCompleted,
      'focus_hours': progress.focusTimeTotalMinutes ~/ 60,
      'delegated_tasks': tasks.where((t) => t.status == 'delegated').length,
      'streak_days': progress.currentStreakDays,
      'points': progress.totalPoints,
      'why_clicks': _countActions('why_click'),
      'achievements_count': achievements.length,
      'stage': progress.currentStage,
    };
  }

  int _countActions(String type) {
    // This would normally query an action log table
    // For now, return a placeholder
    return 0;
  }

  // ========== DEFINITIONS ==========

  static const Map<String, AchievementCondition> _achievementDefinitions = {
    'first_plan': AchievementCondition(
      title: 'Первый шаг',
      description: 'Принял первый план ИИ',
      points: 50,
      check: _checkFirstPlan,
    ),
    'why_master': AchievementCondition(
      title: 'Понимаю почему',
      description: '10 раз нажал "Почему?"',
      points: 100,
      check: _checkWhyMaster,
    ),
    'smart_novice': AchievementCondition(
      title: 'SMART-новичок',
      description: '5 задач по SMART',
      points: 75,
      check: _checkSmartNovice,
    ),
    'eisenhower': AchievementCondition(
      title: 'Эйзенхауэр',
      description: '7 дней правильных приоритетов',
      points: 150,
      check: _checkEisenhower,
    ),
    'clean_inbox': AchievementCondition(
      title: 'Чистюля',
      description: '7 дней нулевого инбокса',
      points: 200,
      check: _checkCleanInbox,
    ),
    'focus_master': AchievementCondition(
      title: 'Фокусник',
      description: '10 часов в режиме Монах',
      points: 150,
      check: _checkFocusMaster,
    ),
    'delegator': AchievementCondition(
      title: 'Делегатор',
      description: '10 задач делегировано',
      points: 200,
      check: _checkDelegator,
    ),
    'autonomous': AchievementCondition(
      title: 'Автоном',
      description: '30 дней без помощи ИИ',
      points: 500,
      check: _checkAutonomous,
    ),
    'mentor': AchievementCondition(
      title: 'Наставник',
      description: 'Помог 3 коллегам',
      points: 1000,
      check: _checkMentor,
    ),
    'streak_30': AchievementCondition(
      title: 'Непрерывность',
      description: '30 дней стрика',
      points: 300,
      check: _checkStreak30,
    ),
    'zero_missed': AchievementCondition(
      title: 'Идеальная неделя',
      description: '7 дней, 0 пропущенных',
      points: 250,
      check: _checkZeroMissed,
    ),
    'explainer': AchievementCondition(
      title: 'Объяснитель',
      description: '5 раз оспорил ИИ с аргументами',
      points: 100,
      check: _checkExplainer,
    ),
  };

  // ========== ACHIEVEMENT CHECKS ==========

  static bool _checkFirstPlan(Map<String, dynamic> stats) =>
      (stats['plans_accepted'] as int?) != null && stats['plans_accepted'] >= 1;

  static bool _checkWhyMaster(Map<String, dynamic> stats) =>
      (stats['why_clicks'] as int?) != null && stats['why_clicks'] >= 10;

  static bool _checkSmartNovice(Map<String, dynamic> stats) =>
      (stats['smart_tasks'] as int?) != null && stats['smart_tasks'] >= 5;

  static bool _checkEisenhower(Map<String, dynamic> stats) =>
      false; // Requires 7 days of correct priorities - future implementation

  static bool _checkCleanInbox(Map<String, dynamic> stats) =>
      false; // Requires 7 days of zero inbox - future implementation

  static bool _checkFocusMaster(Map<String, dynamic> stats) =>
      (stats['focus_hours'] as int?) != null && stats['focus_hours'] >= 10;

  static bool _checkDelegator(Map<String, dynamic> stats) =>
      (stats['delegated_tasks'] as int?) != null && stats['delegated_tasks'] >= 10;

  static bool _checkAutonomous(Map<String, dynamic> stats) =>
      false; // Requires 30 days without AI help - future implementation

  static bool _checkMentor(Map<String, dynamic> stats) =>
      false; // Requires helping 3 colleagues - future implementation

  static bool _checkStreak30(Map<String, dynamic> stats) =>
      (stats['streak_days'] as int?) != null && stats['streak_days'] >= 30;

  static bool _checkZeroMissed(Map<String, dynamic> stats) =>
      false; // Requires 7 days, 0 missed - future implementation

  static bool _checkExplainer(Map<String, dynamic> stats) =>
      false; // Requires 5 disputes with arguments - future implementation

  /// Получить уровень по количеству баллов
  static UserLevel getLevel(int points) {
    return UserLevel.fromPoints(points);
  }

  /// Прогресс к следующему уровню (0-100)
  static double getProgressToNextLevel(int points) {
    final level = UserLevel.fromPoints(points);
    if (level == UserLevel.mentor) return 100.0;
    final currentMin = level.minPoints;
    final nextMax = level.maxPoints;
    final range = nextMax - currentMin;
    if (range <= 0) return 100.0;
    return ((points - currentMin) / range * 100).clamp(0, 100);
  }

  /// Обновить стрик
  Future<void> updateStreak() async {
    final progress = await _userProgressRepository.getUserProgress('default');
    if (progress == null) return;

    final now = DateTime.now();
    final lastActive = progress.lastActiveAt;

    if (lastActive != null) {
      final diff = now.difference(lastActive);
      if (diff.inDays == 1) {
        // Consecutive day
        final newStreak = progress.currentStreakDays + 1;
        await _userProgressRepository.insertOrUpdateUserProgress(
          progress.copyWith(
            currentStreakDays: newStreak,
            lastActiveAt: now,
            longestStreakDays:
                newStreak > progress.longestStreakDays
                    ? newStreak
                    : progress.longestStreakDays,
          ),
        );
      } else if (diff.inDays > 1) {
        // Streak broken
        await _userProgressRepository.insertOrUpdateUserProgress(
          progress.copyWith(
            currentStreakDays: 1,
            lastActiveAt: now,
          ),
        );
      }
    } else {
      await _userProgressRepository.insertOrUpdateUserProgress(
        progress.copyWith(
          currentStreakDays: 1,
          lastActiveAt: now,
        ),
      );
    }
  }
}

class AchievementCondition {
  final String title;
  final String description;
  final int points;
  final bool Function(Map<String, dynamic> stats) check;

  const AchievementCondition({
    required this.title,
    required this.description,
    required this.points,
    required this.check,
  });
}
