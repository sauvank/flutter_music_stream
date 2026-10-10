package com.sauvank.musicstream

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat

// Holds the process in the foreground for a whole download batch.
// WorkManager stops its own foreground service whenever no worker is running
// (between files, during retry backoff); Android then refuses to restart it
// from the background and cuts the process's network, so every remaining task
// fails with DNS errors. This service is started while the app is visible and
// spans those gaps.
class DownloadKeepAliveService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: ""
        try {
            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                notification(this, title),
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC else 0,
            )
        } catch (e: Exception) {
            Log.w(TAG, "Unable to hold downloads in the foreground: ${e.message}")
            stopSelf()
        }
        // Without the Dart queue to release it, a restarted service would
        // keep a stale notification forever.
        return START_NOT_STICKY
    }

    // Android 15+ caps dataSync at six hours per day.
    override fun onTimeout(startId: Int, fgsType: Int) {
        stopSelf()
    }

    override fun onDestroy() {
        // The downloader keeps updating this notification, so detach it
        // rather than removing its final "complete" or "error" state.
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_DETACH)
        super.onDestroy()
    }

    companion object {
        private const val TAG = "DownloadKeepAlive"
        private const val EXTRA_TITLE = "title"

        // Same channel and id as background_downloader's group notification
        // for the "musicstream_audio" group, so a single notification shows
        // the progress the downloader writes into it.
        private const val CHANNEL_ID = "background_downloader"
        private val NOTIFICATION_ID = "groupNotificationmusicstream_audio".hashCode()

        /** Returns false when Android refuses a foreground start (app in background). */
        fun start(context: Context, title: String): Boolean = try {
            ContextCompat.startForegroundService(
                context,
                Intent(context, DownloadKeepAliveService::class.java)
                    .putExtra(EXTRA_TITLE, title),
            )
            true
        } catch (e: Exception) {
            Log.w(TAG, "Unable to start download keep-alive: ${e.message}")
            false
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, DownloadKeepAliveService::class.java))
        }

        private fun notification(context: Context, title: String): Notification {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val manager = context.getSystemService(NotificationManager::class.java)
                if (manager.getNotificationChannel(CHANNEL_ID) == null) {
                    manager.createNotificationChannel(
                        NotificationChannel(CHANNEL_ID, title, NotificationManager.IMPORTANCE_LOW)
                    )
                }
            }
            return NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_stat_musicstream)
                .setContentTitle(title)
                .setProgress(0, 0, true)
                .setOngoing(true)
                .setSilent(true)
                .build()
        }
    }
}
