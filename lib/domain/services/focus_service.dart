import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class FocusService extends ChangeNotifier {
  Timer? _timer;
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;
  bool _isRunning = false;
  bool _isPaused = false;
  String? _currentTaskId;
  String? _currentTaskTitle;

  Duration get elapsed => _elapsed;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  String? get currentTaskId => _currentTaskId;
  String? get currentTaskTitle => _currentTaskTitle;
  int get elapsedMinutes => _elapsed.inMinutes;

  /// Запустить фокус-сессию
  void startFocus({required String taskId, required String taskTitle}) {
    _currentTaskId = taskId;
    _currentTaskTitle = taskTitle;
    _startTime = DateTime.now();
    _isRunning = true;
    _isPaused = false;
    _elapsed = Duration.zero;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime != null) {
        _elapsed = DateTime.now().difference(_startTime!);
        notifyListeners();
      }
    });

    notifyListeners();
  }

  /// Поставить на паузу
  void pause() {
    if (_isRunning && !_isPaused) {
      _isPaused = true;
      _timer?.cancel();
      notifyListeners();
    }
  }

  /// Возобновить
  void resume() {
    if (_isRunning && _isPaused) {
      _isPaused = false;
      _startTime = DateTime.now().subtract(_elapsed);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_startTime != null) {
          _elapsed = DateTime.now().difference(_startTime!);
          notifyListeners();
        }
      });
      notifyListeners();
    }
  }

  /// Завершить фокус-сессию досрочно
  int stopFocus() {
    _timer?.cancel();
    _isRunning = false;
    _isPaused = false;
    final minutes = _elapsed.inMinutes;
    _elapsed = Duration.zero;
    _currentTaskId = null;
    _currentTaskTitle = null;
    notifyListeners();
    return minutes;
  }

  /// Завершить с выполнением задачи
  int completeFocus() {
    final minutes = stopFocus();
    return minutes; // Returns minutes for reward calculation
  }

  /// Проверить, превышен ли лимит
  bool isOverMaxDuration() {
    return _elapsed.inMinutes >= AppConstants.focusMaxDuration;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
