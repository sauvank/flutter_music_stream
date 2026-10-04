package com.sauvank.musicstream

import android.media.MediaCodecList
import androidx.media3.decoder.ffmpeg.FfmpegLibrary
import androidx.mediarouter.app.SystemOutputSwitcherDialogController
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.install.model.UpdateAvailability
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Extends AudioServiceActivity so background playback keeps working, and
// exposes the channel the Dart side uses to refresh the home screen widget.
class MainActivity : AudioServiceActivity() {
    private var visualizer: AudioVisualizer? = null

    override fun onDestroy() {
        visualizer?.stop()
        visualizer = null
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // audio_service caches the engine beyond this activity, so the flag
        // only resets when the process dies.
        engineReady = true
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATE_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "check") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                // Play resolves track, rollout and account eligibility for this install.
                // An uploaded or pending-review build must not trigger an announcement.
                try {
                    AppUpdateManagerFactory.create(applicationContext).appUpdateInfo
                        .addOnSuccessListener { info ->
                            result.success(
                                if (info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE)
                                    info.availableVersionCode() else null
                            )
                        }
                        .addOnFailureListener { result.success(null) }
                } catch (_: Exception) {
                    // No Play Store, offline, or an unsupported installation.
                    result.success(null)
                }
            }
        PlayerWidgetProvider.refreshAll(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "pin") {
                    result.success(PlayerWidgetProvider.requestPin(this))
                    return@setMethodCallHandler
                }
                if (call.method != "update") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                PlayerWidgetProvider.saveState(
                    this,
                    title = call.argument<String>("title") ?: "",
                    artist = call.argument<String>("artist") ?: "",
                    artworkPath = call.argument<String>("artworkPath"),
                    playing = call.argument<Boolean>("playing") ?: false,
                )
                PlayerWidgetProvider.refreshAll(this)
                result.success(null)
            }
        visualizer?.stop()
        visualizer = AudioVisualizer(flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OUTPUT_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "showOutputSwitcher") {
                    // Falls back to Bluetooth settings where the system
                    // switcher is unavailable.
                    result.success(SystemOutputSwitcherDialogController.showDialog(this))
                } else if (call.method == "canDecode") {
                    result.success(canDecode(call.argument<String>("mime") ?: ""))
                } else {
                    result.notImplemented()
                }
            }
    }

    /** Whether the software extension or a platform decoder supports [mime]. */
    private fun canDecode(mime: String): Boolean =
        FfmpegLibrary.supportsFormat(mime) ||
        MediaCodecList(MediaCodecList.REGULAR_CODECS).codecInfos.any { info ->
            !info.isEncoder && info.supportedTypes.any { it.equals(mime, ignoreCase = true) }
        }

    companion object {
        private const val UPDATE_CHANNEL = "com.sauvank.musicstream/updates"
        private const val WIDGET_CHANNEL = "com.sauvank.musicstream/widget"
        private const val OUTPUT_CHANNEL = "com.sauvank.musicstream/output"

        /** Whether this process hosts the Flutter engine that plays audio. */
        @Volatile
        var engineReady = false
            private set
    }
}
