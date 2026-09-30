package com.sauvank.musicstream

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.view.KeyEvent
import android.view.View
import android.widget.RemoteViews
import com.ryanheise.audioservice.MediaButtonReceiver
import java.io.File

/**
 * Home screen widget showing the current track. While the Flutter engine
 * runs, buttons forward media button events to audio_service's receiver,
 * like headset controls. Without it nothing could play, so they open the app.
 */
class PlayerWidgetProvider : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_MEDIA_KEY) {
            super.onReceive(context, intent)
            return
        }
        if (MainActivity.engineReady) {
            val keyCode = intent.getIntExtra(EXTRA_KEY_CODE, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
            context.sendBroadcast(
                Intent(Intent.ACTION_MEDIA_BUTTON)
                    .setComponent(ComponentName(context, MediaButtonReceiver::class.java))
                    .putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, keyCode)),
            )
        } else {
            // The process restarted without the app: buttons now open it.
            refreshAll(context)
            try {
                context.startActivity(launchIntent(context))
            } catch (error: RuntimeException) {
                // Background launch refused: the refreshed buttons open the app.
            }
        }
    }

    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        widgetIds: IntArray,
    ) {
        val views = buildViews(context)
        widgetIds.forEach { manager.updateAppWidget(it, views) }
    }

    companion object {
        private const val PREFERENCES = "musicstream_widget"
        private const val ACTION_MEDIA_KEY = "com.sauvank.musicstream.widget.MEDIA_KEY"
        private const val EXTRA_KEY_CODE = "keyCode"
        private const val ARTWORK_SIZE = 192

        fun saveState(
            context: Context,
            title: String,
            artist: String,
            artworkPath: String?,
            playing: Boolean,
        ) {
            context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit()
                .putString("title", title)
                .putString("artist", artist)
                .putString("artworkPath", artworkPath)
                .putBoolean("playing", playing)
                .apply()
        }

        /** Asks the launcher to add the widget; false if unsupported. */
        fun requestPin(context: Context): Boolean {
            val manager = AppWidgetManager.getInstance(context)
            if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.O ||
                !manager.isRequestPinAppWidgetSupported
            ) {
                return false
            }
            return manager.requestPinAppWidget(
                ComponentName(context, PlayerWidgetProvider::class.java),
                null,
                null,
            )
        }

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, PlayerWidgetProvider::class.java),
            )
            if (ids.isEmpty()) return
            val views = buildViews(context)
            ids.forEach { manager.updateAppWidget(it, views) }
        }

        private fun buildViews(context: Context): RemoteViews {
            val state = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.widget_player)
            views.setTextViewText(
                R.id.widget_title,
                state.getString("title", null)
                    ?: context.getString(R.string.widget_idle),
            )
            views.setTextViewText(R.id.widget_artist, state.getString("artist", ""))
            val artwork = state.getString("artworkPath", null)?.let(::decodeArtwork)
            if (artwork != null) {
                views.setImageViewBitmap(R.id.widget_artwork, artwork)
            } else {
                views.setImageViewResource(R.id.widget_artwork, R.drawable.ic_widget_music)
            }
            val playing = state.getBoolean("playing", false)
            views.setViewVisibility(R.id.widget_bars, if (playing) View.VISIBLE else View.GONE)
            views.setImageViewResource(
                R.id.widget_play_pause,
                if (playing) R.drawable.ic_widget_pause else R.drawable.ic_widget_play,
            )
            views.setContentDescription(
                R.id.widget_play_pause,
                context.getString(if (playing) R.string.widget_pause else R.string.widget_play),
            )
            views.setOnClickPendingIntent(
                R.id.widget_previous,
                mediaButton(context, KeyEvent.KEYCODE_MEDIA_PREVIOUS),
            )
            views.setOnClickPendingIntent(
                R.id.widget_play_pause,
                mediaButton(context, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE),
            )
            views.setOnClickPendingIntent(
                R.id.widget_next,
                mediaButton(context, KeyEvent.KEYCODE_MEDIA_NEXT),
            )
            views.setOnClickPendingIntent(R.id.widget_root, openApp(context))
            return views
        }

        private fun mediaButton(context: Context, keyCode: Int): PendingIntent {
            if (!MainActivity.engineReady) return openApp(context)
            val intent = Intent(context, PlayerWidgetProvider::class.java)
                .setAction(ACTION_MEDIA_KEY)
                .putExtra(EXTRA_KEY_CODE, keyCode)
            return PendingIntent.getBroadcast(
                context,
                keyCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun launchIntent(context: Context): Intent =
            (context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, MainActivity::class.java))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)

        private fun openApp(context: Context): PendingIntent {
            return PendingIntent.getActivity(
                context,
                0,
                launchIntent(context),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        /** Decodes the cover at widget size; remote views cap bitmap memory. */
        private fun decodeArtwork(path: String): Bitmap? {
            val file = File(path)
            if (!file.isFile) return null
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            var sample = 1
            while (bounds.outWidth / (sample * 2) >= ARTWORK_SIZE &&
                bounds.outHeight / (sample * 2) >= ARTWORK_SIZE
            ) {
                sample *= 2
            }
            return BitmapFactory.decodeFile(
                path,
                BitmapFactory.Options().apply { inSampleSize = sample },
            )
        }
    }
}
