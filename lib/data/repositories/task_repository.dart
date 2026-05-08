import '../models/task.dart';
import '../database/database_helper.dart';

/// Репозиторий для работы с задачами
class TaskRepository {
  Future<int> insertTask(Task task) => DatabaseHelper.insertTask(task);
  Future<int> updateTask(Task task) => DatabaseHelper.updateTask(task);
  Future<int> deleteTask(String id) => DatabaseHelper.deleteTask(id);
  Future<Task?> getTask(String id) => DatabaseHelper.getTask(id);
  Future<List<Task>> getTasks({
    String? quadrant,
    String? status,
    String? searchQuery,
    bool? onlyToday,
  }) =>
      DatabaseHelper.getTasks(
        quadrant: quadrant,
        status: status,
        searchQuery: searchQuery,
        onlyToday: onlyToday,
      );
  Future<List<Task>> getTasksByQuadrant(String quadrant) =>
      DatabaseHelper.getTasksByQuadrant(quadrant);
  Future<List<Task>> getTasksByStatus(String status) =>
      DatabaseHelper.getTasksByStatus(status);
  Future<int> getTaskCount() => DatabaseHelper.getTaskCount();
}
