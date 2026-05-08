import '../models/settings.dart';
import '../database/database_helper.dart';

/// Репозиторий для работы с настройками
class SettingsRepository {
  Future<AppSettings?> getSettings(String userId) =>
      DatabaseHelper.getSettings(userId);
  Future<int> saveSettings(AppSettings settings) =>
      DatabaseHelper.saveSettings(settings);
}
