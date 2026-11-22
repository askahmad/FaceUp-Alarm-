// lib/screens/set_alarm_screen.dart
// FaceUp Alarm - Set Alarm Screen (SCREEN 2)
// Time Picker, Repeat Days, Ringtone, Face Mode Toggle & Save

import 'package:flutter/material.dart';
import '../models/alarm_model.dart';
import '../services/audio_service.dart';
import '../services/alarm_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/date_time_utils.dart';

class SetAlarmScreen extends StatefulWidget {
  final AlarmModel? existingAlarm;

  const SetAlarmScreen({super.key, this.existingAlarm});

  @override
  State<SetAlarmScreen> createState() => _SetAlarmScreenState();
}

class _SetAlarmScreenState extends State<SetAlarmScreen> {
  final AudioService _audio = AudioService();

  late int _selectedHour;
  late int _selectedMinute;
  late List<int> _selectedDays;
  late bool _faceMode;
  late String _selectedRingtoneName;
  late String _selectedRingtoneUri;

  List<Map<String, String>> _availableRingtones = [];
  bool _isPlayingPreview = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingAlarm != null) {
      final a = widget.existingAlarm!;
      _selectedHour = a.hour;
      _selectedMinute = a.minute;
      _selectedDays = List<int>.from(a.repeatDays);
      _faceMode = a.faceMode;
      _selectedRingtoneName = a.ringtoneName;
      _selectedRingtoneUri = a.ringtoneUri;
    } else {
      // Default: Next morning 7:00 AM
      _selectedHour = 7;
      _selectedMinute = 0;
      _selectedDays = []; // Default: One time
      _faceMode = true; // ON by default as required
      _selectedRingtoneName = 'ڈیفالٹ الارم / Default Alarm';
      _selectedRingtoneUri = '';
    }

    _loadRingtones();
  }

  @override
  void dispose() {
    _audio.stopRingtonePreview();
    super.dispose();
  }

  Future<void> _loadRingtones() async {
    final tones = await _audio.getAvailableRingtones();
    if (mounted) {
      setState(() {
        _availableRingtones = tones;
      });
    }
  }

  void _toggleRingtonePreview(String uri) async {
    if (_isPlayingPreview) {
      await _audio.stopRingtonePreview();
      if (mounted) setState(() => _isPlayingPreview = false);
    } else {
      final success = await _audio.playRingtonePreview(uri);
      if (mounted) setState(() => _isPlayingPreview = success);
    }
  }

  Future<void> _pickTime() async {
    final initialTime = TimeOfDay(
      hour: _selectedHour,
      minute: _selectedMinute,
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedHour = picked.hour;
        _selectedMinute = picked.minute;
      });
    }
  }

  void _toggleDay(int androidDay) {
    setState(() {
      if (_selectedDays.contains(androidDay)) {
        _selectedDays.remove(androidDay);
      } else {
        _selectedDays.add(androidDay);
      }
    });
  }

  void _saveAlarm() async {
    // Validate: Make sure hour and minute are within 0-23, 0-59
    if (_selectedHour < 0 ||
        _selectedHour > 23 ||
        _selectedMinute < 0 ||
        _selectedMinute > 59) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('غلط وقت منتخب کیا گیا ہے / Invalid time selected'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    // Stop ringtone preview if playing
    if (_isPlayingPreview) {
      await _audio.stopRingtonePreview();
    }

    // Check exact alarm permission on Android 12+
    final canExact = await AlarmService().canScheduleExactAlarms();
    if (!canExact && mounted) {
      final request = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('پرمیشن درکار ہے / Permission Required'),
          content: const Text(
            'اینڈرائڈ 12+ پر وقت پر الارم بجانے کے لیے Exact Alarm پرمیشن درکار ہے۔\nAndroid requires Exact Alarm permission to fire on time.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('چھوڑ دیں / Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('سیٹنگز کھولیں / Open Settings'),
            ),
          ],
        ),
      );

      if (request == true) {
        await AlarmService().requestExactAlarmPermission();
      }
    }

    final AlarmModel alarmToSave;
    if (widget.existingAlarm != null) {
      alarmToSave = widget.existingAlarm!.copyWith(
        hour: _selectedHour,
        minute: _selectedMinute,
        repeatDays: _selectedDays,
        faceMode: _faceMode,
        ringtoneName: _selectedRingtoneName,
        ringtoneUri: _selectedRingtoneUri,
        isEnabled: true,
      );
    } else {
      alarmToSave = AlarmModel.create(
        hour: _selectedHour,
        minute: _selectedMinute,
        repeatDays: _selectedDays,
        faceMode: _faceMode,
        ringtoneName: _selectedRingtoneName,
        ringtoneUri: _selectedRingtoneUri,
      );
    }

    // Android AlarmManager se schedule karo
    final success = await AlarmService().scheduleAlarm(alarmToSave);

    if (mounted) {
      if (success) {
        final timeStr =
            DateTimeUtils.formatTime12Hour(_selectedHour, _selectedMinute);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('الارم $timeStr کے لیے محفوظ ہو گیا ✓ / Alarm saved!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'الارم محفوظ نہیں ہو سکا / Error: Failed to save alarm'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingAlarm != null;
    final timeStr =
        DateTimeUtils.formatTime12Hour(_selectedHour, _selectedMinute);
    final parts = timeStr.split(' ');
    final timeValue = parts[0];
    final timePeriod = parts.length > 1 ? parts[1] : '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          isEditing ? 'الارم تبدیل کریں / Edit Alarm' : 'الارم لگائیں / Set Alarm',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.errorRed),
              onPressed: () async {
                final nav = Navigator.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('الارم ڈیلیٹ کریں؟'),
                    content: const Text(
                        'Are you sure you want to delete this alarm?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('نہیں / Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorRed),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('ڈیلیٹ / Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  await AlarmService().cancelAlarm(widget.existingAlarm!.id);
                  nav.pop(true);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingL,
          vertical: AppTheme.spacingM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ============================================================
            // 1. TIME SELECTION CARD
            // ============================================================
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingXL,
                  horizontal: AppTheme.spacingL,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  boxShadow: AppTheme.cardShadow,
                  border: Border.all(
                    color: AppTheme.primaryBlueLight,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'وقت منتخب کریں / Tap to Select Time',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          timeValue,
                          style: AppTheme.clockStyle.copyWith(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlueDark,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlueLight,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusS),
                          ),
                          child: Text(
                            timePeriod,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlueDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      DateTimeUtils.getNextAlarmDescription(
                        _selectedHour,
                        _selectedMinute,
                        _selectedDays,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.accentGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingL),

            // ============================================================
            // 2. REPEAT DAYS SELECTION
            // ============================================================
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'دہرائیں / Repeat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        _selectedDays.isEmpty
                          ? 'صرف ایک بار / Once'
                          : '${_selectedDays.length} دن منتخب',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  // Day chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [2, 3, 4, 5, 6, 7, 1].map((dayNumber) {
                      final isSelected = _selectedDays.contains(dayNumber);
                      final dayLabel = AppConstants.dayNames[dayNumber] ?? '';
                      final lines = dayLabel.split('\n');
                      final urdu = lines[0];
                      final eng = lines.length > 1 ? lines[1] : '';

                      return GestureDetector(
                        onTap: () => _toggleDay(dayNumber),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 42,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : AppTheme.surfaceVariant,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusM),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryBlue
                                  : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                urdu,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                eng,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected
                                      ? Colors.white70
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  // Clear / Preset Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _selectedDays = []),
                        child: const Text('صاف کریں / Clear'),
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _selectedDays = [2, 3, 4, 5, 6]),
                        child: const Text('پیر تا جمعہ / Weekdays'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingL),

            // ============================================================
            // 3. FACE MODE TOGGLE (DEFAULT ON)
            // ============================================================
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                boxShadow: AppTheme.cardShadow,
                border: Border.all(
                  color: _faceMode
                      ? AppTheme.accentGreen.withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _faceMode
                          ? AppTheme.accentGreenLight
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.face_rounded,
                      color: _faceMode
                          ? AppTheme.accentGreen
                          : AppTheme.textLight,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'چہرہ دکھا کر بند کریں / Face Mode',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _faceMode
                              ? 'جاگنے کی تصدیق کے لیے 3 سیکنڈ چہرہ دکھانا ہوگا'
                              : 'عام الارم بٹن دبا کر بند ہو جائے گا',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _faceMode,
                    onChanged: (val) => setState(() => _faceMode = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingL),

            // ============================================================
            // 4. RINGTONE SELECTION
            // ============================================================
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'رنگ ٹون / Ringtone',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isPlayingPreview
                              ? Icons.stop_circle_rounded
                              : Icons.play_circle_fill_rounded,
                          color: _isPlayingPreview
                              ? AppTheme.errorRed
                              : AppTheme.primaryBlue,
                          size: 32,
                        ),
                        onPressed: () =>
                            _toggleRingtonePreview(_selectedRingtoneUri),
                        tooltip: _isPlayingPreview
                            ? 'آواز بند کریں / Stop'
                            : 'آواز چیک کریں / Preview',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  ..._availableRingtones.map((tone) {
                    final isSelected = tone['name'] == _selectedRingtoneName;
                    return InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      onTap: () {
                        setState(() {
                          _selectedRingtoneName = tone['name'] ?? '';
                          _selectedRingtoneUri = tone['uri'] ?? '';
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: isSelected
                                  ? AppTheme.primaryBlue
                                  : AppTheme.textLight,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tone['name'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? AppTheme.primaryBlue
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingXXL),

            // ============================================================
            // 5. SAVE BUTTON
            // ============================================================
            ElevatedButton(
              onPressed: _saveAlarm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                ),
              ),
              child: const Text(
                'الارم محفوظ کریں / Save Alarm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingL),
          ],
        ),
      ),
    );
  }
}
