// lib/screens/alarm_ringing_screen.dart
// FaceUp Alarm - Alarm Ringing Screen (SCREEN 3)
// Step 4: Live front camera preview + circular face guide + verification stages

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/alarm_service.dart';
import '../services/storage_service.dart';
import '../models/alarm_model.dart';
import '../models/wake_history_model.dart';
import '../utils/app_theme.dart';
import '../utils/date_time_utils.dart';
import '../widgets/face_guide.dart';
import '../widgets/verification_progress.dart';

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

  // Camera state
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String? _cameraErrorMessage;
  FaceGuideStatus _guideStatus = FaceGuideStatus.searching;
  String _guideStatusUrdu = 'چہرہ دائرے میں لائیں';
  String _guideStatusEng = 'Align your face inside circle';

  // Verification stage
  final int _currentStage = 1;
  final double _holdProgress = 0.0;
  final String _activeChallenge = 'ایک بار پلک جھپکائیں / Blink Once';

  @override
  void initState() {
    super.initState();
    _alarm = _storage.getAlarmById(widget.alarmId);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Face Mode ON hone par front camera initialize karo
    if (_alarm?.faceMode ?? true) {
      _initFrontCamera();
    }
  }

  Future<void> _initFrontCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraErrorMessage =
                'کوئی کیمرہ نہیں ملا / No camera available on device';
            _guideStatus = FaceGuideStatus.error;
          });
        }
        return;
      }

      // Front camera dhundho (agar na mile toh pehla camera use karo)
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false, // Privacy: Audio record nahi karni
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      _cameraController = controller;
      await controller.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _cameraErrorMessage = null;
          _guideStatus = FaceGuideStatus.searching;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraErrorMessage =
              'کیمرہ پرمیشن درکار ہے / Camera permission required';
          _guideStatus = FaceGuideStatus.error;
          _guideStatusUrdu = 'کیمرہ شروع نہیں ہو سکا';
          _guideStatusEng = 'Camera failed to start';
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  void _dismissAlarm() async {
    // 1. Stop native ringing and vibration
    await _alarmService.stopAlarm();

    // 2. Dispose camera immediately
    await _cameraController?.dispose();
    _cameraController = null;

    // 3. Record wake history
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

    // 4. Show success state
    if (mounted) {
      setState(() {
        _isSuccess = true;
        _successTime =
            DateTimeUtils.formatTime12Hour(now.hour, now.minute);
      });

      // 2 seconds success screen then return to Home
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
              vertical: AppTheme.spacingM,
            ),
            child: _isSuccess ? _buildSuccessView() : _buildRingingView(timeStr),
          ),
        ),
      ),
    );
  }

  Widget _buildRingingView(String timeStr) {
    final bool isFaceMode = _alarm?.faceMode ?? true;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Top section: Urdu & English Heading
          Column(
            children: [
              const SizedBox(height: AppTheme.spacingS),
              const Text(
                'اٹھ جائیں! اپنا چہرہ دکھائیں',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Wake up! Show your face.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              // Current ringing time
              Text(
                timeStr,
                style: AppTheme.clockStyle.copyWith(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlueDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingM),

          // Center section: Front Camera Live Preview with FaceGuide
          if (isFaceMode) ...[
            ScaleTransition(
              scale: _pulseAnimation,
              child: FaceGuide(
                circleDiameter: 250,
                status: _guideStatus,
                statusUrdu: _guideStatusUrdu,
                statusEng: _guideStatusEng,
                child: _isCameraInitialized && _cameraController != null
                    ? AspectRatio(
                        aspectRatio: 1,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width:
                                _cameraController!.value.previewSize?.height ??
                                    1,
                            height:
                                _cameraController!.value.previewSize?.width ??
                                    1,
                            child: CameraPreview(_cameraController!),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.black12,
                        child: Center(
                          child: _cameraErrorMessage != null
                              ? Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.videocam_off_rounded,
                                        size: 48,
                                        color: AppTheme.errorRed,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _cameraErrorMessage!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.errorRed,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: _initFrontCamera,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.primaryBlue,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                        ),
                                        child: const Text('دوبارہ کوشش کریں / Retry'),
                                      ),
                                    ],
                                  ),
                                )
                              : const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: AppTheme.primaryBlue,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'کیمرہ شروع ہو رہا ہے...\nStarting front camera...',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
              ),
            ),
          ] else ...[
            // Standard alarm placeholder if Face Mode is OFF
            Container(
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
          ],

          const SizedBox(height: AppTheme.spacingM),

          // 3-Stage Verification Progress UI
          VerificationProgress(
            currentStage: _currentStage,
            holdProgress: _holdProgress,
            activeChallengeLabel: _activeChallenge,
          ),

          const SizedBox(height: AppTheme.spacingL),

          // Step 4 Test / Fallback Control: Stop Alarm Button
          // (Step 5 will automatically verify via ML Kit and stop on 3-second hold)
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

          // Privacy Assurance Note
          const Text(
            'آپ کی تصویر کہیں محفوظ نہیں ہوتی\nLive camera preview is processed locally only.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),

          const SizedBox(height: AppTheme.spacingS),
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
