import '../models/user_progress.dart';
import '../database/database_helper.dart';

/// Репозиторий для работы с достижениями
class AchievementRepository {
  Future<List<Achievement>> getAchievements(String userId) =>
      DatabaseHelper.getAchievements(userId);
  Future<int> insertAchievement(Achievement achievement) =>
      DatabaseHelper.insertAchievement(achievement);
}
