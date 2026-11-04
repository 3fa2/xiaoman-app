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
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// local_auth 要求宿主为 FlutterFragmentActivity，否则抛 no_fragment_activity 致生物识别不可用。
class MainActivity : FlutterFragmentActivity() {

    private var pendingResult: MethodChannel.Result? = null
    private var pendingDirResult: MethodChannel.Result? = null

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
                    "updateSchedule" -> {
                        // v5.3：今日日程小组件推送
                        val json = call.argument<String>("schedule") ?: ""
                        val remaining = call.argument<Int>("remaining") ?: 0
                        val dateDay = call.argument<Int>("dateDay") ?: 0
                        WidgetChannelBridge.pushSchedule(applicationContext, json, remaining, dateDay)
                        result.success(null)
                    }
                    "updateMood" -> {
                        // v5.8：心情打卡小组件推送（-1 = 今天没有心情）
                        val moodId = call.argument<Int>("moodId") ?: -1
                        WidgetChannelBridge.pushTodayMood(applicationContext, moodId)
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
                    "drainPendingMoods" -> {
                        // v5.8：App 启动时同步待处理心情打卡（App 没运行时小组件的点击）
                        val ids = MoodWidgetStore.drainPendingMoodPicks(applicationContext)
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
                                repeatDaily = m["repeatDaily"] as? Boolean ?: false,
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

        // 备份导入通道：SAF 选 JSON 文件 + 读 content URI + v5.8 备份目录（写入/列出/清理）
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
                    "pickBackupFile" -> {
                        // v5.8.1：完整备份恢复选 zip——JSON MIME 过滤会让 zip 灰显选不中，
                        // 放宽到 */* 并给 MIME 白名单兜底
                        pendingResult = result
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "*/*"
                            putExtra(
                                Intent.EXTRA_MIME_TYPES,
                                arrayOf(
                                    "application/zip",
                                    "application/x-zip-compressed",
                                    "application/octet-stream",
                                    "application/json",
                                ),
                            )
                            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, false)
                        }
                        @Suppress("DEPRECATION")
                        startActivityForResult(intent, 1003)
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
                    "pickBackupDir" -> {
                        // v5.8：选自动备份目录（SAF tree），持久授权后 Dart 侧存 settings
                        pendingDirResult = result
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                            addFlags(
                                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
                            )
                        }
                        @Suppress("DEPRECATION")
                        startActivityForResult(intent, 1002)
                    }
                    "releaseTreePermission" -> {
                        // v5.8.1：换目录时释放旧持久授权（系统 128/512 上限，防累积）
                        val uriStr = call.argument<String>("uri")
                        if (uriStr.isNullOrBlank()) {
                            result.error("bad_args", "uri required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            contentResolver.releasePersistableUriPermission(
                                Uri.parse(uriStr),
                                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
                            )
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "writeToTree" -> {
                        val uriStr = call.argument<String>("uri")
                        val name = call.argument<String>("fileName")
                        val bytes = call.argument<ByteArray>("bytes")
                        if (uriStr == null || name == null || bytes == null) {
                            result.error("bad_args", "uri/fileName/bytes required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val tree = Uri.parse(uriStr)
                            val dirId = DocumentsContract.getTreeDocumentId(tree)
                            val dirUri = DocumentsContract.buildDocumentUriUsingTree(tree, dirId)
                            // 同名覆盖：先查后删（createDocument 同名会生成 (1) 后缀）
                            val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, dirId)
                            contentResolver.query(
                                children,
                                arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_DISPLAY_NAME),
                                null, null, null,
                            )?.use { c ->
                                while (c.moveToNext()) {
                                    if (c.getString(1) == name) {
                                        val docUri = DocumentsContract.buildDocumentUriUsingTree(tree, c.getString(0))
                                        DocumentsContract.deleteDocument(contentResolver, docUri)
                                    }
                                }
                            }
                            val newDoc = DocumentsContract.createDocument(
                                contentResolver, dirUri, "application/json", name,
                            ) ?: throw IllegalStateException("createDocument returned null")
                            contentResolver.openOutputStream(newDoc)?.use { it.write(bytes) }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("write_failed", e.message, null)
                        }
                    }
                    "listTree" -> {
                        // 返回 [fileName]，按名字升序（自动备份名内嵌时间戳，字典序=时间序）
                        val uriStr = call.argument<String>("uri")
                        if (uriStr == null) { result.error("no_uri", "missing uri", null); return@setMethodCallHandler }
                        try {
                            val tree = Uri.parse(uriStr)
                            val dirId = DocumentsContract.getTreeDocumentId(tree)
                            val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, dirId)
                            val names = mutableListOf<String>()
                            contentResolver.query(
                                children,
                                arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
                                null, null, null,
                            )?.use { c ->
                                while (c.moveToNext()) names.add(c.getString(0))
                            }
                            names.sort()
                            result.success(names)
                        } catch (e: Exception) {
                            result.error("list_failed", e.message, null)
                        }
                    }
                    "deleteFromTree" -> {
                        val uriStr = call.argument<String>("uri")
                        val name = call.argument<String>("fileName")
                        if (uriStr == null || name == null) {
                            result.error("bad_args", "uri/fileName required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val tree = Uri.parse(uriStr)
                            val dirId = DocumentsContract.getTreeDocumentId(tree)
                            val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, dirId)
                            var deleted = false
                            contentResolver.query(
                                children,
                                arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_DISPLAY_NAME),
                                null, null, null,
                            )?.use { c ->
                                while (c.moveToNext()) {
                                    if (c.getString(1) == name) {
                                        val docUri = DocumentsContract.buildDocumentUriUsingTree(tree, c.getString(0))
                                        deleted = DocumentsContract.deleteDocument(contentResolver, docUri)
                                    }
                                }
                            }
                            result.success(deleted)
                        } catch (e: Exception) {
                            result.error("delete_failed", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            // 1001=JSON 备份 / 1003=完整备份 zip：同为文件选择，结果处理一致
            1001, 1003 -> {
                val r = pendingResult
                pendingResult = null
                if (r == null) return
                if (resultCode == Activity.RESULT_OK && data?.data != null) {
                    r.success(data.data.toString())
                } else {
                    r.success(null)
                }
            }
            1002 -> {
                val r = pendingDirResult
                pendingDirResult = null
                if (r == null) return
                if (resultCode == Activity.RESULT_OK && data?.data != null) {
                    // 持久授权：重启后仍可写（读写都要）
                    try {
                        contentResolver.takePersistableUriPermission(
                            data.data!!,
                            Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
                        )
                    } catch (_: SecurityException) {
                        // 某些提供商不给持久授权：仍返回 uri，本次会话内可用
                    }
                    r.success(data.data.toString())
                } else {
                    r.success(null)
                }
            }
        }
    }
}
