import '../models/user_progress.dart';
import '../database/database_helper.dart';

/// Репозиторий для работы с прогрессом пользователя
class UserProgressRepository {
  Future<UserProgress?> getUserProgress(String userId) =>
      DatabaseHelper.getUserProgress(userId);
  Future<int> insertOrUpdateUserProgress(UserProgress progress) =>
      DatabaseHelper.insertOrUpdateUserProgress(progress);
  Future<int> addPoints(String userId, int points) =>
      DatabaseHelper.addPoints(userId, points);
}
