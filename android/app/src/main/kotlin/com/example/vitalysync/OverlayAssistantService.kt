package com.example.vitalysync

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Rect
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterTextureView
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import kotlin.math.abs
import kotlin.math.max

class OverlayAssistantService : Service() {
    companion object {
        @Volatile
        var isRunning: Boolean = false

        private const val notificationChannelId = "vitalysync_floating_assistant"
        private const val notificationId = 4108
        private const val nativePrefsName = "vitalysync_overlay"
        private const val keyBubbleX = "bubble_x"
        private const val keyBubbleY = "bubble_y"
    }

    private lateinit var windowManager: WindowManager
    private var flutterEngine: FlutterEngine? = null
    private var flutterView: FlutterView? = null
    private var rootView: FrameLayout? = null
    private var dismissView: View? = null
    private var overlayChannel: MethodChannel? = null
    private var overlayWindowChannel: MethodChannel? = null
    private var windowLayoutParams: WindowManager.LayoutParams? = null
    private var isBubbleMode = true
    private val mainHandler = Handler(Looper.getMainLooper())
    private var reminderPreviewCollapseRunnable: Runnable? = null

    private var initialWindowX = 0
    private var initialWindowY = 0
    private var initialTouchX = 0f
    private var initialTouchY = 0f
    private var didDrag = false

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        createNotificationChannel()
        startForeground(notificationId, buildNotification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            OverlayAssistantManager.actionStop -> stopSelf()
            OverlayAssistantManager.actionPrepare -> {
                ensureOverlayView()
                detachOverlayWindow()
                flutterEngine?.lifecycleChannel?.appIsPaused()
            }
            OverlayAssistantManager.actionCollapse -> {
                ensureOverlayView()
                collapseToBubble()
            }
            OverlayAssistantManager.actionExpand -> {
                ensureOverlayView()
                expandPanel()
            }
            OverlayAssistantManager.actionReminderPreview -> {
                ensureOverlayView()
                showReminderPreview(intent)
            }
            OverlayAssistantManager.actionGeneratedPreview -> {
                ensureOverlayView()
                showGeneratedPreview(intent)
            }
            else -> {
                if (!OverlayAssistantManager.isEnabled(this) ||
                    !OverlayAssistantManager.isOverlayPermissionGranted(this)
                ) {
                    stopSelf()
                } else if (OverlayAssistantManager.isAppForeground(this)) {
                    ensureOverlayView()
                    detachOverlayWindow()
                    flutterEngine?.lifecycleChannel?.appIsPaused()
                } else {
                    ensureOverlayView()
                    collapseToBubble()
                }
            }
        }

