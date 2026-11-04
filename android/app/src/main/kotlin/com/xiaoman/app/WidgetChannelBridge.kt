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
                    // v5.8：截止日 yyyymmdd，0 / null / 缺键都视为无期限
                    dueDay = o.optLong("dueDay", 0L).takeIf { it > 0 }?.toInt(),
                )
            }
            TodoWidgetStore.setTodos(context, list, count)
            TodoWidgetStore.clearPendingToggles(context)
            TodoWidgetData.refreshAll(context)
        } catch (e: Exception) {
            // 解析失败不影响主流程
        }
    }

    /** v5.3：今日日程小组件推送（[{time,title,done},...] + 剩余数 + 日期） */
    fun pushSchedule(context: Context, json: String, remaining: Int, dateDay: Int) {
        try {
            val arr = org.json.JSONArray(json)
            val list = (0 until arr.length()).map { i ->
                val o = arr.getJSONObject(i)
                ScheduleWidgetStore.Block(
                    time = o.optString("time", ""),
                    title = o.optString("title", ""),
                    done = o.optBoolean("done", false),
                )
            }
            ScheduleWidgetStore.setSchedule(context, list, remaining, dateDay)
            TodoWidgetData.refreshScheduleWidgets(context)
        } catch (e: Exception) {
            // 解析失败不影响主流程
        }
    }

    /** v5.8：心情打卡小组件推送——Flutter 侧的权威心情写入缓存并刷新（-1 = 今天没有心情） */
    fun pushTodayMood(context: Context, moodId: Int) {
        try {
            MoodWidgetStore.setTodayMood(context, moodId)
            // 推送 = App 内数据已是权威状态：清掉 pending 打卡队列，
            // 否则队列里的陈旧心情会在下次启动把用户在 App 内的改选覆盖回去
            MoodWidgetStore.clearPendingMoodPicks(context)
            TodoWidgetData.refreshMoodWidgets(context)
        } catch (e: Exception) {
            // 失败不影响主流程
        }
    }

    /** v5.8：小组件打卡 → 通知 Flutter 执行真正的落库（App 没运行时 channel 为 null，走 pending 队列） */
    fun moodPick(moodId: Int) {
        channel?.invokeMethod("moodPick", moodId)
    }
}
