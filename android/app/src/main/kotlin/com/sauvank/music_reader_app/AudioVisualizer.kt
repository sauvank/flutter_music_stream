package com.sauvank.musicstream

import android.media.audiofx.Visualizer
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlin.math.hypot
import kotlin.math.log10
import kotlin.math.pow

/**
 * Streams the spectrum of the app's own audio session as [BAND_COUNT]
 * levels between 0 and 1. Needs RECORD_AUDIO, as every Android visualizer.
 */
class AudioVisualizer(messenger: BinaryMessenger) {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var visualizer: Visualizer? = null
    private var sink: EventChannel.EventSink? = null

    init {
        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> result.success(start(call.argument<Int>("sessionId") ?: 0))
                "stop" -> {
                    stop()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                sink = events
            }

            override fun onCancel(arguments: Any?) {
                sink = null
            }
        })
    }

    private fun start(sessionId: Int): Boolean {
        stop()
        // Session 0 would capture the whole output mix, never wanted here.
        if (sessionId <= 0) return false
        return try {
            val created = Visualizer(sessionId).apply {
                captureSize = CAPTURE_SIZE.coerceIn(
                    Visualizer.getCaptureSizeRange()[0],
                    Visualizer.getCaptureSizeRange()[1],
                )
                scalingMode = Visualizer.SCALING_MODE_NORMALIZED
                setDataCaptureListener(
                    object : Visualizer.OnDataCaptureListener {
                        override fun onWaveFormDataCapture(v: Visualizer, data: ByteArray, rate: Int) = Unit

                        override fun onFftDataCapture(v: Visualizer, fft: ByteArray, rate: Int) {
                            val levels = bands(fft)
                            mainHandler.post { sink?.success(levels) }
                        }
                    },
                    Visualizer.getMaxCaptureRate().coerceAtMost(CAPTURE_RATE_MILLIHERTZ),
                    false,
                    true,
                )
                enabled = true
            }
            visualizer = created
            true
        } catch (error: RuntimeException) {
            // Missing permission or a session the effect cannot attach to.
            false
        }
    }

    fun stop() {
        visualizer?.run {
            enabled = false
            release()
        }
        visualizer = null
    }

    /** Groups FFT bins into logarithmic bands, mapped from dB to 0..1. */
    private fun bands(fft: ByteArray): DoubleArray {
        val bins = fft.size / 2
        val levels = DoubleArray(BAND_COUNT)
        for (band in 0 until BAND_COUNT) {
            val start = (bins.toDouble().pow(band.toDouble() / BAND_COUNT)).toInt().coerceAtLeast(1)
            val end = (bins.toDouble().pow((band + 1).toDouble() / BAND_COUNT)).toInt()
                .coerceIn(start + 1, bins)
            var peak = 0.0
            for (bin in start until end) {
                val magnitude = hypot(fft[2 * bin].toDouble(), fft[2 * bin + 1].toDouble())
                if (magnitude > peak) peak = magnitude
            }
            // Music loses energy with frequency; the tilt keeps highs visible.
            val tilt = TILT_DECIBELS * band / (BAND_COUNT - 1)
            val decibels = if (peak > 0) 20 * log10(peak / 128.0) + tilt else MIN_DECIBELS
            levels[band] = ((decibels - MIN_DECIBELS) / (MAX_DECIBELS - MIN_DECIBELS))
                .coerceIn(0.0, 1.0)
        }
        return levels
    }

    companion object {
        private const val METHOD_CHANNEL = "com.sauvank.musicstream/visualizer"
        private const val EVENT_CHANNEL = "com.sauvank.musicstream/visualizer/levels"
        private const val BAND_COUNT = 24
        private const val CAPTURE_SIZE = 1024
        private const val CAPTURE_RATE_MILLIHERTZ = 20000
        private const val MIN_DECIBELS = -50.0
        private const val MAX_DECIBELS = -4.0
        private const val TILT_DECIBELS = 12.0
    }
}
