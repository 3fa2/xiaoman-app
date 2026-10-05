package com.xiaoman.app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/// 待办小组件数据缓存（v5.0.3）：从 SharedPreferences 读取待办列表。
///
/// 不再直读 SQLite——drift_flutter 用 sqlite3 (dart:ffi) 写库 + WAL 模式，
/// 小组件用 Android SQLiteDatabase 打开主库时可能读不到 WAL 中的最新数据。
/// 改为 Flutter 侧数据变化时通过 MethodChannel 推送 JSON 到此处缓存。
///
/// 勾选操作：先在缓存中标记 done，再通过 channel 通知 Flutter 侧执行真正的 toggle。
/// App 没运行时：AppWidgetProvider.onReceive 仍会被调用（系统会拉起进程），
/// 但 channel 不可用——此时标记在缓存中，等 App 下次启动时 drainPendingToggles 同步。
object TodoWidgetStore {
    private const val PREFS = "trinity_widget"
    private const val KEY_TODOS = "todos_json"
    private const val KEY_PENDING_TOGGLE = "pending_toggle_ids"
    // 真实未完成总数（列表截断 8 条，数字不能跟着截断；-1 = 未知，按列表现算）
    private const val KEY_OPEN_COUNT = "open_count"

    data class Todo(val id: Int, val title: String, val done: Boolean)

    private fun prefs(ctx: Context) =
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /// Flutter 侧推送：全量替换待办列表（仅未完成的，最多 8 条）+ 真实未完成总数
    fun setTodos(ctx: Context, todos: List<Todo>, count: Int = -1) {
        val arr = JSONArray()
        for (t in todos.take(8)) {
            arr.put(
                JSONObject()
                    .put("id", t.id)
                    .put("title", t.title)
                    .put("done", t.done),
            )
        }
        prefs(ctx).edit()
            .putString(KEY_TODOS, arr.toString())
            .putInt(KEY_OPEN_COUNT, if (count >= 0) count else todos.size)
            .apply()
    }

    /// 读取缓存的待办列表（小组件渲染用）
    fun getTodos(ctx: Context): List<Todo> {
        val s = prefs(ctx).getString(KEY_TODOS, null) ?: return emptyList()
        return try {
            val arr = JSONArray(s)
            (0 until arr.length()).map { i ->
                val o = arr.getJSONObject(i)
                Todo(
                    id = o.getInt("id"),
                    title = o.optString("title", ""),
                    done = o.optBoolean("done", false),
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    /// 未完成数量：优先用 Flutter 推送的真实总数，旧缓存退回按列表现算
    fun openCount(ctx: Context): Int {
        val stored = prefs(ctx).getInt(KEY_OPEN_COUNT, -1)
        if (stored >= 0) return stored
        return getTodos(ctx).count { !it.done }
    }

    /// 未完成列表（小组件渲染用）
    fun openTodos(ctx: Context, limit: Int): List<Todo> =
        getTodos(ctx).filter { !it.done }.take(limit)

    /// 勾选切换：在缓存中翻转 done 状态（即时反馈），并记录待同步 id
    fun toggle(ctx: Context, id: Int) {
        val list = getTodos(ctx)
        var delta = 0
        val flipped = list.map { t ->
            if (t.id == id) {
                // 翻转会改变未完成数：done→未完成 +1，未完成→done -1
                delta = if (t.done) 1 else -1
                t.copy(done = !t.done)
            } else t
        }
        val arr = JSONArray()
        for (t in flipped) {
            arr.put(
                JSONObject()
                    .put("id", t.id)
                    .put("title", t.title)
                    .put("done", t.done),
            )
        }
        // 记录待同步 id
        val pending = prefs(ctx).getStringSet(KEY_PENDING_TOGGLE, emptySet()) ?: emptySet()
        val prevCount = prefs(ctx).getInt(KEY_OPEN_COUNT, -1)
        val editor = prefs(ctx).edit()
            .putString(KEY_TODOS, arr.toString())
            .putStringSet(KEY_PENDING_TOGGLE, pending + id.toString())
        if (prevCount >= 0) {
            editor.putInt(KEY_OPEN_COUNT, (prevCount + delta).coerceAtLeast(0))
        }
        editor.apply()
    }

    /// 清空待同步队列（Flutter 推送权威数据时调用：队列里的陈旧 id 不应再生效）
    fun clearPendingToggles(ctx: Context) {
        prefs(ctx).edit().remove(KEY_PENDING_TOGGLE).apply()
    }

    /// App 启动时调用：返回需要 toggle 的 id 列表，并清空待同步标记
    fun drainPendingToggles(ctx: Context): List<Int> {
        val pending = prefs(ctx).getStringSet(KEY_PENDING_TOGGLE, emptySet()) ?: emptySet()
        if (pending.isEmpty()) return emptyList()
        prefs(ctx).edit().remove(KEY_PENDING_TOGGLE).apply()
        return pending.mapNotNull { it.toIntOrNull() }
    }
}
