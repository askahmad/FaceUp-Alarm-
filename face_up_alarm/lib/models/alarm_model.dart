// lib/models/alarm_model.dart
// FaceUp Alarm - Alarm Data Model
// Ye class ek alarm ki saari information store karti hai

import 'dart:convert';

class AlarmModel {
  final String id; // Unique ID - timestamp se banate hain
  final int hour; // 0-23 (24-hour format)
  final int minute; // 0-59
  final List<int> repeatDays; // Android days: 1=Sun, 2=Mon...7=Sat
  final String ringtoneUri; // Android ringtone content URI
  final String ringtoneName; // Display name: "Default Alarm"
  final bool faceMode; // true = face se band karna hoga
  final bool isEnabled; // true = alarm active hai
  final int createdAt; // Milliseconds since epoch

  const AlarmModel({
    required this.id,
    required this.hour,
    required this.minute,
    this.repeatDays = const [],
    this.ringtoneUri = '',
    this.ringtoneName = 'ڈیفالٹ / Default',
    this.faceMode = true,
    this.isEnabled = true,
    required this.createdAt,
  });

  // ============================================================
  // FACTORY CONSTRUCTORS
  // ============================================================

  /// Naya alarm banao
  factory AlarmModel.create({
    required int hour,
    required int minute,
    List<int> repeatDays = const [],
    String ringtoneUri = '',
    String ringtoneName = 'ڈیفالٹ / Default',
    bool faceMode = true,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return AlarmModel(
      id: 'alarm_$now',
      hour: hour,
      minute: minute,
      repeatDays: repeatDays,
      ringtoneUri: ringtoneUri,
      ringtoneName: ringtoneName,
      faceMode: faceMode,
      isEnabled: true,
      createdAt: now,
    );
  }

  /// JSON se AlarmModel banao (SharedPreferences se read karte waqt)
  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'] as String? ?? 'alarm_unknown',
      hour: json['hour'] as int? ?? 7,
      minute: json['minute'] as int? ?? 0,
      repeatDays: (json['repeatDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      ringtoneUri: json['ringtoneUri'] as String? ?? '',
      ringtoneName: json['ringtoneName'] as String? ?? 'ڈیفالٹ / Default',
      faceMode: json['faceMode'] as bool? ?? true,
      isEnabled: json['isEnabled'] as bool? ?? true,
      createdAt: json['createdAt'] as int? ?? 0,
    );
  }

  /// JSON String se AlarmModel banao
  factory AlarmModel.fromJsonString(String jsonString) {
    return AlarmModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  // ============================================================
  // SERIALIZATION - JSON mein convert karna
  // ============================================================

  /// AlarmModel ko JSON Map mein convert karo
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'repeatDays': repeatDays,
      'ringtoneUri': ringtoneUri,
      'ringtoneName': ringtoneName,
      'faceMode': faceMode,
      'isEnabled': isEnabled,
      'createdAt': createdAt,
    };
  }

  /// JSON Map ko String mein convert karo (storage ke liye)
  String toJsonString() => jsonEncode(toJson());

  // ============================================================
  // COPY WITH - Partial update ke liye
  // ============================================================

  /// Existing alarm ki copy banao kuch fields change karke
  AlarmModel copyWith({
    String? id,
    int? hour,
    int? minute,
    List<int>? repeatDays,
    String? ringtoneUri,
    String? ringtoneName,
    bool? faceMode,
    bool? isEnabled,
    int? createdAt,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatDays: repeatDays ?? this.repeatDays,
      ringtoneUri: ringtoneUri ?? this.ringtoneUri,
      ringtoneName: ringtoneName ?? this.ringtoneName,
      faceMode: faceMode ?? this.faceMode,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ============================================================
  // COMPUTED PROPERTIES
  // ============================================================

  /// One-time alarm hai ya repeating?
  bool get isRepeating => repeatDays.isNotEmpty;

  /// Alarm ID ko integer mein convert (AlarmManager ke liye)
  /// AlarmManager ko int ID chahiye hoti hai
  int get androidAlarmId {
    // ID format: "alarm_1700000000000"
    // Last 9 digits use karo (integer overflow se bachne ke liye)
    final parts = id.split('_');
    if (parts.length >= 2) {
      final ms = int.tryParse(parts.last) ?? 0;
      return ms % 2147483647; // Max int value se modulo
    }
    return createdAt % 2147483647;
  }

  @override
  String toString() {
    return 'AlarmModel(id: $id, time: $hour:$minute, enabled: $isEnabled, faceMode: $faceMode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlarmModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
