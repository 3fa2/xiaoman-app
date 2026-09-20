package com.xiaoman.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
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
                        // 先取消旧持久列表里的全部闹钟（filterEquals 不比较 extras，
                        // 同 requestCode 即可 cancel），防止已删除日程的提醒照响（幽灵通知）
                        val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        for (e in AlarmPersistence.getAll(applicationContext)) {
                            val i = Intent(applicationContext, AlarmReceiver::class.java)
                            val pi = PendingIntent.getBroadcast(
                                applicationContext, e.id, i,
                                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                            )
                            am.cancel(pi)
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
