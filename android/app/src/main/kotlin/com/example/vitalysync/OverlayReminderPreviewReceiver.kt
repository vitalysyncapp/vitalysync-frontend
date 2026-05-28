package com.example.vitalysync

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class OverlayReminderPreviewReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != OverlayAssistantManager.actionReminderPreview) {
            return
        }

        OverlayAssistantManager.onReminderPreviewAlarm(context, intent)
    }
}
