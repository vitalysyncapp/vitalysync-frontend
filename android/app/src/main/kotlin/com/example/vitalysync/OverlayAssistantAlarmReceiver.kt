package com.example.vitalysync

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class OverlayAssistantAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == OverlayAssistantManager.actionAlarm) {
            OverlayAssistantManager.onAutoShowAlarm(context)
        }
    }
}
