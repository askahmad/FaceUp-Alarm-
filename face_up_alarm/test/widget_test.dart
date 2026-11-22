// test/widget_test.dart
// FaceUp Alarm - Comprehensive Tests for Step 2

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:face_up_alarm/main.dart';
import 'package:face_up_alarm/models/alarm_model.dart';
import 'package:face_up_alarm/services/storage_service.dart';
import 'package:face_up_alarm/utils/date_time_utils.dart';
import 'package:face_up_alarm/screens/set_alarm_screen.dart';

void main() {
  setUp(() async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    await StorageService().init();
  });

  group('AlarmModel Tests', () {
    test('Create AlarmModel and serialize to JSON and back', () {
      final alarm = AlarmModel.create(
        hour: 6,
        minute: 30,
        repeatDays: [2, 3, 4, 5, 6],
        faceMode: true,
        ringtoneName: 'Test Ringtone',
      );

      final json = alarm.toJson();
      final fromJson = AlarmModel.fromJson(json);

      expect(fromJson.id, alarm.id);
      expect(fromJson.hour, 6);
      expect(fromJson.minute, 30);
      expect(fromJson.repeatDays, [2, 3, 4, 5, 6]);
      expect(fromJson.faceMode, true);
      expect(fromJson.isEnabled, true);
      expect(fromJson.ringtoneName, 'Test Ringtone');
    });

    test('AlarmModel copyWith updates fields properly', () {
      final alarm = AlarmModel.create(hour: 7, minute: 0);
      final updated = alarm.copyWith(hour: 8, isEnabled: false);

      expect(updated.hour, 8);
      expect(updated.minute, 0);
      expect(updated.isEnabled, false);
      expect(updated.id, alarm.id);
    });
  });

  group('DateTimeUtils Tests', () {
    test('formatTime12Hour formats properly for AM and PM', () {
      expect(DateTimeUtils.formatTime12Hour(7, 5), '7:05 AM');
      expect(DateTimeUtils.formatTime12Hour(0, 0), '12:00 AM');
      expect(DateTimeUtils.formatTime12Hour(12, 0), '12:00 PM');
      expect(DateTimeUtils.formatTime12Hour(23, 45), '11:45 PM');
    });

    test('getRepeatDaysLabel shows accurate text', () {
      expect(DateTimeUtils.getRepeatDaysLabel([]), 'صرف ایک بار / One time');
      expect(DateTimeUtils.getRepeatDaysLabel([2, 3, 4, 5, 6]),
          'پیر تا جمعہ / Weekdays');
      expect(DateTimeUtils.getRepeatDaysLabel([1, 2, 3, 4, 5, 6, 7]),
          'ہر روز / Every day');
    });
  });

  group('StorageService Tests', () {
    test('saveAlarm, getAllAlarms, toggleAlarm and deleteAlarm', () async {
      final storage = StorageService();
      final alarm = AlarmModel.create(hour: 7, minute: 15);

      final saved = await storage.saveAlarm(alarm);
      expect(saved, true);

      final alarms = storage.getAllAlarms();
      expect(alarms.length, 1);
      expect(alarms.first.id, alarm.id);

      // Toggle
      await storage.toggleAlarm(alarm.id, false);
      expect(storage.getAllAlarms().first.isEnabled, false);

      // Delete
      await storage.deleteAlarm(alarm.id);
      expect(storage.getAllAlarms().isEmpty, true);
    });
  });

  group('Widget UI Tests', () {
    testWidgets('Home Screen displays empty state when no alarms are saved',
        (WidgetTester tester) async {
      await tester.pumpWidget(const FaceUpAlarmApp());
      await tester.pumpAndSettle();

      // App branding
      expect(find.text('چہرہ الارم'), findsOneWidget);
      expect(find.text('FaceUp Alarm'), findsOneWidget);

      // Empty state
      expect(find.text('ابھی کوئی الارم نہیں لگا'), findsOneWidget);
      expect(find.text('No alarm is set yet.'), findsOneWidget);

      // Set Alarm button
      expect(find.text('الارم لگائیں / Set Alarm'), findsOneWidget);

      // Privacy message
      expect(find.textContaining('آپ کی تصویر کہیں محفوظ نہیں ہوتی'),
          findsOneWidget);
    });

    testWidgets('SetAlarmScreen renders time, chips, face mode toggle and save',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SetAlarmScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Heading
      expect(find.text('الارم لگائیں / Set Alarm'), findsOneWidget);

      // Face mode toggle
      expect(
          find.text('چہرہ دکھا کر بند کریں / Face Mode'), findsOneWidget);

      // Save button
      expect(find.text('الارم محفوظ کریں / Save Alarm'), findsOneWidget);
    });
  });
}
