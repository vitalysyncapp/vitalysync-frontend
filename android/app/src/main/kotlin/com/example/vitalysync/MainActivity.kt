package com.example.vitalysync

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        const val launchPayloadExtra = "vitalysync_launch_payload"
        private const val appLaunchChannelName = "vitalysync/app_launch"
    }

    private var appLaunchChannel: MethodChannel? = null
    private var pendingLaunchPayload: String? = null

    override fun onResume() {
        super.onResume()
        OverlayAssistantManager.syncAppVisibility(
            context = applicationContext,
            isForeground = true,
            enabled = OverlayAssistantManager.isEnabled(applicationContext),
        )
    }

    override fun onPause() {
        OverlayAssistantManager.syncAppVisibility(
            context = applicationContext,
            isForeground = false,
            enabled = OverlayAssistantManager.isEnabled(applicationContext),
        )
        super.onPause()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        val payload = readLaunchPayload(intent) ?: return
        pendingLaunchPayload = payload
        appLaunchChannel?.invokeMethod("launchPayload", payload)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        appLaunchChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            appLaunchChannelName,
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "consumeInitialPayload" -> {
                        result.success(consumePendingLaunchPayload())
                    }

                    else -> result.notImplemented()
                }
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            OverlayAssistantManager.overlayChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isOverlayPermissionGranted" -> {
                    result.success(OverlayAssistantManager.isOverlayPermissionGranted(this))
                }

                "canScheduleExactAlarms" -> {
                    result.success(OverlayAssistantManager.canScheduleExactAlarms(this))
                }

                "openOverlayPermissionSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName"),
                        ).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        runCatching { startActivity(intent) }
                    }
                    result.success(null)
                }

                "openExactAlarmSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val intent = Intent(
                            Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                            Uri.parse("package:$packageName"),
                        ).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        runCatching { startActivity(intent) }
                    }
                    result.success(null)
                }

                "syncOverlaySettings" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    val autoShowEnabled = call.argument<Boolean>("autoShowEnabled") ?: false
                    val autoShowTime = call.argument<String>("autoShowTime") ?: "06:50"
                    OverlayAssistantManager.syncSettings(
                        context = applicationContext,
                        enabled = enabled,
                        autoShowEnabled = autoShowEnabled,
                        autoShowTime = autoShowTime,
                    )
                    result.success(null)
                }

                "syncAppVisibility" -> {
                    val isForeground = call.argument<Boolean>("isForeground") ?: true
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    OverlayAssistantManager.syncAppVisibility(
                        context = applicationContext,
                        isForeground = isForeground,
                        enabled = enabled,
                    )
                    result.success(null)
                }

                "startOverlayService" -> {
                    OverlayAssistantManager.startOverlayService(applicationContext)
                    result.success(null)
                }

                "stopOverlayService" -> {
                    OverlayAssistantManager.stopOverlayService(applicationContext)
                    result.success(null)
                }

                "collapseOverlay" -> {
                    OverlayAssistantManager.collapseOverlay(applicationContext)
                    result.success(null)
                }

                "openApp" -> {
                    OverlayAssistantManager.openApp(
                        context = applicationContext,
                        payload = call.argument<String>("payload"),
                    )
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        appLaunchChannel?.setMethodCallHandler(null)
        appLaunchChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun consumePendingLaunchPayload(): String? {
        val payload = pendingLaunchPayload ?: readLaunchPayload(intent)
        pendingLaunchPayload = null
        intent?.removeExtra(launchPayloadExtra)
        return payload
    }

    private fun readLaunchPayload(intent: Intent?): String? {
        val payload = intent?.getStringExtra(launchPayloadExtra)?.trim()
        return if (payload.isNullOrEmpty()) null else payload
    }
}
