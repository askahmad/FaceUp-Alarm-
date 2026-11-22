// test/widget_test.dart
// FaceUp Alarm - Comprehensive Tests for Step 1, 2, 3, 4, and 5

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:face_up_alarm/main.dart';
import 'package:face_up_alarm/models/alarm_model.dart';
import 'package:face_up_alarm/services/storage_service.dart';
import 'package:face_up_alarm/services/face_detection_service.dart';
import 'package:face_up_alarm/utils/date_time_utils.dart';
import 'package:face_up_alarm/screens/set_alarm_screen.dart';
import 'package:face_up_alarm/screens/alarm_ringing_screen.dart';
import 'package:face_up_alarm/widgets/face_guide.dart';
import 'package:face_up_alarm/widgets/verification_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    await StorageService().init();

    // Mock ML Kit method channels
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('google_mlkit_face_detector'),
      (MethodCall methodCall) async {
        return null;
      },
    );
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
      expect(fromJson.androidAlarmId > 0, true);
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

    test('getNextAlarmTime never schedules in the past', () {
      final now = DateTime.now();
      // Schedule an alarm for 1 hour ago
      final pastHour = (now.hour - 1 + 24) % 24;
      final nextTime = DateTimeUtils.getNextAlarmTime(pastHour, now.minute, []);

      expect(nextTime != null, true);
      expect(nextTime!.isAfter(now), true);
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

  group('Step 5 FaceDetectionService Unit Tests', () {
    test('FaceDetectionService initializes with blink and smile challenge',
        () async {
      final service = FaceDetectionService();

      service.init(challenge: FaceChallengeType.blink);
      expect(service.activeChallenge, FaceChallengeType.blink);
      expect(service.activeChallengeUrdu, 'ایک بار پلک جھپکائیں');
      expect(service.activeChallengeEng, 'Blink Once');

      service.init(challenge: FaceChallengeType.smile);
      expect(service.activeChallenge, FaceChallengeType.smile);
      expect(service.activeChallengeUrdu, 'مسکرائیں');
      expect(service.activeChallengeEng, 'Smile');

      await service.dispose();
    });

    test('VerificationResult default state and properties', () {
      const result = VerificationResult(
        state: VerificationState.holding,
        messageUrdu: 'تین سیکنڈ رکیں',
        messageEng: 'Hold for 3 seconds',
        holdProgress: 0.66,
        isVerified: false,
        leftEyeOpen: 0.95,
        rightEyeOpen: 0.92,
      );

      expect(result.state, VerificationState.holding);
      expect(result.holdProgress, 0.66);
      expect(result.isVerified, false);
      expect(result.leftEyeOpen, 0.95);
      expect(result.rightEyeOpen, 0.92);
    });
  });

  group('Step 4 & 5 Widgets Tests', () {
    testWidgets('FaceGuide renders circle cutout and status labels',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FaceGuide(
              status: FaceGuideStatus.searching,
              statusUrdu: 'چہرہ دائرے میں لائیں',
              statusEng: 'Align face in circle',
            ),
          ),
        ),
      );

      expect(find.text('چہرہ دائرے میں لائیں'), findsOneWidget);
      expect(find.text('Align face in circle'), findsOneWidget);
    });

    testWidgets('VerificationProgress renders 3 stages and challenge badge',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VerificationProgress(
              currentStage: 2,
              holdProgress: 0.5,
              activeChallengeLabel: 'ایک بار پلک جھپکائیں / Blink Once',
            ),
          ),
        ),
      );

      // 3 stages
      expect(find.text('چہرہ تلاش کر رہے ہیں'), findsOneWidget);
      expect(find.text('آنکھیں کھلی رکھیں'), findsOneWidget);
      expect(find.text('تین سیکنڈ رکیں'), findsOneWidget);

      // Challenge badge
      expect(
          find.text('ایک بار پلک جھپکائیں / Blink Once'), findsOneWidget);
    });
  });

  group('Widget UI Screens Tests', () {
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

    testWidgets(
        'AlarmRingingScreen displays face guide, stages and privacy label',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AlarmRingingScreen(alarmId: 'test_alarm_1'),
        ),
      );
      await tester.pump();

      // Headings
      expect(find.text('اٹھ جائیں! اپنا چہرہ دکھائیں'), findsOneWidget);
      expect(find.text('Wake up! Show your face.'), findsOneWidget);

      // Verification stages
      expect(find.text('چہرہ تلاش کر رہے ہیں'), findsOneWidget);
      expect(find.text('آنکھیں کھلی رکھیں'), findsOneWidget);
      expect(find.text('تین سیکنڈ رکیں'), findsOneWidget);

      // Privacy assurance
      expect(find.textContaining('آپ کی تصویر کہیں محفوظ نہیں ہوتی'),
          findsOneWidget);
    });
  });
}
