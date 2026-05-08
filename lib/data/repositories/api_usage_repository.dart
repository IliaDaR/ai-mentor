import '../models/settings.dart';
import '../database/database_helper.dart';

/// Репозиторий для учёта использования API
class ApiUsageRepository {
  Future<int> logApiUsage(ApiUsage usage) =>
      DatabaseHelper.logApiUsage(usage);
  Future<List<ApiUsage>> getApiUsage(String userId, {DateTime? from}) =>
      DatabaseHelper.getApiUsage(userId, from: from);
}