        return START_STICKY
    }

    override fun onDestroy() {
        destroyOverlayEngine()
        isRunning = false
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun ensureOverlayView() {
        if (rootView != null) {
            return
        }

        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, null)

        val engine = FlutterEngine(this)
        GeneratedPluginRegistrant.registerWith(engine)
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(
                loader.findAppBundlePath(),
                "overlayAssistantMain",
            ),
        )

        overlayChannel = MethodChannel(
            engine.dartExecutor.binaryMessenger,
            OverlayAssistantManager.overlayChannelName,
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "collapseOverlay" -> {
                        collapseToBubble()
                        result.success(null)
                    }
                    "stopOverlayService" -> {
                        stopSelf()
                        result.success(null)
                    }
                    "openApp" -> {
                        OverlayAssistantManager.openApp(
                            applicationContext,
                            call.argument<String>("payload"),
                        )
                        detachOverlayWindow()
                        result.success(null)
                    }
                    "showGeneratedPreview" -> {
                        val wasShown = showGeneratedPreview(
                            kind = call.argument<String>("kind") ?: "smart",
                            title = call.argument<String>("title") ?: "",
                            body = call.argument<String>("body") ?: "",
                        )
                        result.success(wasShown)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        overlayWindowChannel = MethodChannel(
            engine.dartExecutor.binaryMessenger,
            OverlayAssistantManager.overlayWindowChannelName,
        )

        val textureView = FlutterTextureView(this).apply {
            setOpaque(false)
        }
        val view = FlutterView(this, textureView)
        view.setBackgroundColor(Color.TRANSPARENT)
        view.attachToFlutterEngine(engine)
        view.setOnTouchListener { _, event -> handleBubbleTouch(event) }

        val container = FrameLayout(this).apply {
            setBackgroundColor(Color.TRANSPARENT)
            clipChildren = false
            clipToPadding = false
            addView(
                view,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT,
                ),
            )
            setOnTouchListener { _, event -> handleBubbleTouch(event) }
        }

        flutterEngine = engine
        flutterView = view
        rootView = container
    }

    private fun destroyOverlayEngine() {
        cancelReminderPreviewCollapse()
        removeDismissTarget()
        rootView?.let { view ->
            runCatching {
                if (view.isAttachedToWindow) {
                    windowManager.removeView(view)
                }
            }
        }
        flutterView?.detachFromFlutterEngine()
        overlayChannel?.setMethodCallHandler(null)
        flutterEngine?.destroy()
        flutterView = null
        flutterEngine = null
        overlayChannel = null
        overlayWindowChannel = null
        rootView = null
        windowLayoutParams = null
        isBubbleMode = true
    }

    private fun detachOverlayWindow() {
        cancelReminderPreviewCollapse()
        removeDismissTarget()
        rootView?.let { view ->
            runCatching {
                if (view.isAttachedToWindow) {
                    windowManager.removeView(view)
                }
            }
        }
        windowLayoutParams = null
        isBubbleMode = true
    }

    private fun handleBubbleTouch(event: MotionEvent): Boolean {
        if (!isBubbleMode) {
            return false
        }

        val layoutParams = windowLayoutParams ?: return false
        val touchSlop = ViewConfiguration.get(this).scaledTouchSlop

        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                initialWindowX = layoutParams.x
                initialWindowY = layoutParams.y
                initialTouchX = event.rawX
                initialTouchY = event.rawY
                didDrag = false
                return true
            }

            MotionEvent.ACTION_MOVE -> {
                val deltaX = (event.rawX - initialTouchX).toInt()
                val deltaY = (event.rawY - initialTouchY).toInt()
                if (!didDrag && (abs(deltaX) > touchSlop || abs(deltaY) > touchSlop)) {
                    didDrag = true
                    showDismissTarget()
                }

                if (didDrag) {
                    layoutParams.x = initialWindowX + deltaX
                    layoutParams.y = initialWindowY + deltaY
                    clampBubblePosition(layoutParams)
                    updateOverlayLayout()
                    updateDismissTargetState(isOverDismissTarget(layoutParams))
                }
                return true
            }

            MotionEvent.ACTION_UP,
            MotionEvent.ACTION_CANCEL -> {
                val shouldDismiss = didDrag && isOverDismissTarget(layoutParams)
                removeDismissTarget()
                return if (shouldDismiss) {
                    stopSelf()
                    true
                } else if (didDrag) {
                    snapBubbleToEdge(layoutParams)
                    persistBubblePosition(layoutParams)
                    updateOverlayLayout()
                    true
                } else {
                    expandPanel()
                    true
                }
            }
        }

        return false
    }

    private fun collapseToBubble() {
        cancelReminderPreviewCollapse()
        if (OverlayAssistantManager.isAppForeground(this)) {
            detachOverlayWindow()
            flutterEngine?.lifecycleChannel?.appIsPaused()
            return
        }

        isBubbleMode = true
        val root = rootView ?: return
        flutterEngine?.lifecycleChannel?.appIsResumed()
        val metrics = resources.displayMetrics
        val bubbleSize = dpToPx(88)
        val params = windowLayoutParams ?: WindowManager.LayoutParams(
            bubbleSize,
            bubbleSize,
            overlayWindowType(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
        }

        params.width = bubbleSize
        params.height = bubbleSize

        val savedX = overlayPrefs().getInt(keyBubbleX, metrics.widthPixels - bubbleSize - dpToPx(18))
        val savedY = overlayPrefs().getInt(keyBubbleY, metrics.heightPixels - bubbleSize - dpToPx(180))
        params.x = savedX
        params.y = savedY
        clampBubblePosition(params)
        windowLayoutParams = params

        if (!attachOrUpdateRootView(root, params)) {
            return
        }
        overlayWindowChannel?.invokeMethod("setOverlayMode", "bubble")
    }

    private fun expandPanel() {
        cancelReminderPreviewCollapse()
        if (OverlayAssistantManager.isAppForeground(this)) {
            detachOverlayWindow()
            flutterEngine?.lifecycleChannel?.appIsPaused()
            return
        }

        isBubbleMode = false
        val root = rootView ?: return
        flutterEngine?.lifecycleChannel?.appIsResumed()
        val metrics = resources.displayMetrics
        val horizontalMargin = dpToPx(16)
        val verticalMargin = dpToPx(32)
        val width = max(dpToPx(320), minOf(dpToPx(420), metrics.widthPixels - (horizontalMargin * 2)))
        val height = minOf((metrics.heightPixels * 0.76f).toInt(), metrics.heightPixels - (verticalMargin * 2))

        val params = windowLayoutParams ?: WindowManager.LayoutParams(
            width,
            height,
            overlayWindowType(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
        }

        params.width = width
        params.height = height
        params.x = ((metrics.widthPixels - width) / 2).coerceAtLeast(horizontalMargin)
        params.y = ((metrics.heightPixels - height) / 2).coerceAtLeast(verticalMargin)
        windowLayoutParams = params

        if (!attachOrUpdateRootView(root, params)) {
            return
        }
        overlayWindowChannel?.invokeMethod("setOverlayMode", "panel")
    }

    private fun showReminderPreview(intent: Intent?): Boolean {
        if (!OverlayAssistantManager.isEnabled(this) ||
            !OverlayAssistantManager.isOverlayPermissionGranted(this) ||
            OverlayAssistantManager.isAppForeground(this)
        ) {
            detachOverlayWindow()
            return false
        }

        val title = intent?.getStringExtra(OverlayAssistantManager.extraReminderTitle)?.trim().orEmpty()
        val body = intent?.getStringExtra(OverlayAssistantManager.extraReminderBody)?.trim().orEmpty()
        if (title.isEmpty() && body.isEmpty()) {
            return false
        }

        cancelReminderPreviewCollapse()
        removeDismissTarget()
        isBubbleMode = false
        val root = rootView ?: return false
        flutterEngine?.lifecycleChannel?.appIsResumed()

        val metrics = resources.displayMetrics
        val horizontalMargin = dpToPx(16)
        val width = max(dpToPx(300), minOf(dpToPx(390), metrics.widthPixels - (horizontalMargin * 2)))
        val height = dpToPx(168)
        val params = windowLayoutParams ?: WindowManager.LayoutParams(
            width,
            height,
            overlayWindowType(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
        }

        params.width = width
        params.height = height
        params.x = ((metrics.widthPixels - width) / 2).coerceAtLeast(horizontalMargin)
        params.y = dpToPx(72)
        windowLayoutParams = params

        if (!attachOrUpdateRootView(root, params)) {
            return false
        }
        overlayWindowChannel?.invokeMethod(
            "showReminderPreview",
            mapOf(
                "title" to title,
                "body" to body,
                "payload" to intent?.getStringExtra(OverlayAssistantManager.extraReminderPayload).orEmpty(),
                "notificationType" to intent?.getStringExtra(OverlayAssistantManager.extraReminderType).orEmpty(),
            ),
        )

        reminderPreviewCollapseRunnable = Runnable { collapseToBubble() }.also {
            mainHandler.postDelayed(it, 5000L)
        }
        return true
    }

    private fun showGeneratedPreview(intent: Intent?): Boolean {
        return showGeneratedPreview(
            kind = intent?.getStringExtra(OverlayAssistantManager.extraPreviewKind).orEmpty(),
            title = intent?.getStringExtra(OverlayAssistantManager.extraPreviewTitle).orEmpty(),
            body = intent?.getStringExtra(OverlayAssistantManager.extraPreviewBody).orEmpty(),
        )
    }

    private fun showGeneratedPreview(kind: String, title: String, body: String): Boolean {
        if (OverlayAssistantManager.isAppForeground(this)) {
            detachOverlayWindow()
            return false
        }

        if (!isBubbleMode ||
            !OverlayAssistantManager.isEnabled(this) ||
            !OverlayAssistantManager.isOverlayPermissionGranted(this)
        ) {
            return false
        }

        val cleanTitle = title.trim()
        val cleanBody = body.trim()
        if (cleanTitle.isEmpty() && cleanBody.isEmpty()) {
            return false
        }

        cancelReminderPreviewCollapse()
        removeDismissTarget()
        isBubbleMode = false
        val root = rootView ?: return false
        flutterEngine?.lifecycleChannel?.appIsResumed()

        val metrics = resources.displayMetrics
        val horizontalMargin = dpToPx(16)
        val width = max(dpToPx(300), minOf(dpToPx(390), metrics.widthPixels - (horizontalMargin * 2)))
        val height = dpToPx(172)
        val params = windowLayoutParams ?: WindowManager.LayoutParams(
            width,
            height,
            overlayWindowType(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
        }

        params.width = width
        params.height = height
        params.x = ((metrics.widthPixels - width) / 2).coerceAtLeast(horizontalMargin)
        params.y = dpToPx(72)
        windowLayoutParams = params

        if (!attachOrUpdateRootView(root, params)) {
            return false
        }
        overlayWindowChannel?.invokeMethod(
            "showGeneratedPreview",
            mapOf(
                "kind" to kind,
                "title" to cleanTitle,
                "body" to cleanBody,
            ),
        )

        reminderPreviewCollapseRunnable = Runnable { collapseToBubble() }.also {
            mainHandler.postDelayed(it, 5000L)
        }
        return true
    }

    private fun cancelReminderPreviewCollapse() {
        reminderPreviewCollapseRunnable?.let { mainHandler.removeCallbacks(it) }
        reminderPreviewCollapseRunnable = null
    }

    private fun attachOrUpdateRootView(root: FrameLayout, params: WindowManager.LayoutParams): Boolean {
        return runCatching {
            if (root.isAttachedToWindow) {
                windowManager.updateViewLayout(root, params)
            } else {
                windowManager.addView(root, params)
            }
            true
        }.getOrElse {
            windowLayoutParams = null
            false
        }
    }

    private fun updateOverlayLayout() {
        val root = rootView ?: return
        val params = windowLayoutParams ?: return
        if (root.isAttachedToWindow) {
            runCatching {
                windowManager.updateViewLayout(root, params)
            }.onFailure {
                windowLayoutParams = null
            }
        }
    }

    private fun clampBubblePosition(params: WindowManager.LayoutParams) {
        val metrics = resources.displayMetrics
        val margin = dpToPx(8)
        val maxX = (metrics.widthPixels - params.width - margin).coerceAtLeast(margin)
        val maxY = (metrics.heightPixels - params.height - dpToPx(120)).coerceAtLeast(margin)
        params.x = params.x.coerceIn(margin, maxX)
        params.y = params.y.coerceIn(margin, maxY)
    }

    private fun snapBubbleToEdge(params: WindowManager.LayoutParams) {
        val metrics = resources.displayMetrics
        val margin = dpToPx(8)
        val middle = metrics.widthPixels / 2
        params.x = if (params.x + (params.width / 2) < middle) {
            margin
        } else {
            (metrics.widthPixels - params.width - margin).coerceAtLeast(margin)
        }
        clampBubblePosition(params)
    }

    private fun persistBubblePosition(params: WindowManager.LayoutParams) {
        overlayPrefs().edit()
            .putInt(keyBubbleX, params.x)
            .putInt(keyBubbleY, params.y)
            .apply()
    }

    private fun showDismissTarget() {
        if (dismissView != null) {
            return
        }

        val size = dpToPx(96)
        val bottomMargin = dpToPx(32)
        val target = TextView(this).apply {
            text = "X"
            gravity = Gravity.CENTER
            textSize = 24f
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.argb(215, 205, 56, 69))
            alpha = 0.92f
        }

        val params = WindowManager.LayoutParams(
            size,
            size,
            overlayWindowType(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            y = bottomMargin
        }

        runCatching {
            windowManager.addView(target, params)
            dismissView = target
        }
    }

    private fun updateDismissTargetState(isOverTarget: Boolean) {
        (dismissView as? TextView)?.apply {
            scaleX = if (isOverTarget) 1.18f else 1f
            scaleY = if (isOverTarget) 1.18f else 1f
            alpha = if (isOverTarget) 1f else 0.92f
        }
    }

    private fun removeDismissTarget() {
        dismissView?.let { view ->
            runCatching {
                if (view.isAttachedToWindow) {
                    windowManager.removeView(view)
                }
            }
        }
        dismissView = null
    }

    private fun isOverDismissTarget(params: WindowManager.LayoutParams): Boolean {
        val targetBounds = dismissTargetBounds()
        val bubbleRect = Rect(
            params.x,
            params.y,
            params.x + params.width,
            params.y + params.height,
        )
        return Rect.intersects(targetBounds, bubbleRect)
    }

    private fun dismissTargetBounds(): Rect {
        val metrics = resources.displayMetrics
        val size = dpToPx(96)
        val bottomMargin = dpToPx(32)
        val left = (metrics.widthPixels - size) / 2
        val top = metrics.heightPixels - bottomMargin - size
        return Rect(left, top, left + size, top + size)
    }

    private fun buildNotification(): Notification {
        val launchIntent = (
            packageManager.getLaunchIntentForPackage(packageName)
                ?: Intent(this, MainActivity::class.java)
        ).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val contentIntent = PendingIntent.getActivity(
            this,
            4109,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val closeIntent = PendingIntent.getService(
            this,
            4110,
            Intent(this, OverlayAssistantService::class.java).setAction(OverlayAssistantManager.actionStop),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        return NotificationCompat.Builder(this, notificationChannelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Floating Assistant active")
            .setContentText("VitalySync can stay available above other apps.")
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setContentIntent(contentIntent)
            .addAction(R.mipmap.ic_launcher, "Close", closeIntent)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            notificationChannelId,
            "Floating Assistant",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Keeps the VitalySync assistant available outside the app."
        }
        manager.createNotificationChannel(channel)
    }

    private fun overlayWindowType(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
    }

    private fun overlayPrefs() =
        getSharedPreferences(nativePrefsName, Context.MODE_PRIVATE)

    private fun dpToPx(value: Int): Int =
        (value * resources.displayMetrics.density).toInt()
}
