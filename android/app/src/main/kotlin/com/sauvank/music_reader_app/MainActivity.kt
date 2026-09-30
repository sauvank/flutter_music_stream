package com.sauvank.musicstream

import androidx.mediarouter.app.SystemOutputSwitcherDialogController
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Extends AudioServiceActivity so background playback keeps working, and
// exposes the channel the Dart side uses to refresh the home screen widget.
class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // audio_service caches the engine beyond this activity, so the flag
        // only resets when the process dies.
        engineReady = true
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OUTPUT_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "showOutputSwitcher") {
                    // Falls back to Bluetooth settings where the system
                    // switcher is unavailable.
                    result.success(SystemOutputSwitcherDialogController.showDialog(this))
                } else {
                    result.notImplemented()
                }
            }
    }

    companion object {
        private const val WIDGET_CHANNEL = "com.sauvank.musicstream/widget"
        private const val OUTPUT_CHANNEL = "com.sauvank.musicstream/output"

        /** Whether this process hosts the Flutter engine that plays audio. */
        @Volatile
        var engineReady = false
            private set
    }
}
