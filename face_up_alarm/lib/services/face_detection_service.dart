// lib/services/face_detection_service.dart
// FaceUp Alarm - Google ML Kit Face Detection Service
// 100% On-Device, Offline, Privacy-First Face Verification

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../utils/app_constants.dart';

enum FaceChallengeType {
  blink, // ایک بار پلک جھپکائیں / Blink Once
  smile, // مسکرائیں / Smile
}

enum VerificationState {
  searchingFace, // Stage 1: Face not found or not centered
  eyesClosed, // Stage 2: Face found but eyes are closed
  challenging, // Stage 2: Performing blink or smile challenge
  holding, // Stage 3: Eyes open, challenge done, holding for 3 seconds
  verified, // All conditions passed continuously for 3 seconds!
}

class VerificationResult {
  final VerificationState state;
  final String messageUrdu;
  final String messageEng;
  final double holdProgress; // 0.0 to 1.0
  final bool isVerified;
  final double? leftEyeOpen;
  final double? rightEyeOpen;
  final double? smileProb;

  const VerificationResult({
    required this.state,
    required this.messageUrdu,
    required this.messageEng,
    this.holdProgress = 0.0,
    this.isVerified = false,
    this.leftEyeOpen,
    this.rightEyeOpen,
    this.smileProb,
  });
}

class FaceDetectionService {
  FaceDetector? _faceDetector;
  bool _isInitialized = false;

  // Active Challenge (Blink ya Smile)
  FaceChallengeType _activeChallenge = FaceChallengeType.blink;
  FaceChallengeType get activeChallenge => _activeChallenge;

  String get activeChallengeUrdu {
    switch (_activeChallenge) {
      case FaceChallengeType.blink:
        return 'ایک بار پلک جھپکائیں';
      case FaceChallengeType.smile:
        return 'مسکرائیں';
    }
  }

  String get activeChallengeEng {
    switch (_activeChallenge) {
      case FaceChallengeType.blink:
        return 'Blink Once';
      case FaceChallengeType.smile:
        return 'Smile';
    }
  }

  // Blink detection state machine
  bool _blinkEyesWereOpen = false;
  bool _blinkEyesClosedDetected = false;
  DateTime? _blinkStartTime;
  bool _challengePassed = false;

  // Smile consecutive frames
  int _consecutiveSmileFrames = 0;

  // 3-second hold timer
  DateTime? _holdStartTime;
  double _holdProgress = 0.0;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  /// Service initialize karo
  void init({FaceChallengeType? challenge}) {
    // Random challenge select karo ya specified
    _activeChallenge = challenge ??
        (DateTime.now().millisecond % 2 == 0
            ? FaceChallengeType.blink
            : FaceChallengeType.smile);

    resetVerification();

    final options = FaceDetectorOptions(
      enableClassification: true, // Eyes open & smile probability
      enableLandmarks: true, // Face landmarks
      enableContours: false,
      enableTracking: true, // Face tracking
      minFaceSize: AppConstants.minimumFaceSizeRatio,
      performanceMode: FaceDetectorMode.fast, // Real-time 30fps stream
    );

    _faceDetector = FaceDetector(options: options);
    _isInitialized = true;
  }

  /// State reset karo
  void resetVerification() {
    _blinkEyesWereOpen = false;
    _blinkEyesClosedDetected = false;
    _blinkStartTime = null;
    _consecutiveSmileFrames = 0;
    _challengePassed = false;
    _holdStartTime = null;
    _holdProgress = 0.0;
  }

