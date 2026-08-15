package com.teamkawach.kawach

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

/**
 * MainApplication – WorkManager + foreground service initialisation.
 *
 * Configures notification channels required for the foreground safety
 * monitoring service and periodic sync via WorkManager.
 */
class MainApplication : Application() {

    companion object {
        const val CHANNEL_ID_FOREGROUND = "kawach_foreground_service"
        const val CHANNEL_ID_ALERTS = "kawach_alerts"
        const val CHANNEL_ID_SOS = "kawach_sos"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)

            // Foreground service channel (silent, persistent)
            val foregroundChannel = NotificationChannel(
                CHANNEL_ID_FOREGROUND,
                "Safety Monitoring",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Background safety monitoring service"
                setShowBadge(false)
            }

            // Alert notifications
            val alertChannel = NotificationChannel(
                CHANNEL_ID_ALERTS,
                "Safety Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Danger zone and risk alerts"
                enableVibration(true)
            }

            // SOS emergency channel (highest priority)
            val sosChannel = NotificationChannel(
                CHANNEL_ID_SOS,
                "SOS Emergency",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Emergency SOS notifications"
                enableVibration(true)
                enableLights(true)
            }

            manager.createNotificationChannels(
                listOf(foregroundChannel, alertChannel, sosChannel)
            )
        }
    }
}
