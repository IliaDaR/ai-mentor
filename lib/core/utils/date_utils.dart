import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final _dateFormat = DateFormat('yyyy-MM-dd');
  static final _timeFormat = DateFormat('HH:mm');
  static final _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final _ruDateFormat = DateFormat('d MMMM yyyy', 'ru');
  static final _ruDayFormat = DateFormat('EEEE', 'ru');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatTime(DateTime date) => _timeFormat.format(date);
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
  static String formatRuDate(DateTime date) => _ruDateFormat.format(date);
  static String formatRuDay(DateTime date) {
    final day = _ruDayFormat.format(date);
    return '${day[0].toUpperCase()}${day.substring(1)}';
  }

  static String formatDuration(int minutes) {
    if (minutes < 60) return '$minutes мин';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours ч';
    return '$hours ч $mins мин';
  }

  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    if (diff.inDays < 7) return '${diff.inDays} дн назад';
    return formatDate(dateTime);
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isOverdue(DateTime? deadline) {
    if (deadline == null) return false;
    return deadline.isBefore(DateTime.now());
  }

  static String formatCountdown(DateTime dateTime) {
    final diff = dateTime.difference(DateTime.now());
    if (diff.isNegative) return 'Просрочено';
    if (diff.inDays > 0) return '${diff.inDays} д ${diff.inHours % 24} ч';
    if (diff.inHours > 0) return '${diff.inHours} ч ${diff.inMinutes % 60} мин';
    if (diff.inMinutes > 0) return '${diff.inMinutes} мин';
    return 'Скоро';
  }

  static int toMinutes(Duration duration) {
    return duration.inMinutes;
  }

  static Duration fromMinutes(int minutes) {
    return Duration(minutes: minutes);
  }
}
