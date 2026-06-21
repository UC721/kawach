package com.kawach.safety

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val prefs = context.getSharedPreferences(
            BackgroundSosForegroundService.PREFS,
            Context.MODE_PRIVATE,
        )
        val emergencyId = prefs.getString(
            BackgroundSosForegroundService.KEY_EMERGENCY_ID,
            null,
        ) ?: return

        val serviceIntent = Intent(context, BackgroundSosForegroundService::class.java).apply {
            action = BackgroundSosForegroundService.ACTION_START
            putExtra(BackgroundSosForegroundService.EXTRA_EMERGENCY_ID, emergencyId)
            putExtra(
                BackgroundSosForegroundService.EXTRA_TITLE,
                prefs.getString(
                    BackgroundSosForegroundService.KEY_TITLE,
                    "KAWACH SOS active",
                ),
            )
            putExtra(
                BackgroundSosForegroundService.EXTRA_BODY,
                prefs.getString(
                    BackgroundSosForegroundService.KEY_BODY,
                    "Emergency protection is running",
                ),
            )
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}
