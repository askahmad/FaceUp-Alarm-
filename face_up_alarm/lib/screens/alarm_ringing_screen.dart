// lib/screens/alarm_ringing_screen.dart
// FaceUp Alarm - Alarm Ringing Screen (SCREEN 3)
// Step 3: Alarm sound + vibration + full-screen launch + stop control

import 'package:flutter/material.dart';
import '../services/alarm_service.dart';
import '../services/storage_service.dart';
import '../models/alarm_model.dart';
import '../models/wake_history_model.dart';
import '../utils/app_theme.dart';
import '../utils/date_time_utils.dart';

class AlarmRingingScreen extends StatefulWidget {
  final String alarmId;

  const AlarmRingingScreen({
    super.key,
    required this.alarmId,
  });

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen>
    with SingleTickerProviderStateMixin {
  final AlarmService _alarmService = AlarmService();
  final StorageService _storage = StorageService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  AlarmModel? _alarm;
  bool _isSuccess = false;
  String _successTime = '';

  @override
  void initState() {
    super.initState();
    _alarm = _storage.getAlarmById(widget.alarmId);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _dismissAlarm() async {
    // 1. Stop native ringing and vibration
    await _alarmService.stopAlarm();

    // 2. Record wake history
    final now = DateTime.now();
    final history = WakeHistoryModel(
      alarmId: widget.alarmId,
      wakeTime: now.millisecondsSinceEpoch,
      scheduledTime: _alarm != null
          ? DateTime(
              now.year,
              now.month,
              now.day,
              _alarm!.hour,
              _alarm!.minute,
            ).millisecondsSinceEpoch
          : now.millisecondsSinceEpoch,
    );
    await _storage.saveWakeHistory(history);

    // 3. Show success state
    if (mounted) {
      setState(() {
        _isSuccess = true;
        _successTime =
            DateTimeUtils.formatTime12Hour(now.hour, now.minute);
      });

      // 2 seconds success animation then return to Home
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context, true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = _alarm != null
        ? DateTimeUtils.formatTime12Hour(_alarm!.hour, _alarm!.minute)
        : DateTimeUtils.formatTime12Hour(now.hour, now.minute);

    return PopScope(
      canPop: false, // Step 6 requirement: Block back button while ringing!
      child: Scaffold(
        backgroundColor:
            _isSuccess ? AppTheme.accentGreen : AppTheme.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingL,
              vertical: AppTheme.spacingXL,
            ),
            child: _isSuccess ? _buildSuccessView() : _buildRingingView(timeStr),
          ),
        ),
      ),
    );
  }

  Widget _buildRingingView(String timeStr) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Top section: Urdu & English Heading
          Column(
            children: [
              const SizedBox(height: AppTheme.spacingM),
              const Text(
                'اٹھ جائیں! اپنا چہرہ دکھائیں',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Wake up! Show your face.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              // Current ringing time
              Text(
                timeStr,
                style: AppTheme.clockStyle.copyWith(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlueDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingM),

          // Center section: Pulsing Alarm Icon / Face Verification placeholder
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryBlueLight.withValues(alpha: 0.4),
                border: Border.all(
                  color: AppTheme.primaryBlue,
                  width: 3,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.alarm_on_rounded,
                  size: 70,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingL),

          // 3 Verification Stages Display
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              boxShadow: AppTheme.cardShadow,
            ),
            child: const Column(
              children: [
                _StageRow(
                  icon: Icons.face_retouching_natural_rounded,
                  stageNumber: '1',
                  urduText: 'چہرہ تلاش کر رہے ہیں',
                  engText: 'Face Detection',
                ),
                Divider(height: 16),
                _StageRow(
                  icon: Icons.visibility_rounded,
                  stageNumber: '2',
                  urduText: 'آنکھیں کھلی رکھیں',
                  engText: 'Eyes Open',
                ),
                Divider(height: 16),
                _StageRow(
                  icon: Icons.timer_rounded,
                  stageNumber: '3',
                  urduText: 'تین سیکنڈ رکیں',
                  engText: 'Hold for 3 Seconds',
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingL),

          // Step 3 Test Control: Stop Alarm Button
          // (Step 4-5 will gate this behind camera & ML Kit detection)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _dismissAlarm,
              icon: const Icon(Icons.stop_circle_rounded, size: 28),
              label: const Text(
                'الارم بند کریں / Stop Alarm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingM),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppTheme.accentGreen,
              size: 72,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          const Text(
            'شاباش! آپ اٹھ گئے',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'آج آپ $_successTime پر اٹھے',
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  final IconData icon;
  final String stageNumber;
  final String urduText;
  final String engText;

  const _StageRow({
    required this.icon,
    required this.stageNumber,
    required this.urduText,
    required this.engText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppTheme.primaryBlueLight,
          child: Text(
            stageNumber,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlueDark,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Icon(icon, color: AppTheme.primaryBlue, size: 22),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                urduText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                engText,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
