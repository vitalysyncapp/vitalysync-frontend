package com.example.vitalysync

import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.app.AlarmManager
import android.app.PendingIntent
import java.util.Calendar

object OverlayAssistantManager {
    const val overlayChannelName = "vitalysync/assistant_overlay"
    const val overlayWindowChannelName = "vitalysync/assistant_overlay/window"

    const val actionStart = "com.example.vitalysync.action.OVERLAY_START"
    const val actionPrepare = "com.example.vitalysync.action.OVERLAY_PREPARE"
    const val actionStop = "com.example.vitalysync.action.OVERLAY_STOP"
    const val actionCollapse = "com.example.vitalysync.action.OVERLAY_COLLAPSE"
    const val actionExpand = "com.example.vitalysync.action.OVERLAY_EXPAND"
    const val actionReminderPreview = "com.example.vitalysync.action.OVERLAY_REMINDER_PREVIEW"
    const val actionGeneratedPreview = "com.example.vitalysync.action.OVERLAY_GENERATED_PREVIEW"
    const val extraReminderTitle = "reminder_title"
    const val extraReminderBody = "reminder_body"
    const val extraReminderPayload = "reminder_payload"
    const val extraReminderType = "reminder_type"
    const val extraPreviewKind = "preview_kind"
    const val extraPreviewTitle = "preview_title"
    const val extraPreviewBody = "preview_body"

    private const val prefsName = "vitalysync_overlay"
    private const val keyEnabled = "enabled"
    private const val keyAppForeground = "app_foreground"
    private const val reminderPreviewRequestCodeOffset = 52000

    fun isOverlayPermissionGranted(context: Context): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(context)
    }

    fun syncSettings(
        context: Context,
        enabled: Boolean,
    ) {
        prefs(context).edit()
            .putBoolean(keyEnabled, enabled)
            .apply()

        if (!enabled || !isOverlayPermissionGranted(context)) {
            stopOverlayService(context)
            return
        }

        if (isAppForeground(context)) {
            if (OverlayAssistantService.isRunning) {
                startOverlayService(context, actionPrepare)
            }
            return
        }

        startOverlayService(context)
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

        if (isForeground) {
            if (OverlayAssistantService.isRunning) {
                startOverlayService(context, actionPrepare)
            }
            return
        }

        startOverlayService(context)
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

    fun scheduleReminderPreview(
        context: Context,
        id: Int,
        title: String,
        body: String,
        hour: Int,
        minute: Int,
        payload: String,
        notificationType: String,
    ) {
        if (id < 0) {
            return
        }

        val nextTrigger = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour.coerceIn(0, 23))
            set(Calendar.MINUTE, minute.coerceIn(0, 59))
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (!after(Calendar.getInstance())) {
                add(Calendar.DAY_OF_YEAR, 1)
            }
        }
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.setWindow(
            AlarmManager.RTC_WAKEUP,
            nextTrigger.timeInMillis,
            5 * 60 * 1000L,
            reminderPreviewPendingIntent(
                context = context,
                id = id,
                hour = hour,
                minute = minute,
                title = title,
                body = body,
                payload = payload,
                notificationType = notificationType,
            ),
        )
    }

    fun cancelReminderPreview(context: Context, id: Int) {
        if (id < 0) {
            return
        }

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(
            reminderPreviewPendingIntent(
                context = context,
                id = id,
                hour = -1,
                minute = -1,
                title = "",
                body = "",
                payload = "",
                notificationType = "",
            ),
        )
    }

    fun onReminderPreviewAlarm(context: Context, intent: Intent?) {
        val title = intent?.getStringExtra(extraReminderTitle)?.trim().orEmpty()
        val body = intent?.getStringExtra(extraReminderBody)?.trim().orEmpty()
        val payload = intent?.getStringExtra(extraReminderPayload)?.trim().orEmpty()
        val notificationType = intent?.getStringExtra(extraReminderType)?.trim().orEmpty()
        val id = intent?.getIntExtra("reminder_id", -1) ?: -1
        val hour = intent?.getIntExtra("reminder_hour", -1) ?: -1
        val minute = intent?.getIntExtra("reminder_minute", -1) ?: -1

        if (id >= 0 && hour >= 0 && minute >= 0) {
            scheduleReminderPreview(
                context = context,
                id = id,
                title = title,
                body = body,
                hour = hour,
                minute = minute,
                payload = payload,
                notificationType = notificationType,
            )
        }

        if (title.isEmpty() && body.isEmpty()) {
            return
        }

        if (!isEnabled(context) ||
            !isOverlayPermissionGranted(context) ||
            isAppForeground(context) ||
            !OverlayAssistantService.isRunning
        ) {
            return
        }

        val serviceIntent = Intent(context, OverlayAssistantService::class.java)
            .setAction(actionReminderPreview)
            .putExtra(extraReminderTitle, title)
            .putExtra(extraReminderBody, body)
            .putExtra(extraReminderPayload, payload)
            .putExtra(extraReminderType, notificationType)
        runCatching { context.startService(serviceIntent) }
    }

    fun showGeneratedPreview(
        context: Context,
        kind: String,
        title: String,
        body: String,
    ): Boolean {
        if (title.trim().isEmpty() && body.trim().isEmpty()) {
            return false
        }

        if (!isEnabled(context) ||
            !isOverlayPermissionGranted(context) ||
            isAppForeground(context) ||
            !OverlayAssistantService.isRunning
        ) {
            return false
        }

        val serviceIntent = Intent(context, OverlayAssistantService::class.java)
            .setAction(actionGeneratedPreview)
            .putExtra(extraPreviewKind, kind)
            .putExtra(extraPreviewTitle, title)
            .putExtra(extraPreviewBody, body)
        return runCatching {
            context.startService(serviceIntent)
            true
        }.getOrDefault(false)
    }

    fun onBootCompleted(context: Context) {
        markAppBackground(context)
    }

    fun isEnabled(context: Context): Boolean = prefs(context).getBoolean(keyEnabled, false)

    fun isAppForeground(context: Context): Boolean =
        prefs(context).getBoolean(keyAppForeground, false)

    private fun prefs(context: Context) =
        context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)

    private fun reminderPreviewPendingIntent(
        context: Context,
        id: Int,
        hour: Int,
        minute: Int,
        title: String,
        body: String,
        payload: String,
        notificationType: String,
    ): PendingIntent {
        val intent = Intent(context, OverlayReminderPreviewReceiver::class.java)
            .setAction(actionReminderPreview)
            .putExtra("reminder_id", id)
            .putExtra(extraReminderTitle, title)
            .putExtra(extraReminderBody, body)
            .putExtra(extraReminderPayload, payload)
            .putExtra(extraReminderType, notificationType)

        if (hour >= 0 && minute >= 0) {
            intent.putExtra("reminder_hour", hour)
            intent.putExtra("reminder_minute", minute)
        }

        return PendingIntent.getBroadcast(
            context,
            reminderPreviewRequestCodeOffset + id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun markAppBackground(context: Context) {
        prefs(context).edit()
            .putBoolean(keyAppForeground, false)
            .apply()
    }
}
