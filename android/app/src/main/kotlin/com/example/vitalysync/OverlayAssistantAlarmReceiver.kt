package com.example.vitalysync

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class OverlayAssistantAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        // Kept as a no-op so old scheduled overlay intents cannot restart removed auto-appear behavior.
    }
}
