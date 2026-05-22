package com.example.vitalysync

import android.app.AlarmManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class OverlayAssistantBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> OverlayAssistantManager.onBootCompleted(context)
            Intent.ACTION_USER_PRESENT -> OverlayAssistantManager.onUserPresent(context)
            AlarmManager.ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED ->
                OverlayAssistantManager.onExactAlarmPermissionChanged(context)
        }
    }
}
