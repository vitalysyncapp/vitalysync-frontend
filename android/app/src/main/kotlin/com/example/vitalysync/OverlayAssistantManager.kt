package com.example.vitalysync

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import java.util.Calendar

object OverlayAssistantManager {
    const val overlayChannelName = "vitalysync/assistant_overlay"
    const val overlayWindowChannelName = "vitalysync/assistant_overlay/window"

    const val actionStart = "com.example.vitalysync.action.OVERLAY_START"
    const val actionPrepare = "com.example.vitalysync.action.OVERLAY_PREPARE"
    const val actionStop = "com.example.vitalysync.action.OVERLAY_STOP"
    const val actionCollapse = "com.example.vitalysync.action.OVERLAY_COLLAPSE"
    const val actionExpand = "com.example.vitalysync.action.OVERLAY_EXPAND"
    const val actionAlarm = "com.example.vitalysync.action.OVERLAY_ALARM"

    private const val prefsName = "vitalysync_overlay"
    private const val keyEnabled = "enabled"
    private const val keyAutoShowEnabled = "auto_show_enabled"
    private const val keyAutoShowTime = "auto_show_time"
    private const val keyAppForeground = "app_foreground"

    fun isOverlayPermissionGranted(context: Context): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(context)
    }

    fun syncSettings(
        context: Context,
        enabled: Boolean,
        autoShowEnabled: Boolean,
        autoShowTime: String,
    ) {
        prefs(context).edit()
            .putBoolean(keyEnabled, enabled)
            .putBoolean(keyAutoShowEnabled, autoShowEnabled)
            .putString(keyAutoShowTime, autoShowTime)
            .apply()

        if (!enabled || !isOverlayPermissionGranted(context)) {
            cancelAutoShowAlarm(context)
            stopOverlayService(context)
            return
        }

        scheduleAutoShowAlarm(context)
        if (isAppForeground(context)) {
            startOverlayService(context, actionPrepare)
        }
    }

    fun syncAppVisibility(context: Context, isForeground: Boolean, enabled: Boolean) {
        prefs(context).edit().putBoolean(keyAppForeground, isForeground).apply()

        if (!enabled || !isOverlayPermissionGranted(context)) {
            stopOverlayService(context)
            return
        }

        if (!isEnabled(context)) {
            stopOverlayService(context)
            return
        }

        startOverlayService(context, if (isForeground) actionPrepare else actionStart)
    }

    fun startOverlayService(context: Context, action: String = actionStart) {
        if (!isEnabled(context) || !isOverlayPermissionGranted(context)) {
            return
        }

        val intent = Intent(context, OverlayAssistantService::class.java).setAction(action)
        runCatching {
            if (OverlayAssistantService.isRunning) {
                context.startService(intent)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }

    fun stopOverlayService(context: Context) {
        if (!OverlayAssistantService.isRunning) {
            return
        }

        runCatching {
            context.startService(
                Intent(context, OverlayAssistantService::class.java).setAction(actionStop),
            )
        }
    }

    fun collapseOverlay(context: Context) {
        if (!OverlayAssistantService.isRunning) {
            return
        }

        runCatching {
            context.startService(
                Intent(context, OverlayAssistantService::class.java).setAction(actionCollapse),
            )
        }
    }

    fun onAutoShowAlarm(context: Context) {
        scheduleAutoShowAlarm(context)

        if (!isEnabled(context) ||
            !isAutoShowEnabled(context) ||
            !isOverlayPermissionGranted(context) ||
            isAppForeground(context)
        ) {
            return
        }

        startOverlayService(context, actionStart)
    }

    fun onBootCompleted(context: Context) {
        if (isEnabled(context) && isAutoShowEnabled(context) && isOverlayPermissionGranted(context)) {
            scheduleAutoShowAlarm(context)
        }
    }

    fun isEnabled(context: Context): Boolean = prefs(context).getBoolean(keyEnabled, false)

    private fun isAutoShowEnabled(context: Context): Boolean =
        prefs(context).getBoolean(keyAutoShowEnabled, false)

    private fun isAppForeground(context: Context): Boolean =
        prefs(context).getBoolean(keyAppForeground, true)

    private fun scheduleAutoShowAlarm(context: Context) {
        if (!isEnabled(context) || !isAutoShowEnabled(context) || !isOverlayPermissionGranted(context)) {
            cancelAutoShowAlarm(context)
            return
        }

        val (hour, minute) = parseTime(
            prefs(context).getString(keyAutoShowTime, "06:50") ?: "06:50",
        )
        val nextTrigger = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (!after(Calendar.getInstance())) {
                add(Calendar.DAY_OF_YEAR, 1)
            }
        }

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = alarmPendingIntent(context)

        when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ->
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    nextTrigger.timeInMillis,
                    pendingIntent,
                )
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT ->
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    nextTrigger.timeInMillis,
                    pendingIntent,
                )
            else ->
                alarmManager.set(
                    AlarmManager.RTC_WAKEUP,
                    nextTrigger.timeInMillis,
                    pendingIntent,
                )
        }
    }

    private fun cancelAutoShowAlarm(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(alarmPendingIntent(context))
    }

    private fun alarmPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, OverlayAssistantAlarmReceiver::class.java).setAction(actionAlarm)
        return PendingIntent.getBroadcast(
            context,
            4107,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)

    private fun parseTime(value: String): Pair<Int, Int> {
        val parts = value.split(":")
        val hour = parts.getOrNull(0)?.toIntOrNull()?.coerceIn(0, 23) ?: 6
        val minute = parts.getOrNull(1)?.toIntOrNull()?.coerceIn(0, 59) ?: 50
        return hour to minute
    }
}
