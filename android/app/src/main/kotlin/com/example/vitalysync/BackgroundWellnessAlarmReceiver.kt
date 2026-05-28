package com.example.vitalysync

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BackgroundWellnessAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != BackgroundWellnessManager.actionCollect) {
            return
        }

        BackgroundWellnessManager.onDailyAlarm(context, goAsync())
    }
}
