package com.trinity.app

import android.app.AlarmManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// local_auth 要求宿主为 FlutterFragmentActivity，否则抛 no_fragment_activity 致生物识别不可用。
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "trinity/alarms")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setAll" -> {
                        val list = call.argument<List<Map<*, *>>>("alarms") ?: emptyList()
                        val entries = list.mapNotNull { m ->
                            val id = (m["id"] as? Number)?.toInt() ?: return@mapNotNull null
                            AlarmEntry(
                                id = id,
                                title = m["title"] as? String ?: "",
                                body = m["body"] as? String ?: "",
                                epochMs = (m["epochMs"] as? Number)?.toLong() ?: return@mapNotNull null,
                                payload = m["payload"] as? String,
                            )
                        }
                        AlarmPersistence.setAll(applicationContext, entries)
                        BootReceiver().rescheduleAll(applicationContext)
                        result.success(null)
                    }
                    "canExact" -> {
                        val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        result.success(if (Build.VERSION.SDK_INT >= 31) am.canScheduleExactAlarms() else true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
