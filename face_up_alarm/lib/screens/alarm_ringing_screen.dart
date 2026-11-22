// lib/screens/alarm_ringing_screen.dart
// FaceUp Alarm - Alarm Ringing Screen (STEP 4-5 mein implement hogi)
// Ye abhi placeholder hai

import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class AlarmRingingScreen extends StatelessWidget {
  final String alarmId;

  const AlarmRingingScreen({
    super.key,
    required this.alarmId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.alarm, size: 64, color: AppTheme.primaryBlue),
            const SizedBox(height: 16),
            const Text(
              'اٹھ جائیں! اپنا چہرہ دکھائیں',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text('Wake up! Show your face.'),
            const SizedBox(height: 16),
            Text(
              'Alarm ID: $alarmId',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text(
              'STEP 4-5 mein implement hogi',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
