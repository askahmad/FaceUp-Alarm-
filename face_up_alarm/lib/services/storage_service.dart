// lib/services/storage_service.dart
// FaceUp Alarm - Local Storage Service
// Ye service alarms aur history ko phone mein save karta hai
// SharedPreferences use karta hai - simple key-value storage

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';
import '../models/wake_history_model.dart';
import '../utils/app_constants.dart';

class StorageService {
  // Singleton pattern - poori app mein ek hi instance hoga
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  /// Initialize karo - app start hote hi call karo
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// _prefs ready hai ya nahi check karo
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError(
        'StorageService not initialized. Call init() first.',
      );
    }
    return _prefs!;
  }

  // ============================================================
  // ALARM OPERATIONS
  // ============================================================

  /// Saari alarms read karo
  List<AlarmModel> getAllAlarms() {
    try {
      final jsonString = prefs.getString(AppConstants.alarmsKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((item) {
            try {
              return AlarmModel.fromJson(item as Map<String, dynamic>);
            } catch (e) {
              // Agar koi alarm corrupt ho to skip karo, crash mat karo
              return null;
            }
          })
          .whereType<AlarmModel>()
          .toList();
    } catch (e) {
      // Corrupt data - empty list return karo
      return [];
    }
  }

  /// Ek naya alarm save karo
  Future<bool> saveAlarm(AlarmModel alarm) async {
    try {
      final alarms = getAllAlarms();

      // Check karo duplicate ID to nahi
      final existingIndex = alarms.indexWhere((a) => a.id == alarm.id);
      if (existingIndex >= 0) {
        // Update karo existing alarm
        alarms[existingIndex] = alarm;
      } else {
        // Naya alarm add karo
        alarms.add(alarm);
      }

      return await _saveAllAlarms(alarms);
    } catch (e) {
      return false;
    }
  }

  /// Alarm delete karo
  Future<bool> deleteAlarm(String alarmId) async {
    try {
      final alarms = getAllAlarms();
      alarms.removeWhere((a) => a.id == alarmId);
      return await _saveAllAlarms(alarms);
    } catch (e) {
      return false;
    }
  }

  /// Alarm enable/disable karo
  Future<bool> toggleAlarm(String alarmId, bool isEnabled) async {
    try {
      final alarms = getAllAlarms();
      final index = alarms.indexWhere((a) => a.id == alarmId);
      if (index < 0) return false;

      alarms[index] = alarms[index].copyWith(isEnabled: isEnabled);
      return await _saveAllAlarms(alarms);
    } catch (e) {
      return false;
    }
  }

  /// Ek specific alarm dhundho
  AlarmModel? getAlarmById(String alarmId) {
    final alarms = getAllAlarms();
    try {
      return alarms.firstWhere((a) => a.id == alarmId);
    } catch (_) {
      return null;
    }
  }

  /// Sirf enabled alarms
  List<AlarmModel> getEnabledAlarms() {
    return getAllAlarms().where((a) => a.isEnabled).toList();
  }

  // ============================================================
  // WAKE HISTORY
  // ============================================================

  /// Wake history save karo (jab alarm successfully band ho)
  Future<bool> saveWakeHistory(WakeHistoryModel history) async {
    try {
      final histories = getAllWakeHistory();
      histories.add(history);

      // Last 30 records hi rakhte hain
      final trimmed = histories.length > 30
          ? histories.sublist(histories.length - 30)
          : histories;

      final jsonString =
          jsonEncode(trimmed.map((h) => h.toJson()).toList());
      return await prefs.setString(AppConstants.wakeHistoryKey, jsonString);
    } catch (e) {
      return false;
    }
  }

  /// Saari wake history read karo
  List<WakeHistoryModel> getAllWakeHistory() {
    try {
      final jsonString = prefs.getString(AppConstants.wakeHistoryKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((item) {
            try {
              return WakeHistoryModel.fromJson(item as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<WakeHistoryModel>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  Future<bool> _saveAllAlarms(List<AlarmModel> alarms) async {
    final jsonString = jsonEncode(alarms.map((a) => a.toJson()).toList());
    return await prefs.setString(AppConstants.alarmsKey, jsonString);
  }

  /// Sab kuch clear karo (testing ke liye)
  Future<void> clearAll() async {
    await prefs.remove(AppConstants.alarmsKey);
    await prefs.remove(AppConstants.wakeHistoryKey);
  }
}
