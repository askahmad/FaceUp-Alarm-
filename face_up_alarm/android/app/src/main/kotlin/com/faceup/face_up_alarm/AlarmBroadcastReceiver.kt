package com.faceup.face_up_alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

/**
 * AlarmBroadcastReceiver
 *
 * Android OS ye receiver tab call karta hai jab AlarmManager ka timer poora hota hai.
 *
 * Is receiver ka kaam:
 * 1. Intent se alarm info nikalna.
 * 2. AlarmForegroundService ko start karna jo ringtone, vibration aur full-screen notification chalayegi.
 */
class AlarmBroadcastReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val alarmId = intent.getStringExtra(AlarmForegroundService.EXTRA_ALARM_ID) ?: "unknown_alarm"
        val ringtoneUri = intent.getStringExtra(AlarmForegroundService.EXTRA_RINGTONE_URI) ?: ""
        val faceMode = intent.getBooleanExtra(AlarmForegroundService.EXTRA_FACE_MODE, true)

        val serviceIntent = Intent(context, AlarmForegroundService::class.java).apply {
            putExtra(AlarmForegroundService.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmForegroundService.EXTRA_RINGTONE_URI, ringtoneUri)
            putExtra(AlarmForegroundService.EXTRA_FACE_MODE, faceMode)
        }

        try {
            ContextCompat.startForegroundService(context, serviceIntent)
        } catch (_: Exception) {
            // Fallback for older devices
            context.startService(serviceIntent)
        }
    }
}