  /// Camera Image ko ML Kit InputImage mein convert karke process karo
  Future<VerificationResult> processCameraImage({
    required CameraImage cameraImage,
    required CameraDescription cameraDescription,
    required DeviceOrientation deviceOrientation,
  }) async {
    if (!_isInitialized || _faceDetector == null || _isProcessing) {
      return VerificationResult(
        state: VerificationState.searchingFace,
        messageUrdu: 'چہرہ تلاش کر رہے ہیں',
        messageEng: 'Searching for face',
        holdProgress: _holdProgress,
      );
    }

    _isProcessing = true;

    try {
      final inputImage = _convertCameraImageToInputImage(
        cameraImage: cameraImage,
        cameraDescription: cameraDescription,
        deviceOrientation: deviceOrientation,
      );

      if (inputImage == null) {
        _resetHold();
        return VerificationResult(
          state: VerificationState.searchingFace,
          messageUrdu: 'چہرہ تلاش کر رہے ہیں',
          messageEng: 'Aligning camera',
          holdProgress: 0.0,
        );
      }

      final List<Face> faces = await _faceDetector!.processImage(inputImage);

      // ============================================================
      // CHECK 1: FACE FOUND & PROPERLY SIZED
      // ============================================================
      if (faces.isEmpty) {
        _resetHold();
        return const VerificationResult(
          state: VerificationState.searchingFace,
          messageUrdu: 'چہرہ نہیں نظر آ رہا',
          messageEng: 'Face not found. Show your face',
          holdProgress: 0.0,
        );
      }

      final Face face = faces.first;

      // Face clarity / posture check: Reject extreme tilts (yaw or roll > 35 degrees)
      final rotY = face.headEulerAngleY ?? 0;
      final rotZ = face.headEulerAngleZ ?? 0;
      if (rotY.abs() > 35 || rotZ.abs() > 35) {
        _resetHold();
        return const VerificationResult(
          state: VerificationState.searchingFace,
          messageUrdu: 'اپنا چہرہ سیدھا رکھیں',
          messageEng: 'Look straight at camera',
          holdProgress: 0.0,
        );
      }

      // ============================================================
      // CHECK 2: EYES OPEN CHECK
      // ============================================================
      final double leftEye = face.leftEyeOpenProbability ?? 0.0;
      final double rightEye = face.rightEyeOpenProbability ?? 0.0;
      final double smile = face.smilingProbability ?? 0.0;

      final bool bothEyesOpen = leftEye >= AppConstants.eyeOpenThreshold &&
          rightEye >= AppConstants.eyeOpenThreshold;

      // ============================================================
      // CHECK 3 & 4: INTERACTIVE LIVE CHALLENGE (Blink or Smile)
      // ============================================================
      if (!_challengePassed) {
        if (_activeChallenge == FaceChallengeType.blink) {
          // Blink logic: Open -> Closed (< 0.3) -> Open (> 0.7)
          if (!_blinkEyesWereOpen) {
            if (bothEyesOpen) {
              _blinkEyesWereOpen = true;
              _blinkStartTime = DateTime.now();
            }
          } else if (!_blinkEyesClosedDetected) {
            // Check if eyes closed
            final bool bothClosed = leftEye < AppConstants.eyeClosedThreshold &&
                rightEye < AppConstants.eyeClosedThreshold;
            if (bothClosed) {
              _blinkEyesClosedDetected = true;
            } else if (_blinkStartTime != null &&
                DateTime.now().difference(_blinkStartTime!).inMilliseconds >
                    AppConstants.blinkTimeWindowMs) {
              // Timeout - restart blink sequence
              _blinkEyesWereOpen = false;
            }
          } else {
            // Waiting for eyes to open again
            if (bothEyesOpen) {
              _challengePassed = true; // Blink complete!
            }
          }

          if (!_challengePassed) {
            _resetHold();
            return VerificationResult(
              state: VerificationState.challenging,
              messageUrdu: 'ایک بار پلک جھپکائیں',
              messageEng: 'Blink once to verify',
              leftEyeOpen: leftEye,
              rightEyeOpen: rightEye,
              holdProgress: 0.0,
            );
          }
        } else {
          // Smile challenge logic: Smiling > 0.7 for consecutive frames
          if (smile >= AppConstants.smileThreshold) {
            _consecutiveSmileFrames++;
            if (_consecutiveSmileFrames >=
                AppConstants.smileConfirmationFrames) {
              _challengePassed = true;
            }
          } else {
            _consecutiveSmileFrames = 0;
          }

          if (!_challengePassed) {
            _resetHold();
            return VerificationResult(
              state: VerificationState.challenging,
              messageUrdu: 'تھوڑا سا مسکرائیں',
              messageEng: 'Please smile to verify',
              smileProb: smile,
              holdProgress: 0.0,
            );
          }
        }
      }

      // If challenge is passed, ensure eyes remain open
      if (!bothEyesOpen) {
        _resetHold();
        return VerificationResult(
          state: VerificationState.eyesClosed,
          messageUrdu: 'اپنی آنکھیں کھولیں',
          messageEng: 'Keep both eyes open',
          leftEyeOpen: leftEye,
          rightEyeOpen: rightEye,
          holdProgress: 0.0,
        );
      }

      // ============================================================
      // CHECK 5: CONTINUOUS 3-SECOND HOLD
      // ============================================================
      final now = DateTime.now();
      _holdStartTime ??= now;

      final elapsedMs = now.difference(_holdStartTime!).inMilliseconds;
      _holdProgress = (elapsedMs / (AppConstants.holdDurationSeconds * 1000))
          .clamp(0.0, 1.0);

      if (_holdProgress >= 1.0) {
        // SUCCESS! 3 continuous seconds passed
        return VerificationResult(
          state: VerificationState.verified,
          messageUrdu: 'شاباش! آپ اٹھ گئے',
          messageEng: 'Verified! You are awake',
          holdProgress: 1.0,
          isVerified: true,
          leftEyeOpen: leftEye,
          rightEyeOpen: rightEye,
          smileProb: smile,
        );
      }

      final secondsRemaining =
          (AppConstants.holdDurationSeconds - (elapsedMs / 1000))
              .toStringAsFixed(1);

      return VerificationResult(
        state: VerificationState.holding,
        messageUrdu: 'تین سیکنڈ رکیں ($secondsRemaining s)',
        messageEng: 'Hold still for 3 seconds',
        holdProgress: _holdProgress,
        leftEyeOpen: leftEye,
        rightEyeOpen: rightEye,
        smileProb: smile,
      );
    } catch (_) {
      return VerificationResult(
        state: VerificationState.searchingFace,
        messageUrdu: 'چہرہ تلاش کر رہے ہیں',
        messageEng: 'Processing frame',
        holdProgress: _holdProgress,
      );
    } finally {
      _isProcessing = false;
    }
  }

