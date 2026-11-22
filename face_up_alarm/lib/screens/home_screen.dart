// lib/screens/home_screen.dart
// FaceUp Alarm - Home Screen (SCREEN 1)
// Clean, premium, friendly interface displaying alarms, clock, and controls

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/alarm_model.dart';
import '../services/storage_service.dart';
import '../services/alarm_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/date_time_utils.dart';
import '../widgets/alarm_card.dart';
import 'set_alarm_screen.dart';
import 'alarm_ringing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  final AlarmService _alarmService = AlarmService();

  List<AlarmModel> _alarms = [];
  Timer? _clockTimer;
  StreamSubscription<String>? _alarmSubscription;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAlarms();

    // Clock update timer (every 1 second)
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    // Listen to native alarm triggers
    _alarmSubscription = _alarmService.onAlarmTriggered.listen((alarmId) {
      if (mounted) {
        _openAlarmRingingScreen(alarmId);
      }
    });

    // Check if an alarm is already ringing on cold launch
    _checkActiveAlarm();
  }

  Future<void> _checkActiveAlarm() async {
    final activeId = await _alarmService.getActiveRingingAlarmId();
    if (activeId != null && mounted) {
      _openAlarmRingingScreen(activeId);
    }
  }

  void _openAlarmRingingScreen(String alarmId) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmRingingScreen(alarmId: alarmId),
      ),
    );
    _loadAlarms();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _alarmSubscription?.cancel();
    super.dispose();
  }

  void _loadAlarms() {
    setState(() {
      _alarms = _storage.getAllAlarms();
      // Sort alarms by time (hour then minute)
      _alarms.sort((a, b) {
        if (a.hour != b.hour) return a.hour.compareTo(b.hour);
        return a.minute.compareTo(b.minute);
      });
    });
  }

  void _onToggleAlarm(AlarmModel alarm, bool isEnabled) async {
    await _alarmService.toggleAlarm(alarm.id, isEnabled);
    _loadAlarms();
  }

  void _onDeleteAlarm(AlarmModel alarm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الارم ڈیلیٹ کریں؟'),
        content: Text(
          '${DateTimeUtils.formatTime12Hour(alarm.hour, alarm.minute)} الارم ختم کرنا چاہتے ہیں؟\nAre you sure you want to delete this alarm?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('نہیں / Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ڈیلیٹ / Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _alarmService.cancelAlarm(alarm.id);
      _loadAlarms();
    }
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: AppTheme.accentGreen),
            SizedBox(width: 8),
            Text('پرائیویسی کی ضمانت'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'آپ کا ڈیٹا 100% محفوظ ہے',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                '1. کیمرے کی کوئی تصویر یا ویڈیو محفوظ نہیں ہوتی۔\n'
                '2. چہرے کی تصدیق فون کے اندر ہی Google ML Kit کے ذریعے آف لائن ہوتی ہے۔\n'
                '3. کوئی سرور، کوئی اکاؤنٹ اور کوئی ٹریکنگ موجود نہیں ہے۔\n'
                '4. صرف آپ کے الارم کے اوقات اور جاگنے کا وقت فون میں محفوظ رہتا ہے۔\n\n'
                'Privacy Commitment:\n'
                '• No camera frames or face images are ever stored or uploaded.\n'
                '• 100% on-device local face detection.\n'
                '• No analytics, no server, and zero tracking.',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('سمجھ گیا / Got it'),
          ),
        ],
      ),
    );
  }

  void _showWakeHistorySheet(BuildContext context) {
    final historyList = _storage.getAllWakeHistory().reversed.toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'جاگنے کا ریکارڈ / History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'چہرے کی تصدیق کے ساتھ جاگنے کے اوقات',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreenLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                    child: Text(
                      '${historyList.length} ریکارڈز',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: historyList.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off_rounded,
                              size: 48, color: AppTheme.textLight),
                          SizedBox(height: 12),
                          Text(
                            'ابھی تک جاگنے کا کوئی ریکارڈ نہیں',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'No wake-up history yet.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: historyList.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = historyList[index];
                        final dt = item.wakeDateTime;
                        final timeStr =
                            DateTimeUtils.formatTime12Hour(dt.hour, dt.minute);
                        final dateStr = '${dt.day}/${dt.month}/${dt.year}';
                        final isLate = item.minutesLate > 3;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isLate
                                      ? AppTheme.warningOrange.withValues(alpha: 0.15)
                                      : AppTheme.accentGreenLight,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.verified_user_rounded,
                                  color: isLate
                                      ? AppTheme.warningOrange
                                      : AppTheme.accentGreen,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      timeStr,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      dateStr,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isLate
                                      ? AppTheme.warningOrange.withValues(alpha: 0.15)
                                      : AppTheme.accentGreenLight,
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusS),
                                ),
                                child: Text(
                                  isLate
                                      ? '${item.minutesLate} منٹ تاخیر'
                                      : 'بر وقت / On time',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isLate
                                        ? AppTheme.warningOrange
                                        : AppTheme.accentGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddAlarm() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const SetAlarmScreen(),
      ),
    );
    if (result == true) {
      _loadAlarms();
    }
  }

  void _navigateToEditAlarm(AlarmModel alarm) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SetAlarmScreen(existingAlarm: alarm),
      ),
    );
    if (result == true) {
      _loadAlarms();
    }
  }

  /// Next active alarm dhundho
  AlarmModel? _getNextUpcomingAlarm() {
    final enabled = _alarms.where((a) => a.isEnabled).toList();
    if (enabled.isEmpty) return null;

    AlarmModel? nextAlarm;
    DateTime? earliestTime;

    for (final alarm in enabled) {
      final alarmTime = DateTimeUtils.getNextAlarmTime(
        alarm.hour,
        alarm.minute,
        alarm.repeatDays,
      );
      if (alarmTime != null) {
        if (earliestTime == null || alarmTime.isBefore(earliestTime)) {
          earliestTime = alarmTime;
          nextAlarm = alarm;
        }
      }
    }
    return nextAlarm;
  }

  @override
  Widget build(BuildContext context) {
    final nextAlarm = _getNextUpcomingAlarm();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ============================================================
            // 1. TOP HEADER & APP BRANDING
            // ============================================================
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingL,
                vertical: AppTheme.spacingM,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlueLight,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusM),
                        ),
                        child: const Icon(
                          Icons.alarm_on_rounded,
                          color: AppTheme.primaryBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appNameUrdu,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            AppConstants.appName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.history_rounded,
                          color: AppTheme.primaryBlue,
                        ),
                        onPressed: () => _showWakeHistorySheet(context),
                        tooltip: 'جاگنے کا ریکارڈ / History',
                      ),
                      Text(
                        DateTimeUtils.getTodayLabel(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ============================================================
            // 2. LIVE CLOCK DISPLAY & UPCOMING ALARM CARD
            // ============================================================
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingL,
                vertical: AppTheme.spacingS,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: AppTheme.spacingL,
                horizontal: AppTheme.spacingL,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  // Live Clock
                  Text(
                    DateTimeUtils.formatCurrentTime(_currentTime),
                    style: AppTheme.clockStyle.copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlueDark,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  // Upcoming alarm banner
                  if (nextAlarm != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreenLight,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusCircle),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.notifications_active_rounded,
                            size: 16,
                            color: AppTheme.accentGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'اگلا الارم: ${DateTimeUtils.getNextAlarmDescription(nextAlarm.hour, nextAlarm.minute, nextAlarm.repeatDays)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'کوئی فعال الارم نہیں / No active alarms',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingM),

            // ============================================================
            // 3. SECTION HEADER ("آپ کے الارم / Your Alarms")
            // ============================================================
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingL,
                vertical: AppTheme.spacingXS,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'آپ کے الارم / Saved Alarms',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '${_alarms.length} الارم',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // ============================================================
            // 4. LIST OF SAVED ALARMS OR EMPTY STATE
            // ============================================================
            Expanded(
              child: _alarms.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: const BoxDecoration(
                                color: AppTheme.surfaceVariant,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.alarm_off_rounded,
                                size: 40,
                                color: AppTheme.textLight,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingS),
                            const Text(
                              'ابھی کوئی الارم نہیں لگا',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'No alarm is set yet.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _alarms.length,
                      itemBuilder: (context, index) {
                        final alarm = _alarms[index];
                        return AlarmCard(
                          alarm: alarm,
                          onToggle: (val) => _onToggleAlarm(alarm, val),
                          onTap: () => _navigateToEditAlarm(alarm),
                          onDelete: () => _onDeleteAlarm(alarm),
                        );
                      },
                    ),
            ),

            // ============================================================
            // 5. PRIVACY MESSAGE (Clickable with full guarantee dialog)
            // ============================================================
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingL,
                vertical: AppTheme.spacingXS,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                onTap: () => _showPrivacyDialog(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: AppTheme.accentGreen,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          AppConstants.privacyMessage,
                          textAlign: TextAlign.center,
                          style: AppTheme.privacyStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ============================================================
            // 6. MAIN ACTION BUTTON: "الارم لگائیں / Set Alarm"
            // ============================================================
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToAddAlarm,
                  icon: const Icon(Icons.add_rounded, size: 24),
                  label: const Text(
                    'الارم لگائیں / Set Alarm',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusXL),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
