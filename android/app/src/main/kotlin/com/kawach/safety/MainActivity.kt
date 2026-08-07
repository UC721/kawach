package com.kawach.safety

import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "kawach/background_sos"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val emergencyId = call.argument<String>("emergencyId").orEmpty()
                    val title = call.argument<String>("title").orEmpty()
                    val body = call.argument<String>("body").orEmpty()
                    BackgroundSosForegroundService.persistState(
                        context = this,
                        emergencyId = emergencyId,
                        title = title,
                        body = body,
                    )
                    val intent = Intent(this, BackgroundSosForegroundService::class.java).apply {
                        action = BackgroundSosForegroundService.ACTION_START
                        putExtra(BackgroundSosForegroundService.EXTRA_EMERGENCY_ID, emergencyId)
                        putExtra(BackgroundSosForegroundService.EXTRA_TITLE, title)
                        putExtra(BackgroundSosForegroundService.EXTRA_BODY, body)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }

                "stop" -> {
                    val intent = Intent(this, BackgroundSosForegroundService::class.java).apply {
                        action = BackgroundSosForegroundService.ACTION_STOP
                    }
                    startService(intent)
                    BackgroundSosForegroundService.clearState(this)
                    result.success(null)
                }

                "updateNotification" -> {
                    BackgroundSosForegroundService.persistState(
                        context = this,
                        emergencyId = getSharedPreferences(
                            BackgroundSosForegroundService.PREFS,
                            Context.MODE_PRIVATE
                        ).getString(BackgroundSosForegroundService.KEY_EMERGENCY_ID, "") ?: "",
                        title = call.argument<String>("title").orEmpty(),
                        body = call.argument<String>("body").orEmpty(),
                    )
                    val intent = Intent(this, BackgroundSosForegroundService::class.java).apply {
                        action = BackgroundSosForegroundService.ACTION_UPDATE
                        putExtra(
                            BackgroundSosForegroundService.EXTRA_TITLE,
                            call.argument<String>("title").orEmpty(),
                        )
                        putExtra(
                            BackgroundSosForegroundService.EXTRA_BODY,
                            call.argument<String>("body").orEmpty(),
                        )
                    }
                    startService(intent)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "kawach/mesh"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startRelay" -> {
                    getSharedPreferences("kawach_mesh", Context.MODE_PRIVATE)
                        .edit()
                        .putString("last_packet", call.argument<String>("packet"))
                        .apply()
                    result.success(true)
                }

                "stopRelay" -> {
                    getSharedPreferences("kawach_mesh", Context.MODE_PRIVATE)
                        .edit()
                        .remove("last_packet")
                        .apply()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }
}
