// lib/utils/date_time_utils.dart
// FaceUp Alarm - Date aur Time utility functions
// Ye simple helper functions hain jo time ke sath kaam karti hain

class DateTimeUtils {
  // ============================================================
  // TIME FORMATTING
  // Time ko readable format mein convert karna
  // ============================================================

  /// 24-hour time ko 12-hour format mein convert karo
  /// Example: hour=14, minute=30 → "2:30 PM"
  static String formatTime12Hour(int hour, int minute) {
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  /// Current time ko readable format mein dikhao
  static String formatCurrentTime(DateTime now) {
    return formatTime12Hour(now.hour, now.minute);
  }

  /// Seconds ko readable format mein dikhao (3 → "00:03")
  static String formatCountdown(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  // ============================================================
  // NEXT ALARM CALCULATION
  // Agli alarm kab bajegi ye calculate karna
  // ============================================================

  /// Alarm ke liye next DateTime calculate karo
  /// repeatDays: empty list = one-time alarm
  /// repeatDays: [2,3,4,5,6] = Mon-Fri
  static DateTime? getNextAlarmTime(
    int hour,
    int minute,
    List<int> repeatDays,
  ) {
    final now = DateTime.now();
    final todayWithAlarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (repeatDays.isEmpty) {
      // One-time alarm
      if (todayWithAlarmTime.isAfter(now)) {
        // Aaj ke baad hai
        return todayWithAlarmTime;
      } else {
        // Aaj ka time guzar gaya, kal ke liye schedule karo
        return todayWithAlarmTime.add(const Duration(days: 1));
      }
    }

    // Repeating alarm - agle repeat day dhundho
    // Android Calendar: 1=Sunday, 2=Monday...7=Saturday
    for (int i = 0; i < 8; i++) {
      final checkDate = now.add(Duration(days: i));
      final checkDateTime = DateTime(
        checkDate.year,
        checkDate.month,
        checkDate.day,
        hour,
        minute,
      );

      // Android weekday: 1=Sunday, Dart weekday: 1=Monday
      // Convert karo: Dart (1=Mon,7=Sun) → Android (2=Mon,1=Sun)
      final dartWeekday = checkDate.weekday; // 1=Mon...7=Sun
      final androidDay = dartWeekday == 7 ? 1 : dartWeekday + 1;

      if (repeatDays.contains(androidDay) &&
          checkDateTime.isAfter(now)) {
        return checkDateTime;
      }
    }

    return null;
  }

  /// Next alarm ka human-readable description
  /// Example: "Kal subah 7:00 AM" ya "Aaj raat 11:30 PM"
  static String getNextAlarmDescription(
    int hour,
    int minute,
    List<int> repeatDays,
  ) {
    final nextTime = getNextAlarmTime(hour, minute, repeatDays);
    if (nextTime == null) return 'کوئی آنے والی alarm نہیں';

    final now = DateTime.now();
    final timeStr = formatTime12Hour(hour, minute);

    final diff = nextTime.difference(now);

    if (diff.inDays == 0) {
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      if (hours > 0) {
        return '$timeStr • $hours گھنٹے بعد';
      } else {
        return '$timeStr • $minutes منٹ بعد';
      }
    } else if (diff.inDays == 1) {
      return '$timeStr • کل';
    } else {
      return '$timeStr • ${diff.inDays} دن بعد';
    }
  }

  /// Repeat days ki list ko readable string mein convert karo
  /// Example: [2,3,4,5,6] → "پیر تا جمعہ"
  static String getRepeatDaysLabel(List<int> repeatDays) {
    if (repeatDays.isEmpty) return 'صرف ایک بار / One time';

    // All weekdays
    final weekdays = [2, 3, 4, 5, 6];
    final weekend = [7, 1];
    final allDays = [1, 2, 3, 4, 5, 6, 7];

    if (repeatDays.toSet().containsAll(allDays.toSet()) &&
        allDays.toSet().containsAll(repeatDays.toSet())) {
      return 'ہر روز / Every day';
    }

    if (repeatDays.toSet().containsAll(weekdays.toSet()) &&
        weekdays.toSet().containsAll(repeatDays.toSet())) {
      return 'پیر تا جمعہ / Weekdays';
    }

    if (repeatDays.toSet().containsAll(weekend.toSet()) &&
        weekend.toSet().containsAll(repeatDays.toSet())) {
      return 'ہفتہ اتوار / Weekend';
    }

    // Individual days
    const dayLabels = {
      1: 'اتوار',
      2: 'پیر',
      3: 'منگل',
      4: 'بدھ',
      5: 'جمعرات',
      6: 'جمعہ',
      7: 'ہفتہ',
    };

    // Sort by Android day order: Sun=1, Mon=2...Sat=7
    final sorted = List<int>.from(repeatDays)..sort();
    return sorted.map((d) => dayLabels[d] ?? '').join('، ');
  }

  /// Current date ko Urdu format mein dikhao
  static String getTodayLabel() {
    final now = DateTime.now();
    const months = [
      '',
      'جنوری',
      'فروری',
      'مارچ',
      'اپریل',
      'مئی',
      'جون',
      'جولائی',
      'اگست',
      'ستمبر',
      'اکتوبر',
      'نومبر',
      'دسمبر',
    ];
    return '${now.day} ${months[now.month]} ${now.year}';
  }

  /// Milliseconds se DateTime banao
  static DateTime fromMilliseconds(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms);

  /// DateTime ko milliseconds mein convert karo
  static int toMilliseconds(DateTime dt) => dt.millisecondsSinceEpoch;
}
