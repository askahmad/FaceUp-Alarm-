package com.faceup.face_up_alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * BootReceiver
 *
 * Phone restart hone ya clock/timezone change hone par ye receiver Android OS se trigger hota hai.
 * SharedPreferences se saari enabled alarms read karke AlarmManager se dobara schedule karta hai.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return

        val validActions = listOf(
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.miui.powercenter.poweron",
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED
        )

        if (action in validActions) {
            // Restore all future enabled alarms
            AlarmScheduler.restoreAllAlarms(context)
        }
    }
}