  void _resetHold() {
    _holdStartTime = null;
    _holdProgress = 0.0;
  }

  /// CameraImage ko ML Kit InputImage format mein convert karne ka helper
  InputImage? _convertCameraImageToInputImage({
    required CameraImage cameraImage,
    required CameraDescription cameraDescription,
    required DeviceOrientation deviceOrientation,
  }) {
    try {
      final sensorOrientation = cameraDescription.sensorOrientation;
      InputImageRotation? rotation;

      if (Platform.isAndroid) {
        var rotationCompensation = _orientations[deviceOrientation];
        if (rotationCompensation == null) return null;
        if (cameraDescription.lensDirection == CameraLensDirection.front) {
          rotationCompensation =
              (sensorOrientation + rotationCompensation) % 360;
        } else {
          rotationCompensation =
              (sensorOrientation - rotationCompensation + 360) % 360;
        }
        rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      }

      if (rotation == null) return null;

      final format = InputImageFormatValue.fromRawValue(cameraImage.format.raw);
      if (format == null) return null;

      // Handle multi-plane YUV420 or single plane NV21
      final Uint8List bytes;
      if (cameraImage.planes.length == 1) {
        bytes = cameraImage.planes.first.bytes;
      } else {
        // Concatenate all planes
        final allBytes = BytesBuilder();
        for (final plane in cameraImage.planes) {
          allBytes.add(plane.bytes);
        }
        bytes = allBytes.toBytes();
      }

      final metadata = InputImageMetadata(
        size: Size(
          cameraImage.width.toDouble(),
          cameraImage.height.toDouble(),
        ),
        rotation: rotation,
        format: format,
        bytesPerRow: cameraImage.planes.first.bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } catch (_) {
      return null;
    }
  }

  static const Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  /// Clean up native resources
  Future<void> dispose() async {
    try {
      await _faceDetector?.close();
    } catch (_) {}
    _faceDetector = null;
    _isInitialized = false;
  }
}
