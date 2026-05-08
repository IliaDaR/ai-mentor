import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/providers/repository_providers.dart';
import '../../../domain/providers/service_providers.dart';

class FocusScreen extends ConsumerStatefulWidget {
  final String? initialTaskId;
  final String? initialTaskTitle;

  const FocusScreen({
    super.key,
    this.initialTaskId,
    this.initialTaskTitle,
  });

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isPulsing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    final focusService = ref.read(focusServiceProvider);
    focusService.addListener(_onFocusChanged);

    if (widget.initialTaskId != null) {
      focusService.startFocus(
        taskId: widget.initialTaskId!,
        taskTitle: widget.initialTaskTitle ?? 'Фокус',
      );
    }
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _startFocus() {
    final focusService = ref.read(focusServiceProvider);
    _pulseController.repeat(reverse: true);
    setState(() => _isPulsing = true);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Начать фокус-сессию'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Название задачи (необязательно)',
              ),
              onChanged: (v) {
                focusService.startFocus(
                  taskId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                  taskTitle: v.isEmpty ? 'Фокус-сессия' : v,
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              focusService.startFocus(
                taskId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                taskTitle: 'Фокус-сессия',
              );
            },
            child: const Text('Начать'),
          ),
        ],
      ),
    );
  }

  void _stopFocus() async {
    final focusService = ref.read(focusServiceProvider);
    final gamificationService = ref.read(gamificationServiceProvider);
    final userProgressRepo = ref.read(userProgressRepositoryProvider);

    _pulseController.stop();
    setState(() => _isPulsing = false);

    final minutes = focusService.completeFocus();
    if (minutes >= AppConstants.focusMinDuration) {
      await gamificationService.addPoints('focus_session', AppConstants.focusRewardPoints);

      final progress = await userProgressRepo.getUserProgress('default');
      if (progress != null) {
        await userProgressRepo.insertOrUpdateUserProgress(
          progress.copyWith(
            focusTimeTotalMinutes: progress.focusTimeTotalMinutes + minutes,
          ),
        );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Сессия завершена! $minutes минут фокуса'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final focusService = ref.read(focusServiceProvider);
    final theme = Theme.of(context);
    final elapsed = focusService.elapsed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Режим Монах'),
        actions: [
          if (focusService.isRunning)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopFocus,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade800,
              Colors.deepPurple.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Timer
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = _isPulsing
                        ? 1.0 + (_pulseController.value * 0.02)
                        : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 4,
                      ),
                      color: Colors.white.withOpacity(0.05),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatElapsed(elapsed),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w200,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatProgress(elapsed),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Task title
                if (focusService.currentTaskTitle != null)
                  Text(
                    focusService.currentTaskTitle!,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 32),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (focusService.isRunning) ...[
                      // Pause/Resume
                      _buildControlButton(
                        icon: focusService.isPaused
                            ? Icons.play_arrow
                            : Icons.pause,
                        label: focusService.isPaused
                            ? 'Продолжить'
                            : 'Пауза',
                        onTap: () {
                          if (focusService.isPaused) {
                            focusService.resume();
                            _pulseController.repeat(reverse: true);
                          } else {
                            focusService.pause();
                            _pulseController.stop();
                          }
                        },
                      ),
                      const SizedBox(width: 24),
                      _buildControlButton(
                        icon: Icons.stop,
                        label: 'Завершить',
                        onTap: _stopFocus,
                      ),
                    ] else ...[
                      _buildControlButton(
                        icon: Icons.play_arrow,
                        label: 'Начать',
                        onTap: _startFocus,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 48),

                // Tips
                if (!focusService.isRunning)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Начните фокус-сессию, чтобы погрузиться\nв глубокую работу без отвлечений',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  String _formatElapsed(Duration elapsed) {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);

    if (hours > 0) {
      return '${_pad(hours)}:${_pad(minutes)}:${_pad(seconds)}';
    }
    return '${_pad(minutes)}:${_pad(seconds)}';
  }

  String _pad(int value) => value.toString().padLeft(2, '0');

  String _formatProgress(Duration elapsed) {
    final minutes = elapsed.inMinutes;
    final target = AppConstants.focusDefaultDuration;
    return '$minutes / $target мин';
  }

  @override
  void dispose() {
    ref.read(focusServiceProvider).removeListener(_onFocusChanged);
    _pulseController.dispose();
    super.dispose();
  }
}
