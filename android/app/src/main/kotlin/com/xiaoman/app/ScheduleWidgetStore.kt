package com.xiaoman.app

import android.content.Context
import org.json.JSONArray

/// 今日日程小组件缓存（v5.3）：Flutter 侧通过 trinity/widget 推送，
/// 结构与 TodoWidgetStore 同一套（SharedPreferences，绕开 SQLite/WAL）。
object ScheduleWidgetStore {
    private const val PREFS = "trinity_schedule_widget"
    private const val KEY_ITEMS = "schedule_json"
    private const val KEY_REMAINING = "schedule_remaining"
    private const val KEY_DATE = "schedule_date"

    data class Block(val time: String, val title: String, val done: Boolean)

    private fun prefs(ctx: Context) =
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun setSchedule(ctx: Context, items: List<Block>, remaining: Int, dateDay: Int) {
        val arr = JSONArray()
        for (b in items.take(4)) {
            arr.put(
                JSONArray()
                    .put(b.time)
                    .put(b.title)
                    .put(b.done),
            )
        }
        prefs(ctx).edit()
            .putString(KEY_ITEMS, arr.toString())
            .putInt(KEY_REMAINING, remaining)
            .putInt(KEY_DATE, dateDay)
            .apply()
    }

    fun blocks(ctx: Context, limit: Int): List<Block> {
        val s = prefs(ctx).getString(KEY_ITEMS, null) ?: return emptyList()
        return try {
            val arr = JSONArray(s)
            (0 until arr.length()).take(limit).map { i ->
                val o = arr.getJSONArray(i)
                Block(
                    time = o.optString(0, ""),
                    title = o.optString(1, ""),
                    done = o.optBoolean(2, false),
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun remaining(ctx: Context): Int = prefs(ctx).getInt(KEY_REMAINING, 0)

    /** 缓存对应哪天：跨天后的兜底刷新不显示昨天的日程 */
    fun isToday(ctx: Context): Boolean {
        val n = java.util.Calendar.getInstance()
        val today = n.get(java.util.Calendar.YEAR) * 10000 +
            (n.get(java.util.Calendar.MONTH) + 1) * 100 + n.get(java.util.Calendar.DAY_OF_MONTH)
        return prefs(ctx).getInt(KEY_DATE, -1) == today
    }
}
