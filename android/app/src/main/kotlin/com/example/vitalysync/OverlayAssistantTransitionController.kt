package com.example.vitalysync

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.view.View
import android.view.animation.DecelerateInterpolator
import android.widget.FrameLayout
import io.flutter.embedding.android.FlutterView
import io.flutter.plugin.common.MethodChannel

internal class OverlayAssistantTransitionController(
    private val context: Context,
    private val rootView: FrameLayout,
    private val flutterView: FlutterView,
    private val mainHandler: Handler,
) {
    enum class Target(
        val isBubble: Boolean,
        val horizontalInsetDp: Int,
        val cornerRadiusDp: Int,
    ) {
        BUBBLE(isBubble = true, horizontalInsetDp = 0, cornerRadiusDp = 29),
        PANEL(isBubble = false, horizontalInsetDp = 8, cornerRadiusDp = 28),
        PREVIEW(isBubble = false, horizontalInsetDp = 10, cornerRadiusDp = 20),
    }

    companion object {
        private const val flutterPrefsName = "FlutterSharedPreferences"
        private const val flutterThemeModeKey = "flutter.app_theme_mode"
        private const val transitionDurationMillis = 180L
        private const val fallbackMillis = 900L
    }

    private var transitionView: View? = null
    private var fallbackRunnable: Runnable? = null
    private var generation = 0

    fun begin(target: Target): MethodChannel.Result {
        generation += 1
        clear(revealFlutter = false)

        val transitionGeneration = generation
        // A TextureView stretches its last frame while its window is resized.
        // Hide that stale bubble frame until Dart paints the target layout.
        flutterView.apply {
            animate().cancel()
            alpha = 0f
        }

        val transition = View(context).apply {
            isClickable = false
            isFocusable = false
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
            background = GradientDrawable().apply {
                shape = if (target.isBubble) {
                    GradientDrawable.OVAL
                } else {
                    GradientDrawable.RECTANGLE
                }
                cornerRadius = dpToPx(target.cornerRadiusDp).toFloat()
                setColor(transitionColor())
            }
        }
        rootView.addView(
            transition,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            ).apply {
                val horizontalInset = dpToPx(target.horizontalInsetDp)
                setMargins(horizontalInset, 0, horizontalInset, 0)
            },
        )
        transitionView = transition
        fallbackRunnable = Runnable {
            finish(transitionGeneration)
        }.also {
            mainHandler.postDelayed(it, fallbackMillis)
        }

        return object : MethodChannel.Result {
            override fun success(result: Any?) {
                mainHandler.post { finish(transitionGeneration) }
            }

            override fun error(
                errorCode: String,
                errorMessage: String?,
                errorDetails: Any?,
            ) {
                mainHandler.post { finish(transitionGeneration) }
            }

            override fun notImplemented() {
                mainHandler.post { finish(transitionGeneration) }
            }
        }
    }

    fun cancel() {
        generation += 1
        clear(revealFlutter = true)
    }

    private fun finish(transitionGeneration: Int) {
        if (transitionGeneration != generation) {
            return
        }

        fallbackRunnable?.let { mainHandler.removeCallbacks(it) }
        fallbackRunnable = null
        val transition = transitionView ?: return clear(revealFlutter = true)

        flutterView.animate()
            .alpha(1f)
            .setDuration(transitionDurationMillis)
            .setInterpolator(DecelerateInterpolator())
            .start()
        transition.animate()
            .alpha(0f)
            .setDuration(transitionDurationMillis)
            .setInterpolator(DecelerateInterpolator())
            .withEndAction {
                if (transitionGeneration == generation && transitionView === transition) {
                    rootView.removeView(transition)
                    transitionView = null
                }
            }
            .start()
    }

    private fun clear(revealFlutter: Boolean) {
        fallbackRunnable?.let { mainHandler.removeCallbacks(it) }
        fallbackRunnable = null
        transitionView?.let { transition ->
            transition.animate().cancel()
            rootView.removeView(transition)
        }
        transitionView = null
        flutterView.animate().cancel()
        if (revealFlutter) {
            flutterView.alpha = 1f
        }
    }

    private fun transitionColor(): Int {
        val flutterPrefs = context.getSharedPreferences(
            flutterPrefsName,
            Context.MODE_PRIVATE,
        )
        val themeMode = flutterPrefs.getString(flutterThemeModeKey, "light")
        val systemUsesDarkTheme =
            context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK ==
                Configuration.UI_MODE_NIGHT_YES
        val useDarkTheme = themeMode == "dark" ||
            (themeMode == "system" && systemUsesDarkTheme)
        return if (useDarkTheme) {
            Color.argb(235, 15, 27, 45)
        } else {
            Color.argb(235, 246, 251, 249)
        }
    }

    private fun dpToPx(value: Int): Int =
        (value * context.resources.displayMetrics.density).toInt()
}
