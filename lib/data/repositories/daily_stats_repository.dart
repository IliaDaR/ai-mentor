import '../models/user_progress.dart';
import '../database/database_helper.dart';

/// Репозиторий для работы с дневной статистикой
class DailyStatsRepository {
  Future<DailyStats?> getDailyStats(String userId, String date) =>
      DatabaseHelper.getDailyStats(userId, date);
  Future<int> updateDailyStats(DailyStats stats) =>
      DatabaseHelper.updateDailyStats(stats);
}
