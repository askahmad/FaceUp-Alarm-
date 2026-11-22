package com.faceup.face_up_alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

/**
 * AlarmScheduler
 *
 * Shared helper for scheduling and restoring alarms in Android OS.
 * Used by both MainActivity (when user saves an alarm) and BootReceiver (after device reboot).
 */
object AlarmScheduler {

    /**
     * Schedule a single alarm with AlarmManager
     */
    fun schedule(
        context: Context,
        id: Int,
        triggerAtMillis: Long,
        alarmIdString: String,
        ringtoneUri: String,
        faceMode: Boolean
    ): Boolean {
        // Safety: Do not schedule past alarms
        if (triggerAtMillis <= System.currentTimeMillis()) {
            return false
        }

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val intent = Intent(context, AlarmBroadcastReceiver::class.java).apply {
            action = "FACEUP_ALARM_TRIGGER"
            putExtra(AlarmForegroundService.EXTRA_ALARM_ID, alarmIdString)
            putExtra(AlarmForegroundService.EXTRA_RINGTONE_URI, ringtoneUri)
            putExtra(AlarmForegroundService.EXTRA_FACE_MODE, faceMode)
        }

        // FLAG_UPDATE_CURRENT avoids duplicates and updates any existing scheduled alarm with same ID
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val showIntent = Intent(context, MainActivity::class.java)
        val showPendingIntent = PendingIntent.getActivity(
            context,
            id,
            showIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return try {
            val clockInfo = AlarmManager.AlarmClockInfo(triggerAtMillis, showPendingIntent)
            alarmManager.setAlarmClock(clockInfo, pendingIntent)
            true
        } catch (_: Exception) {
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
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    /**
     * Cancel an alarm
     */
    fun cancel(context: Context, id: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AlarmBroadcastReceiver::class.java).apply {
            action = "FACEUP_ALARM_TRIGGER"
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
    }

    /**
     * Restore all enabled alarms from SharedPreferences after reboot or time change
     */
    fun restoreAllAlarms(context: Context): Int {
        var restoredCount = 0
        try {
            // Flutter SharedPreferences are stored in "FlutterSharedPreferences" xml with "flutter." prefix
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val alarmsJsonString = prefs.getString("flutter.alarms", null) ?: return 0

            val alarmsArray = JSONArray(alarmsJsonString)
            val now = System.currentTimeMillis()

            for (i in 0 until alarmsArray.length()) {
                val alarmObj = alarmsArray.getJSONObject(i)
                val isEnabled = alarmObj.optBoolean("isEnabled", true)
                if (!isEnabled) continue

                val idString = alarmObj.optString("id", "")
                val hour = alarmObj.optInt("hour", 7)
                val minute = alarmObj.optInt("minute", 0)
                val ringtoneUri = alarmObj.optString("ringtoneUri", "")
                val faceMode = alarmObj.optBoolean("faceMode", true)
                val createdAt = alarmObj.optLong("createdAt", now)

                // Repeat days: 1=Sun, 2=Mon...7=Sat
                val repeatDays = mutableListOf<Int>()
                val daysArray = alarmObj.optJSONArray("repeatDays")
                if (daysArray != null) {
                    for (j in 0 until daysArray.length()) {
                        repeatDays.add(daysArray.getInt(j))
                    }
                }

                val nextMillis = calculateNextAlarmMillis(hour, minute, repeatDays)
                if (nextMillis != null && nextMillis > now) {
                    val intId = (createdAt % 2147483647).toInt()
                    val scheduled = schedule(context, intId, nextMillis, idString, ringtoneUri, faceMode)
                    if (scheduled) restoredCount++
                }
            }
        } catch (_: Exception) {}
        return restoredCount
    }

    /**
     * Calculate next alarm trigger millis in Android
     */
    private fun calculateNextAlarmMillis(hour: Int, minute: Int, repeatDays: List<Int>): Long? {
        val now = Calendar.getInstance()

        if (repeatDays.isEmpty()) {
            // One-time alarm
            val target = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, hour)
                set(Calendar.MINUTE, minute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            if (target.after(now)) {
                return target.timeInMillis
            } else {
                target.add(Calendar.DAY_OF_YEAR, 1)
                return target.timeInMillis
            }
        }

        // Repeating alarm: check next 8 days
        for (i in 0..7) {
            val candidate = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, i)
                set(Calendar.HOUR_OF_DAY, hour)
                set(Calendar.MINUTE, minute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val dayOfWeek = candidate.get(Calendar.DAY_OF_WEEK) // 1=Sun, 2=Mon...7=Sat
            if (repeatDays.contains(dayOfWeek) && candidate.after(now)) {
                return candidate.timeInMillis
            }
        }

        return null
    }
}
