package com.faceup.face_up_alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val RINGTONE_CHANNEL = "com.faceup/ringtone"
    private val ALARM_CHANNEL = "com.faceup/alarm_manager"

    private var previewRingtone: Ringtone? = null
    private var alarmMethodChannel: MethodChannel? = null
    private var pendingAlarmId: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleAlarmIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleAlarmIntent(intent)
    }

    private fun handleAlarmIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action
        if (action == "FACEUP_ALARM_ACTION") {
            val alarmId = intent.getStringExtra("ALARM_ID")
            if (alarmId != null) {
                pendingAlarmId = alarmId
                alarmMethodChannel?.invokeMethod("onAlarmTriggered", mapOf("alarmId" to alarmId))
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Ringtone Channel (Preview purposes)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RINGTONE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAvailableRingtones" -> {
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

        // 2. Alarm Channel (Real Android Alarm Scheduling)
        alarmMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager

                when (call.method) {
                    "scheduleAlarm" -> {
                        val id = call.argument<Int>("id") ?: 0
                        val triggerAtMillis = call.argument<Long>("triggerAtMillis") ?: 0L
                        val alarmIdString = call.argument<String>("alarmIdString") ?: ""
                        val ringtoneUri = call.argument<String>("ringtoneUri") ?: ""
                        val faceMode = call.argument<Boolean>("faceMode") ?: true

                        val intent = Intent(this@MainActivity, AlarmBroadcastReceiver::class.java).apply {
                            action = "FACEUP_ALARM_TRIGGER"
                            putExtra(AlarmForegroundService.EXTRA_ALARM_ID, alarmIdString)
                            putExtra(AlarmForegroundService.EXTRA_RINGTONE_URI, ringtoneUri)
                            putExtra(AlarmForegroundService.EXTRA_FACE_MODE, faceMode)
                        }

                        val pendingIntent = PendingIntent.getBroadcast(
                            this@MainActivity,
                            id,
                            intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )

                        // Intent to show clock / open app when user clicks clock widget
                        val showIntent = Intent(this@MainActivity, MainActivity::class.java)
                        val showPendingIntent = PendingIntent.getActivity(
                            this@MainActivity,
                            id,
                            showIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )

                        try {
                            // Gold standard: setAlarmClock guarantees alarm firing and status bar icon
                            val clockInfo = AlarmManager.AlarmClockInfo(triggerAtMillis, showPendingIntent)
                            alarmManager.setAlarmClock(clockInfo, pendingIntent)
                            result.success(true)
                        } catch (e: Exception) {
                            // Fallback to setExactAndAllowWhileIdle
                            try {
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                    alarmManager.setExactAndAllowWhileIdle(
                                        AlarmManager.RTC_WAKEUP,
                                        triggerAtMillis,
                                        pendingIntent
                                    )
                                } else {
                                    alarmManager.setExact(
                                        AlarmManager.RTC_WAKEUP,
                                        triggerAtMillis,
                                        pendingIntent
                                    )
                                }
                                result.success(true)
                            } catch (fallbackEx: Exception) {
                                result.error("ALARM_ERROR", fallbackEx.message, null)
                            }
                        }
                    }

                    "cancelAlarm" -> {
                        val id = call.argument<Int>("id") ?: 0
                        val intent = Intent(this@MainActivity, AlarmBroadcastReceiver::class.java).apply {
                            action = "FACEUP_ALARM_TRIGGER"
                        }
                        val pendingIntent = PendingIntent.getBroadcast(
                            this@MainActivity,
                            id,
                            intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        alarmManager.cancel(pendingIntent)
                        result.success(true)
                    }

                    "stopAlarm" -> {
                        AlarmForegroundService.stopAlarmService(this@MainActivity)
                        pendingAlarmId = null
                        result.success(true)
                    }

                    "canScheduleExactAlarms" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            result.success(alarmManager.canScheduleExactAlarms())
                        } else {
                            result.success(true)
                        }
                    }

                    "requestExactAlarmPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            try {
                                val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                    data = Uri.parse("package:$packageName")
                                }
                                startActivity(intent)
                                result.success(true)
                            } catch (e: Exception) {
                                result.success(false)
                            }
                        } else {
                            result.success(true)
                        }
                    }

                    "getActiveRingingAlarmId" -> {
                        val id = pendingAlarmId ?: AlarmForegroundService.activeAlarmId
                        result.success(id)
                    }

                    else -> {
                        result.notImplemented()
                    }
                }
            }
        }

        // Agar app cold start hui thi alarm intent se, toh inform Flutter
        pendingAlarmId?.let { id ->
            alarmMethodChannel?.invokeMethod("onAlarmTriggered", mapOf("alarmId" to id))
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
