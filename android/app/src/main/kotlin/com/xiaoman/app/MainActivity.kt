package com.xiaoman.app

import android.app.Activity
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// local_auth 要求宿主为 FlutterFragmentActivity，否则抛 no_fragment_activity 致生物识别不可用。
class MainActivity : FlutterFragmentActivity() {

    private var pendingResult: MethodChannel.Result? = null

    companion object {
        /// 小组件 + 按钮带来的打开动作（冷启动时 engine 未就绪先存这里，
        /// Flutter 启动后通过 getLaunchAction 取走；热启动直接 invoke）
        @JvmStatic var launchAction: String? = null
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        readOpenAction(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        readOpenAction(intent)
    }

    private fun readOpenAction(intent: Intent?) {
        val a = intent?.getStringExtra(TodoWidgetData.EXTRA_OPEN_ACTION) ?: return
        launchAction = a
        // 热启动时 engine 在跑，直接推给 Flutter
        widgetChannel?.invokeMethod("openAction", a)
    }

    private var widgetChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 小组件通道（v5.0→v5.0.3）：数据推送/刷新 + 启动动作分发 + 勾选回调。
        // 独立于 trinity/alarms（红线：闹钟通道不动）。
        widgetChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, "trinity/widget",
        ).also { ch ->
            WidgetChannelBridge.channel = ch
            ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    "refresh" -> {
                        TodoWidgetData.refreshAll(applicationContext)
                        result.success(null)
                    }
                    "updateTodos" -> {
                        // Flutter 侧推送全量待办 JSON + 真实未完成总数
                        val json = call.argument<String>("todos") ?: ""
                        val count = call.argument<Int>("count") ?: -1
                        WidgetChannelBridge.pushTodos(applicationContext, json, count)
                        result.success(null)
                    }
                    "getLaunchAction" -> {
                        val a = launchAction
                        launchAction = null
                        result.success(a)
                    }
                    "drainPending" -> {
                        // App 启动时同步待处理勾选（App 没运行时小组件标记的 toggle）
                        val ids = TodoWidgetStore.drainPendingToggles(applicationContext)
                        result.success(ids)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        // 闹钟通道
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
                                channel = m["channel"] as? String ?: "trinity_schedule",
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

        // 备份导入通道：SAF 选 JSON 文件 + 读 content URI
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "trinity/backup")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickJsonFile" -> {
                        pendingResult = result
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "application/json"
                            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, false)
                        }
                        @Suppress("DEPRECATION")
                        startActivityForResult(intent, 1001)
                    }
                    "readFile" -> {
                        val uriStr = call.argument<String>("uri")
                        if (uriStr == null) { result.error("no_uri", "missing uri", null); return@setMethodCallHandler }
                        try {
                            val uri = Uri.parse(uriStr)
                            val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
                            if (bytes != null) result.success(bytes) else result.error("read_failed", "null", null)
                        } catch (e: Exception) {
                            result.error("read_failed", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 1001) {
            val r = pendingResult
            pendingResult = null
            if (r == null) return
            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                r.success(data.data.toString())
            } else {
                r.success(null)
            }
        }
    }
}
