// lib/widgets/face_guide.dart
// FaceUp Alarm - Circular Face Guide Widget
// User ko clear circular cutout dikhata hai jahan chehra rakhna hai

import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

enum FaceGuideStatus {
  searching, // Blue pulse - searching for face
  detected, // Green border - face found
  error, // Red border - face out of frame / eyes closed
  success, // Solid green - 3-second hold complete
}

class FaceGuide extends StatelessWidget {
  final double circleDiameter;
  final FaceGuideStatus status;
  final String statusUrdu;
  final String statusEng;
  final Widget? child; // Camera preview ya placeholder

  const FaceGuide({
    super.key,
    this.circleDiameter = 270.0,
    this.status = FaceGuideStatus.searching,
    this.statusUrdu = 'چہرہ دائرے میں لائیں',
    this.statusEng = 'Align your face in circle',
    this.child,
  });

  Color get _borderColor {
    switch (status) {
      case FaceGuideStatus.searching:
        return AppTheme.faceGuideInactive;
      case FaceGuideStatus.detected:
        return AppTheme.faceGuideActive;
      case FaceGuideStatus.error:
        return AppTheme.faceGuideError;
      case FaceGuideStatus.success:
        return AppTheme.accentGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular Face Guide Container
          Container(
            width: circleDiameter,
            height: circleDiameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _borderColor,
                width: 4.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _borderColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: child ??
                  Container(
                    color: Colors.black12,
                    child: const Center(
                      child: Icon(
                        Icons.face_rounded,
                        size: 90,
                        color: Colors.white70,
                      ),
                    ),
                  ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingM),

          // Status Badge beneath face guide
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
              boxShadow: AppTheme.cardShadow,
              border: Border.all(
                color: _borderColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  statusUrdu,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _borderColor == AppTheme.faceGuideInactive
                        ? AppTheme.primaryBlueDark
                        : _borderColor,
                  ),
                ),
                Text(
                  statusEng,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
