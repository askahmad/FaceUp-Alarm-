// lib/services/audio_service.dart
// FaceUp Alarm - Audio Service
// Native Android RingtoneManager ke sath connect karta hai
// Zero third-party audio packages needed!

import 'package:flutter/services.dart';
import '../utils/app_constants.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final MethodChannel _channel =
      const MethodChannel(AppConstants.ringtoneMethodChannel);

  bool _isPreviewPlaying = false;
  bool get isPreviewPlaying => _isPreviewPlaying;

  /// Android system se available ringtones ki list lo
  Future<List<Map<String, String>>> getAvailableRingtones() async {
    try {
      final List<dynamic>? result =
          await _channel.invokeMethod('getAvailableRingtones');
      if (result != null) {
        return result.map((item) {
          final map = item as Map<dynamic, dynamic>;
          return {
            'id': map['id']?.toString() ?? '',
            'name': map['name']?.toString() ?? 'Default Alarm',
            'uri': map['uri']?.toString() ?? '',
          };
        }).toList();
      }
    } catch (_) {
      // Fallback
    }

    return [
      {
        'id': 'default_alarm',
        'name': 'ڈیفالٹ الارم / Default Alarm',
        'uri': '',
      },
      {
        'id': 'system_ringtone',
        'name': 'فون کی گھنٹی / Phone Ringtone',
        'uri': 'type_ringtone',
      },
      {
        'id': 'system_notification',
        'name': 'نوٹیفکیشن ساؤنڈ / Notification Sound',
        'uri': 'type_notification',
      },
    ];
  }

  /// Ringtone ka preview chalao
  Future<bool> playRingtonePreview(String uri) async {
    try {
      final bool? success =
          await _channel.invokeMethod('playPreview', {'uri': uri});
      _isPreviewPlaying = success ?? false;
      return _isPreviewPlaying;
    } catch (_) {
      _isPreviewPlaying = false;
      return false;
    }
  }

  /// Ringtone ka preview roko
  Future<void> stopRingtonePreview() async {
    try {
      await _channel.invokeMethod('stopPreview');
    } catch (_) {}
    _isPreviewPlaying = false;
  }
}
