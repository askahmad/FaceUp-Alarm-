// lib/widgets/alarm_card.dart
// FaceUp Alarm - Alarm Card Widget
// Ye widget Home Screen par har alarm ko ek khubsurat card ki shakal mein dikhata hai

import 'package:flutter/material.dart';
import '../models/alarm_model.dart';
import '../utils/app_theme.dart';
import '../utils/date_time_utils.dart';

class AlarmCard extends StatelessWidget {
  final AlarmModel alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateTimeUtils.formatTime12Hour(alarm.hour, alarm.minute);
    final daysLabel = DateTimeUtils.getRepeatDaysLabel(alarm.repeatDays);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: alarm.isEnabled
            ? AppTheme.alarmCardEnabled
            : AppTheme.alarmCardDisabled,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: alarm.isEnabled ? AppTheme.cardShadow : null,
        border: Border.all(
          color: alarm.isEnabled
              ? AppTheme.primaryBlueLight.withValues(alpha: 0.5)
              : Colors.black12,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                // Left side: Time & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time display (e.g. 7:00 AM)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            timeStr.split(' ')[0], // "7:00"
                            style: AppTheme.alarmTimeStyle.copyWith(
                              color: alarm.isEnabled
                                  ? AppTheme.textPrimary
                                  : AppTheme.textLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingXS),
                          Text(
                            timeStr.split(' ').length > 1
                                ? timeStr.split(' ')[1]
                                : '', // "AM" / "PM"
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: alarm.isEnabled
                                  ? AppTheme.primaryBlue
                                  : AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppTheme.spacingXS),

                      // Repeat days label
                      Text(
                        daysLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: alarm.isEnabled
                              ? AppTheme.textSecondary
                              : AppTheme.textLight,
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingS),

                      // Badges row: Face mode & Ringtone
                      Row(
                        children: [
                          // Face mode badge
                          if (alarm.faceMode)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: alarm.isEnabled
                                    ? AppTheme.accentGreenLight
                                    : Colors.grey.shade200,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusS),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.face_rounded,
                                    size: 14,
                                    color: alarm.isEnabled
                                        ? AppTheme.accentGreen
                                        : AppTheme.textLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'چہرہ موڈ / Face Mode',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: alarm.isEnabled
                                          ? AppTheme.accentGreen
                                          : AppTheme.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusS),
                              ),
                              child: Text(
                                'عام الارم / Standard',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Right side: Toggle Switch & Delete button
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: alarm.isEnabled,
                      onChanged: onToggle,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppTheme.errorRed,
                        size: 20,
                      ),
                      onPressed: onDelete,
                      tooltip: 'ڈیلیٹ کریں / Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
