// lib/services/alarm_service.dart
// FaceUp Alarm - Alarm Service (STEP 3 mein fully implement hogi)
// Ye service alarms schedule aur cancel karti hai

import '../models/alarm_model.dart';
import 'storage_service.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final StorageService _storage = StorageService();

  /// Alarm schedule karo aur save karo
  Future<bool> scheduleAlarm(AlarmModel alarm) async {
    // STEP 3 mein implement hoga - Android AlarmManager integration
    // Abhi sirf storage mein save karo
    return await _storage.saveAlarm(alarm);
  }

  /// Alarm cancel karo
  Future<bool> cancelAlarm(String alarmId) async {
    // STEP 3 mein implement hoga - Android AlarmManager cancel
    // Abhi sirf storage se delete karo
    return await _storage.deleteAlarm(alarmId);
  }

  /// Alarm toggle karo (on/off)
  Future<bool> toggleAlarm(String alarmId, bool isEnabled) async {
    return await _storage.toggleAlarm(alarmId, isEnabled);
  }

  /// Reboot ke baad saari enabled alarms restore karo
  Future<void> restoreAlarmsAfterBoot() async {
    // STEP 6 mein implement hoga
    final enabledAlarms = _storage.getEnabledAlarms();
    for (final alarm in enabledAlarms) {
      await scheduleAlarm(alarm);
    }
  }
}
