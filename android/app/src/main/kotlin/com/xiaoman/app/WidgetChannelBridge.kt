package com.xiaoman.app

import android.content.Context

/// 小组件 → Flutter 的桥（v5.0.3）。
/// App 运行时直接 invoke channel 通知 Flutter toggle；
/// App 没运行时 AppWidgetProvider.onReceive 仍会被调用（系统拉起进程的 receiver），
/// 但 channel 不可用——toggle 先写入 SharedPreferences 待同步标记，
/// 等 App 启动时 drainPendingToggles 同步。
object WidgetChannelBridge {
    @Volatile var channel: io.flutter.plugin.common.MethodChannel? = null

    fun toggleTodo(id: Int) {
        channel?.invokeMethod("widgetToggle", id)
    }

    fun pushTodos(context: Context, todosJson: String, count: Int = -1) {
        // Flutter 侧推来的全量待办 JSON，解析后写入 SharedPreferences。
        // 推送 = App 内数据已是权威状态：此刻应清掉 pending 勾选队列，
        // 否则队列里的陈旧 id 会在下次启动把用户在 App 内的取消勾选改回去。
        try {
            val arr = org.json.JSONArray(todosJson)
            val list = (0 until arr.length()).map { i ->
                val o = arr.getJSONObject(i)
                TodoWidgetStore.Todo(
                    id = o.getInt("id"),
                    title = o.optString("title", ""),
                    done = o.optBoolean("done", false),
                )
            }
            TodoWidgetStore.setTodos(context, list, count)
            TodoWidgetStore.clearPendingToggles(context)
            TodoWidgetData.refreshAll(context)
        } catch (e: Exception) {
            // 解析失败不影响主流程
        }
    }
}
