// lib/services/alarm_service.dart
// FaceUp Alarm - Alarm Service
// Android AlarmManager aur native Kotlin channel ke sath connect karta hai

import 'dart:async';
import 'package:flutter/services.dart';
import '../models/alarm_model.dart';
import '../utils/app_constants.dart';
import '../utils/date_time_utils.dart';
import 'storage_service.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal() {
    _channel.setMethodCallHandler(_handleNativeMethodCall);
  }

  final MethodChannel _channel =
      const MethodChannel(AppConstants.alarmMethodChannel);
  final StorageService _storage = StorageService();

  // StreamController taake jab bhi native side se alarm trigger ho, UI ko pata chale
  final StreamController<String> _alarmTriggeredController =
      StreamController<String>.broadcast();
  Stream<String> get onAlarmTriggered => _alarmTriggeredController.stream;

  Future<void> _handleNativeMethodCall(MethodCall call) async {
    if (call.method == 'onAlarmTriggered') {
      final Map<dynamic, dynamic>? args =
          call.arguments as Map<dynamic, dynamic>?;
      final alarmId = args?['alarmId']?.toString() ?? '';
      if (alarmId.isNotEmpty) {
        _alarmTriggeredController.add(alarmId);
      }
    }
  }

  /// Alarm schedule karo (Local storage + Android AlarmManager)
  Future<bool> scheduleAlarm(AlarmModel alarm) async {
    try {
      // 1. Storage mein save karo
      await _storage.saveAlarm(alarm);

      if (!alarm.isEnabled) {
        // Agar disabled hai toh native alarm cancel karo
        await cancelNativeAlarm(alarm.androidAlarmId);
        return true;
      }

      // 2. Next trigger time calculate karo
      final nextTime = DateTimeUtils.getNextAlarmTime(
        alarm.hour,
        alarm.minute,
        alarm.repeatDays,
      );

      if (nextTime == null) {
        return false;
      }

      // 3. Android AlarmManager ko schedule karne ke liye pass karo
      final bool? success = await _channel.invokeMethod('scheduleAlarm', {
        'id': alarm.androidAlarmId,
        'triggerAtMillis': nextTime.millisecondsSinceEpoch,
        'alarmIdString': alarm.id,
        'ringtoneUri': alarm.ringtoneUri,
        'faceMode': alarm.faceMode,
      });

      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Native alarm cancel karo bina storage delete kiye
  Future<bool> cancelNativeAlarm(int androidAlarmId) async {
    try {
      final bool? success = await _channel.invokeMethod('cancelAlarm', {
        'id': androidAlarmId,
      });
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Alarm cancel aur delete karo
  Future<bool> cancelAlarm(String alarmId) async {
    try {
      final alarm = _storage.getAlarmById(alarmId);
      if (alarm != null) {
        await cancelNativeAlarm(alarm.androidAlarmId);
      }
      return await _storage.deleteAlarm(alarmId);
    } catch (_) {
      return false;
    }
  }

  /// Alarm toggle karo (ON / OFF)
  Future<bool> toggleAlarm(String alarmId, bool isEnabled) async {
    try {
      final alarm = _storage.getAlarmById(alarmId);
      if (alarm == null) return false;

      final updated = alarm.copyWith(isEnabled: isEnabled);
      return await scheduleAlarm(updated);
    } catch (_) {
      return false;
    }
  }

  /// Ringing alarm ko stop karo (Ringtone, vibration, notification band)
  Future<bool> stopAlarm() async {
    try {
      final bool? success = await _channel.invokeMethod('stopAlarm');
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Check karo exact alarm permission available hai ya nahi (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    try {
      final bool? canSchedule =
          await _channel.invokeMethod('canScheduleExactAlarms');
      return canSchedule ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Exact alarm permission request settings open karo
  Future<bool> requestExactAlarmPermission() async {
    try {
      final bool? success =
          await _channel.invokeMethod('requestExactAlarmPermission');
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Agar app cold start hui hai aur alarm baj raha hai toh alarmId lo
  Future<String?> getActiveRingingAlarmId() async {
    try {
      final String? alarmId =
          await _channel.invokeMethod('getActiveRingingAlarmId');
      return (alarmId != null && alarmId.isNotEmpty) ? alarmId : null;
    } catch (_) {
      return null;
    }
  }

  /// Phone reboot ke baad saari enabled alarms restore karo
  Future<void> restoreAlarmsAfterBoot() async {
    final enabledAlarms = _storage.getEnabledAlarms();
    for (final alarm in enabledAlarms) {
      await scheduleAlarm(alarm);
    }
  }
}
