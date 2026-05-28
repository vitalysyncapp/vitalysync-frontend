package com.example.vitalysync

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.util.Calendar

object BackgroundWellnessManager {
    const val actionCollect = "com.example.vitalysync.action.BACKGROUND_WELLNESS_COLLECT"
    private const val channelName = "vitalysync/background_wellness"
    private const val requestCode = 4206
    private const val collectionHour = 6
    private const val collectionMinute = 30
    private const val collectionWindowMillis = 30 * 60 * 1000L
    private const val maxRunMillis = 45 * 1000L

    private val mainHandler = Handler(Looper.getMainLooper())
    private var activeEngine: FlutterEngine? = null
    private var activeChannel: MethodChannel? = null
    private var activePendingResult: BroadcastReceiver.PendingResult? = null
    private var timeoutRunnable: Runnable? = null

    fun scheduleDailyCollection(context: Context) {
        val nextTrigger = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, collectionHour)
            set(Calendar.MINUTE, collectionMinute)
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
            collectionWindowMillis,
            collectionPendingIntent(context),
        )
    }

    fun onDailyAlarm(
        context: Context,
        pendingResult: BroadcastReceiver.PendingResult,
    ) {
        scheduleDailyCollection(context)
        startCollection(context.applicationContext, pendingResult)
    }

    @Synchronized
    private fun startCollection(
        context: Context,
        pendingResult: BroadcastReceiver.PendingResult,
    ) {
        if (activeEngine != null) {
            pendingResult.finish()
            return
        }

        activePendingResult = pendingResult

        runCatching {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(context)
            loader.ensureInitializationComplete(context, null)

            val engine = FlutterEngine(context)
            GeneratedPluginRegistrant.registerWith(engine)

            val channel = MethodChannel(engine.dartExecutor.binaryMessenger, channelName)
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "backgroundRunComplete" -> {
                        result.success(null)
                        finishActiveRun()
                    }

                    else -> result.notImplemented()
                }
            }

            activeEngine = engine
            activeChannel = channel
            timeoutRunnable = Runnable { finishActiveRun() }.also {
                mainHandler.postDelayed(it, maxRunMillis)
            }

            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(
                    loader.findAppBundlePath(),
                    "backgroundWellnessMain",
                ),
            )
        }.onFailure {
            finishActiveRun()
        }
    }

    @Synchronized
    private fun finishActiveRun() {
        timeoutRunnable?.let { mainHandler.removeCallbacks(it) }
        timeoutRunnable = null

        activeChannel?.setMethodCallHandler(null)
        activeChannel = null

        activeEngine?.destroy()
        activeEngine = null

        activePendingResult?.finish()
        activePendingResult = null
    }

    private fun collectionPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, BackgroundWellnessAlarmReceiver::class.java)
            .setAction(actionCollect)
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
