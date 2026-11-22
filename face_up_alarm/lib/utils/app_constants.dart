// lib/utils/app_constants.dart
// FaceUp Alarm - App Constants
// Ye file poori app ki settings aur constants store karti hai

class AppConstants {
  // ============================================================
  // APP INFO
  // ============================================================
  static const String appName = 'FaceUp Alarm';
  static const String appNameUrdu = 'چہرہ الارم';
  static const String appVersion = '1.0.0';

  // ============================================================
  // SHARED PREFERENCES KEYS
  // SharedPreferences mein data in keys ke sath save hota hai
  // ============================================================
  static const String alarmsKey = 'alarms';
  static const String wakeHistoryKey = 'wake_history';

  // ============================================================
  // FACE DETECTION THRESHOLDS
  // ML Kit face detection ki sensitivity settings
  // ============================================================

  // Eye open probability - 0.0 = closed, 1.0 = fully open
  // 0.7 matlab: 70% chance eye open hai
  static const double eyeOpenThreshold = 0.7;

  // Eye closed probability for blink detection
  // Blink tab detect hoga jab eye 30% se kam open hogi
  static const double eyeClosedThreshold = 0.3;

  // Smile probability threshold
  // 0.7 matlab: 70% chance smile hai
  static const double smileThreshold = 0.7;

  // Face size minimum - face itna bada hona chahiye
  // 0.15 matlab: frame ka 15% area cover kare
  static const double minimumFaceSizeRatio = 0.15;

  // ============================================================
  // ALARM VERIFICATION SETTINGS
  // ============================================================

  // Alarm band karne ke liye kitne seconds tak face dikhana hai
  static const int holdDurationSeconds = 3;

  // Challenge complete karne ka max time (seconds)
  static const int challengeTimeoutSeconds = 15;

  // Blink detect karne ka time window
  static const int blinkTimeWindowMs = 2000;

  // Consecutive frames needed for smile confirmation
  static const int smileConfirmationFrames = 5;

  // ============================================================
  // ALARM SETTINGS
  // ============================================================

  // Default alarm audio stream volume (0.0 to 1.0)
  // We use Android's alarm stream which manages this natively
  static const int maxAlarms = 20;

  // ============================================================
  // METHOD CHANNEL
  // Flutter aur Android (Kotlin) ke beech communication ka bridge
  // ============================================================
  static const String alarmMethodChannel = 'com.faceup/alarm_manager';
  static const String ringtoneMethodChannel = 'com.faceup/ringtone';

  // ============================================================
  // NOTIFICATION IDs
  // Har notification ka alag ID hona chahiye
  // ============================================================
  static const String notificationChannelId = 'faceup_alarm_channel';
  static const String notificationChannelName = 'FaceUp Alarm';
  static const String notificationChannelDesc =
      'FaceUp Alarm - چہرہ الارم notifications';

  // ============================================================
  // REPEAT DAYS
  // Week ke din - Android Calendar ke standards follow karte hain
  // Android: 1 = Sunday, 2 = Monday ... 7 = Saturday
  // ============================================================
  static const Map<int, String> dayNames = {
    2: 'پیر\nMon',
    3: 'منگل\nTue',
    4: 'بدھ\nWed',
    5: 'جمعرات\nThu',
    6: 'جمعہ\nFri',
    7: 'ہفتہ\nSat',
    1: 'اتوار\nSun',
  };

  // Day names short form for display
  static const Map<int, String> dayNamesShort = {
    2: 'Mon',
    3: 'Tue',
    4: 'Wed',
    5: 'Thu',
    6: 'Fri',
    7: 'Sat',
    1: 'Sun',
  };

  // ============================================================
  // PRIVACY MESSAGE
  // Ye message poori app mein dikhaya jata hai
  // ============================================================
  static const String privacyMessage =
      'آپ کی تصویر کہیں محفوظ نہیں ہوتی\nYour face image is never stored.';
}
