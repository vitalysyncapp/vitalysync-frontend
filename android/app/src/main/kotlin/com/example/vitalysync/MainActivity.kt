package com.example.vitalysync

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            OverlayAssistantManager.overlayChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isOverlayPermissionGranted" -> {
                    result.success(OverlayAssistantManager.isOverlayPermissionGranted(this))
                }

                "openOverlayPermissionSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName"),
                        ).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
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

                else -> result.notImplemented()
            }
        }
    }
}
