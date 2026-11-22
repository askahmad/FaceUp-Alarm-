package com.faceup.face_up_alarm

import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val RINGTONE_CHANNEL = "com.faceup/ringtone"
    private var previewRingtone: Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RINGTONE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAvailableRingtones" -> {
                    // System alarm tones provide karo
                    val tones = listOf(
                        mapOf("id" to "default_alarm", "name" to "ڈیفالٹ الارم / Default Alarm", "uri" to ""),
                        mapOf("id" to "system_ringtone", "name" to "فون کی گھنٹی / Phone Ringtone", "uri" to "type_ringtone"),
                        mapOf("id" to "system_notification", "name" to "نوٹیفکیشن ساؤنڈ / Notification Sound", "uri" to "type_notification")
                    )
                    result.success(tones)
                }
                "playPreview" -> {
                    val toneType = call.argument<String>("uri") ?: ""
                    stopPreviewInternal()

                    try {
                        val uri: Uri = when (toneType) {
                            "type_ringtone" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                            "type_notification" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                            else -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                        }

                        previewRingtone = RingtoneManager.getRingtone(context, uri).apply {
                            audioAttributes = AudioAttributes.Builder()
                                .setUsage(AudioAttributes.USAGE_ALARM)
                                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                .build()
                            play()
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "stopPreview" -> {
                    stopPreviewInternal()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun stopPreviewInternal() {
        try {
            previewRingtone?.let {
                if (it.isPlaying) {
                    it.stop()
                }
            }
        } catch (_: Exception) {}
        previewRingtone = null
    }

    override fun onDestroy() {
        stopPreviewInternal()
        super.onDestroy()
    }
}
