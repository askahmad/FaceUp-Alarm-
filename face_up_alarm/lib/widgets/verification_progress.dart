// lib/widgets/verification_progress.dart
// FaceUp Alarm - Verification Progress Interface
// 3 Stages ki visual progress dikhata hai: Face Found -> Eyes Open -> 3 Sec Hold

import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class VerificationProgress extends StatelessWidget {
  final int currentStage; // 1, 2, ya 3
  final double holdProgress; // 0.0 se 1.0 (3 seconds hold)
  final String? activeChallengeLabel; // "ایک بار پلک جھپکائیں / Blink Once" ya "مسکرائیں / Smile"

  const VerificationProgress({
    super.key,
    required this.currentStage,
    this.holdProgress = 0.0,
    this.activeChallengeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // 3 Stages Row
          _buildStageRow(
            stageNum: 1,
            urdu: 'چہرہ تلاش کر رہے ہیں',
            eng: 'Face Detection',
            icon: Icons.face_retouching_natural_rounded,
            isPassed: currentStage > 1,
            isActive: currentStage == 1,
          ),

          const Divider(height: 14),

          _buildStageRow(
            stageNum: 2,
            urdu: 'آنکھیں کھلی رکھیں',
            eng: 'Eyes Open',
            icon: Icons.visibility_rounded,
            isPassed: currentStage > 2,
            isActive: currentStage == 2,
          ),

          const Divider(height: 14),

          _buildStageRow(
            stageNum: 3,
            urdu: 'تین سیکنڈ رکیں',
            eng: 'Hold for 3 Seconds',
            icon: Icons.timer_rounded,
            isPassed: currentStage >= 3 && holdProgress >= 1.0,
            isActive: currentStage == 3,
          ),

          // Active challenge badge (if stage 2 or 3)
          if (activeChallengeLabel != null && currentStage >= 2) ...[
            const SizedBox(height: AppTheme.spacingS),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlueLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: AppTheme.primaryBlueDark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    activeChallengeLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlueDark,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 3-second hold progress bar (active during stage 3)
          if (currentStage == 3) ...[
            const SizedBox(height: AppTheme.spacingM),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
              child: LinearProgressIndicator(
                value: holdProgress.clamp(0.0, 1.0),
                backgroundColor: AppTheme.surfaceVariant,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${((1.0 - holdProgress) * 3).toStringAsFixed(1)} سیکنڈ باقی',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.accentGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStageRow({
    required int stageNum,
    required String urdu,
    required String eng,
    required IconData icon,
    required bool isPassed,
    required bool isActive,
  }) {
    final Color color;
    if (isPassed) {
      color = AppTheme.accentGreen;
    } else if (isActive) {
      color = AppTheme.primaryBlue;
    } else {
      color = AppTheme.textLight;
    }

    return Row(
      children: [
        // Status indicator circle
        CircleAvatar(
          radius: 12,
          backgroundColor: isPassed
              ? AppTheme.accentGreenLight
              : isActive
                  ? AppTheme.primaryBlueLight
                  : Colors.grey.shade200,
          child: isPassed
              ? const Icon(Icons.check_rounded,
                  size: 14, color: AppTheme.accentGreen)
              : Text(
                  '$stageNum',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                urdu,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppTheme.textPrimary : color,
                ),
              ),
              Text(
                eng,
                style: TextStyle(
                  fontSize: 10,
                  color: isPassed ? AppTheme.accentGreen : AppTheme.textLight,
                ),
              ),
            ],
          ),
        ),
        if (isPassed)
          const Icon(
            Icons.check_circle_rounded,
            color: AppTheme.accentGreen,
            size: 18,
          ),
      ],
    );
  }
}
