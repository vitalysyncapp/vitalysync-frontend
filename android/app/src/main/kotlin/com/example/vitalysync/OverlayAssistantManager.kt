package com.example.vitalysync

import android.app.AlarmManager
import android.app.KeyguardManager
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
    const val actionAutoShow = "com.example.vitalysync.action.OVERLAY_AUTO_SHOW"
    const val actionAlarm = "com.example.vitalysync.action.OVERLAY_ALARM"
    const val actionDayStart = "com.example.vitalysync.action.OVERLAY_DAY_START"

    private const val prefsName = "vitalysync_overlay"
    private const val keyEnabled = "enabled"
    private const val keyAutoShowEnabled = "auto_show_enabled"
    private const val keyAutoShowTime = "auto_show_time"
    private const val keyAppForeground = "app_foreground"
    private const val keyLastAutoShowDate = "last_auto_show_date"
    private const val keyPendingAutoShowDate = "pending_auto_show_date"
    private const val keyLastTrackingPrimeDate = "last_tracking_prime_date"

    fun isOverlayPermissionGranted(context: Context): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(context)
    }

    fun canScheduleExactAlarms(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return true
        }

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return alarmManager.canScheduleExactAlarms()
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
            cancelDayStartTrackingAlarm(context)
            stopOverlayService(context)
            return
        }

        scheduleAutoShowAlarm(context)
        scheduleDayStartTrackingAlarm(context)
        if (isAppForeground(context)) {
            startOverlayService(context, actionPrepare)
        }
    }

    fun syncAppVisibility(context: Context, isForeground: Boolean, enabled: Boolean) {
        prefs(context).edit()
            .putBoolean(keyAppForeground, isForeground)
            .apply()

        if (!enabled || !isOverlayPermissionGranted(context)) {
            stopOverlayService(context)
            return
        }

        if (!isEnabled(context)) {
            stopOverlayService(context)
            return
        }

        if (!isForeground && shouldAutoShowToday(context)) {
            showAutoOverlay(context)
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

    fun openApp(context: Context, payload: String? = null) {
        val launchIntent = (
            context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, MainActivity::class.java)
        ).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP,
            )

            val normalizedPayload = payload?.trim()
            if (!normalizedPayload.isNullOrEmpty()) {
                putExtra(MainActivity.launchPayloadExtra, normalizedPayload)
            }
        }

        runCatching { context.startActivity(launchIntent) }
    }

    fun onAutoShowAlarm(context: Context) {
        scheduleAutoShowAlarm(context)

        if (!isEnabled(context) ||
            !isAutoShowEnabled(context) ||
            !isOverlayPermissionGranted(context)
        ) {
            return
        }

        if (isAppForeground(context) || isDeviceLocked(context)) {
            markPendingAutoShow(context)
            return
        }

        showAutoOverlay(context)
    }

    fun onBootCompleted(context: Context) {
        markAppBackground(context)
        if (isEnabled(context) && isOverlayPermissionGranted(context)) {
            scheduleAutoShowAlarm(context)
            scheduleDayStartTrackingAlarm(context)
        }
    }

    fun onExactAlarmPermissionChanged(context: Context) {
        if (!isEnabled(context) || !isOverlayPermissionGranted(context)) {
            return
        }

        scheduleAutoShowAlarm(context)
    }

    fun onUserPresent(context: Context) {
        if (!isEnabled(context) || !isOverlayPermissionGranted(context)) {
            return
        }

        scheduleAutoShowAlarm(context)
        scheduleDayStartTrackingAlarm(context)
        primeDailyTrackingIfNeeded(context)

        if (shouldAutoShowToday(context)) {
            showAutoOverlay(context)
        }
    }

    fun onDayStartAlarm(context: Context) {
        scheduleDayStartTrackingAlarm(context)

        if (!isEnabled(context) || !isOverlayPermissionGranted(context) || isDeviceLocked(context)) {
            return
        }

        primeDailyTrackingIfNeeded(context)
    }

    fun isEnabled(context: Context): Boolean = prefs(context).getBoolean(keyEnabled, false)

    private fun isAutoShowEnabled(context: Context): Boolean =
        prefs(context).getBoolean(keyAutoShowEnabled, false)

    private fun isAppForeground(context: Context): Boolean =
        prefs(context).getBoolean(keyAppForeground, false)

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
        val pendingIntent = alarmPendingIntent(context, actionAlarm, 4107)
        val triggerAtMillis = nextTrigger.timeInMillis

        when {
            canUseExactAlarms(alarmManager) ->
                runCatching {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            triggerAtMillis,
                            pendingIntent,
                        )
                    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                        alarmManager.setExact(
                            AlarmManager.RTC_WAKEUP,
                            triggerAtMillis,
                            pendingIntent,
                        )
                    } else {
                        alarmManager.set(
                            AlarmManager.RTC_WAKEUP,
                            triggerAtMillis,
                            pendingIntent,
                        )
                    }
                }.onFailure {
                    scheduleApproximateAlarm(alarmManager, triggerAtMillis, pendingIntent)
                }
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ->
                scheduleApproximateAlarm(alarmManager, triggerAtMillis, pendingIntent)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT ->
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent,
                )
            else ->
                alarmManager.set(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent,
                )
        }
    }

    private fun cancelAutoShowAlarm(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(alarmPendingIntent(context, actionAlarm, 4107))
    }

    private fun scheduleDayStartTrackingAlarm(context: Context) {
        if (!isEnabled(context) || !isOverlayPermissionGranted(context)) {
            cancelDayStartTrackingAlarm(context)
            return
        }

        val nextTrigger = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 2)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = alarmPendingIntent(context, actionDayStart, 4106)

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

    private fun cancelDayStartTrackingAlarm(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(alarmPendingIntent(context, actionDayStart, 4106))
    }

    private fun canUseExactAlarms(alarmManager: AlarmManager): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarmManager.canScheduleExactAlarms()
    }

    private fun scheduleApproximateAlarm(
        alarmManager: AlarmManager,
        triggerAtMillis: Long,
        pendingIntent: PendingIntent,
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAtMillis,
                pendingIntent,
            )
        } else {
            alarmManager.set(
                AlarmManager.RTC_WAKEUP,
                triggerAtMillis,
                pendingIntent,
            )
        }
    }

    private fun alarmPendingIntent(context: Context, action: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, OverlayAssistantAlarmReceiver::class.java).setAction(action)
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)

    private fun markAppBackground(context: Context) {
        prefs(context).edit()
            .putBoolean(keyAppForeground, false)
            .apply()
    }

    private fun shouldAutoShowToday(context: Context): Boolean {
        if (!isAutoShowEnabled(context) || isAppForeground(context)) {
            return false
        }

        val today = todayKey()
        if (prefs(context).getString(keyLastAutoShowDate, null) == today) {
            return false
        }

        val pendingDate = prefs(context).getString(keyPendingAutoShowDate, null)
        return pendingDate == today || hasAutoShowTimePassedToday(context)
    }

    private fun showAutoOverlay(context: Context) {
        val today = todayKey()
        prefs(context).edit()
            .putString(keyLastAutoShowDate, today)
            .remove(keyPendingAutoShowDate)
            .apply()
        startOverlayService(context, actionAutoShow)
    }

    private fun markPendingAutoShow(context: Context) {
        prefs(context).edit()
            .putString(keyPendingAutoShowDate, todayKey())
            .apply()
    }

    private fun primeDailyTrackingIfNeeded(context: Context) {
        val today = todayKey()
        if (prefs(context).getString(keyLastTrackingPrimeDate, null) == today) {
            return
        }

        prefs(context).edit()
            .putString(keyLastTrackingPrimeDate, today)
            .apply()
        startOverlayService(context, actionPrepare)
    }

    private fun hasAutoShowTimePassedToday(context: Context): Boolean {
        val (hour, minute) = parseTime(
            prefs(context).getString(keyAutoShowTime, "06:50") ?: "06:50",
        )
        val scheduledToday = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        return !Calendar.getInstance().before(scheduledToday)
    }

    private fun isDeviceLocked(context: Context): Boolean {
        val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        return keyguardManager.isKeyguardLocked
    }

    private fun todayKey(): String {
        val calendar = Calendar.getInstance()
        val month = (calendar.get(Calendar.MONTH) + 1).toString().padStart(2, '0')
        val day = calendar.get(Calendar.DAY_OF_MONTH).toString().padStart(2, '0')
        return "${calendar.get(Calendar.YEAR)}-$month-$day"
    }

    private fun parseTime(value: String): Pair<Int, Int> {
        val parts = value.split(":")
        val hour = parts.getOrNull(0)?.toIntOrNull()?.coerceIn(0, 23) ?: 6
        val minute = parts.getOrNull(1)?.toIntOrNull()?.coerceIn(0, 59) ?: 50
        return hour to minute
    }
}
