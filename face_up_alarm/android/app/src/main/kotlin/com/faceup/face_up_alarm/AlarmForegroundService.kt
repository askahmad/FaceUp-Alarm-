package com.faceup.face_up_alarm

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat

/**
 * AlarmForegroundService
 *
 * Ye Android Foreground Service hai jo alarm trigger hone par chalti hai.
 *
 * Iska kaam:
 * 1. WakeLock lena taake phone ki screen on ho sake.
 * 2. Alarm stream par loud ringtone bajana (looping).
 * 3. Phone ko vibrate karna.
 * 4. Ongoing notification dikhana (Full-Screen Intent ke sath).
 * 5. Jab user face verification poori kare, ye service stop hoti hai.
 */
class AlarmForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "faceup_alarm_high_priority_channel"
        const val CHANNEL_NAME = "FaceUp Alarm Ringing"
        const val NOTIFICATION_ID = 1001

        const val EXTRA_ALARM_ID = "extra_alarm_id"
        const val EXTRA_RINGTONE_URI = "extra_ringtone_uri"
        const val EXTRA_FACE_MODE = "extra_face_mode"

        var isRinging = false
            private set

        var activeAlarmId: String? = null
            private set

        fun stopAlarmService(context: Context) {
            val stopIntent = Intent(context, AlarmForegroundService::class.java).apply {
                action = "STOP_ALARM"
            }
            context.startService(stopIntent)
        }
    }

    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action

        if (action == "STOP_ALARM") {
            stopSelfAndCleanup()
            return START_NOT_STICKY
        }

        val alarmId = intent?.getStringExtra(EXTRA_ALARM_ID) ?: "unknown_alarm"
        val ringtoneUriString = intent?.getStringExtra(EXTRA_RINGTONE_URI) ?: ""
        val faceMode = intent?.getBooleanExtra(EXTRA_FACE_MODE, true) ?: true

        activeAlarmId = alarmId
        isRinging = true

        // 1. Acquire WakeLock (screen on karne ke liye)
        acquireWakeLock()

        // 2. Build Full-Screen Notification
        val notification = buildAlarmNotification(alarmId, faceMode)

        // 3. Start as Foreground Service
        startForeground(NOTIFICATION_ID, notification)

        // 4. Start Sound
        startRingtone(ringtoneUriString)

        // 5. Start Vibration
        startVibration()

        return START_STICKY
    }

    private fun acquireWakeLock() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            val flags = PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                    PowerManager.ACQUIRE_CAUSES_WAKEUP or
                    PowerManager.ON_AFTER_RELEASE

            wakeLock = powerManager.newWakeLock(flags, "FaceUpAlarm::AlarmWakeLock")
            // 10 minutes timeout safety
            wakeLock?.acquire(10 * 60 * 1000L)
        } catch (_: Exception) {}
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_ALARM)
                .build()

            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "FaceUp Alarm ringing notification"
                enableLights(true)
                enableVibration(true)
                setSound(null, audioAttributes) // Sound is handled by MediaPlayer for looping
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setBypassDnd(true)
            }

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildAlarmNotification(alarmId: String, faceMode: Boolean): Notification {
        // MainActivity kholne ke liye Intent
        val fullScreenIntent = Intent(this, MainActivity::class.java).apply {
            action = "FACEUP_ALARM_ACTION"
            putExtra("ALARM_ID", alarmId)
            putExtra("FACE_MODE", faceMode)
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            alarmId.hashCode(),
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("اٹھ جائیں! اپنا چہرہ دکھائیں")
            .setContentText("Wake up! Show your face to dismiss alarm.")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setFullScreenIntent(pendingIntent, true)
            .setContentIntent(pendingIntent)
            .build()
    }

    private fun startRingtone(ringtoneUriString: String) {
        try {
            // Anti-Dismissal Audio Strategy: Ensure alarm volume is high and audible
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as android.media.AudioManager
            val maxVol = audioManager.getStreamMaxVolume(android.media.AudioManager.STREAM_ALARM)
            val currentVol = audioManager.getStreamVolume(android.media.AudioManager.STREAM_ALARM)
            if (currentVol < (maxVol * 0.7).toInt()) {
                audioManager.setStreamVolume(
                    android.media.AudioManager.STREAM_ALARM,
                    (maxVol * 0.85).toInt(),
                    0
                )
            }

            // Audio Focus request
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val focusRequest = android.media.AudioFocusRequest.Builder(android.media.AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                    )
                    .build()
                audioManager.requestAudioFocus(focusRequest)
            }

            val uri: Uri = if (ringtoneUriString.isNotEmpty()) {
                Uri.parse(ringtoneUriString)
            } else {
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            }

            mediaPlayer = MediaPlayer().apply {
                setDataSource(this@AlarmForegroundService, uri)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                isLooping = true
                prepare()
                start()
            }
        } catch (_: Exception) {
            // Fallback: Default ringtone
            try {
                val fallbackUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                mediaPlayer = MediaPlayer.create(this, fallbackUri).apply {
                    isLooping = true
                    start()
                }
            } catch (_: Exception) {}
        }
    }

    private fun startVibration() {
        try {
            vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vm.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }

            val pattern = longArrayOf(0, 800, 400, 800, 400, 800)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val effect = VibrationEffect.createWaveform(pattern, 0) // 0 = repeat indefinitely
                vibrator?.vibrate(effect)
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(pattern, 0)
            }
        } catch (_: Exception) {}
    }

    private fun stopSelfAndCleanup() {
        isRinging = false
        activeAlarmId = null

        // Stop sound
        try {
            mediaPlayer?.let {
                if (it.isPlaying) it.stop()
                it.release()
            }
        } catch (_: Exception) {}
        mediaPlayer = null

        // Stop vibration
        try {
            vibrator?.cancel()
        } catch (_: Exception) {}
        vibrator = null

        // Release WakeLock
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (_: Exception) {}
        wakeLock = null

        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        stopSelfAndCleanup()
        super.onDestroy()
    }
}
