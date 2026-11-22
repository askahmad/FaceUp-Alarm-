// lib/models/wake_history_model.dart
// FaceUp Alarm - Wake-up History Data Model
// Jab bhi user successfully face se alarm band kare, ye record hota hai

import 'dart:convert';

class WakeHistoryModel {
  final String alarmId; // Kis alarm ki wajah se utha
  final int wakeTime; // Kab utha (milliseconds since epoch)
  final int scheduledTime; // Alarm kab schedule thi

  const WakeHistoryModel({
    required this.alarmId,
    required this.wakeTime,
    required this.scheduledTime,
  });

  // Factory: JSON se banao
  factory WakeHistoryModel.fromJson(Map<String, dynamic> json) {
    return WakeHistoryModel(
      alarmId: json['alarmId'] as String? ?? '',
      wakeTime: json['wakeTime'] as int? ?? 0,
      scheduledTime: json['scheduledTime'] as int? ?? 0,
    );
  }

  // JSON mein convert karo
  Map<String, dynamic> toJson() {
    return {
      'alarmId': alarmId,
      'wakeTime': wakeTime,
      'scheduledTime': scheduledTime,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  // Human readable wake time
  DateTime get wakeDateTime => DateTime.fromMillisecondsSinceEpoch(wakeTime);
  DateTime get scheduledDateTime =>
      DateTime.fromMillisecondsSinceEpoch(scheduledTime);

  // Kitni der late utha (minutes mein)
  int get minutesLate {
    final diff = wakeTime - scheduledTime;
    return (diff / 60000).round(); // milliseconds to minutes
  }

  @override
  String toString() {
    return 'WakeHistoryModel(alarmId: $alarmId, wakeTime: ${wakeDateTime.toString()})';
  }
}
