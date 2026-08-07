package com.kawach.safety

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class BackgroundSosForegroundService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                } else {
                    @Suppress("DEPRECATION")
                    stopForeground(true)
                }
                stopSelf()
            }

            ACTION_START, ACTION_UPDATE, null -> {
                val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                val title = intent?.getStringExtra(EXTRA_TITLE)
                    ?: prefs.getString(KEY_TITLE, "KAWACH SOS active")
                    ?: "KAWACH SOS active"
                val body = intent?.getStringExtra(EXTRA_BODY)
                    ?: prefs.getString(KEY_BODY, "Emergency protection is running")
                    ?: "Emergency protection is running"

                createChannel()
                startForeground(NOTIFICATION_ID, buildNotification(title, body))
            }
        }

        return START_STICKY
    }

    private fun buildNotification(title: String, body: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .build()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Kawach Emergency Guard",
            NotificationManager.IMPORTANCE_HIGH
        )
        channel.description = "Pins active SOS protection in the foreground"
        manager.createNotificationChannel(channel)
    }

    companion object {
        const val ACTION_START = "kawach.action.START_SOS_SERVICE"
        const val ACTION_STOP = "kawach.action.STOP_SOS_SERVICE"
        const val ACTION_UPDATE = "kawach.action.UPDATE_SOS_NOTIFICATION"

        const val EXTRA_EMERGENCY_ID = "extra_emergency_id"
        const val EXTRA_TITLE = "extra_title"
        const val EXTRA_BODY = "extra_body"

        const val PREFS = "kawach_background_sos"
        const val KEY_EMERGENCY_ID = "emergency_id"
        const val KEY_TITLE = "title"
        const val KEY_BODY = "body"

        private const val CHANNEL_ID = "kawach_emergency_guard"
        private const val NOTIFICATION_ID = 4407

        fun persistState(
            context: Context,
            emergencyId: String,
            title: String,
            body: String,
        ) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putString(KEY_EMERGENCY_ID, emergencyId)
                .putString(KEY_TITLE, title)
                .putString(KEY_BODY, body)
                .apply()
        }

        fun clearState(context: Context) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .clear()
                .apply()
        }
    }
}
