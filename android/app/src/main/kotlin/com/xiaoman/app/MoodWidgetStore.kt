package com.xiaoman.app

import android.content.Context
import java.util.Calendar

/// 心情打卡小组件缓存（v5.8）：记录「今天的心情」+ App 未运行时的待同步打卡队列。
///
/// 结构与 TodoWidgetStore 同一套思路（SharedPreferences，绕开 SQLite/WAL）：
/// - todayMoodId：今天选中的预设心情 id（-1 = 无）；跨天自动失效（todayDate != 今天视为 -1）
/// - pendingMoodPicks：小组件点击但 channel 不可用时的待同步队列，
///   App 下次启动 drainPendingMoodPicks 补落库
object MoodWidgetStore {
    private const val PREFS = "trinity_mood_widget"
    private const val KEY_TODAY_MOOD = "today_mood_id" // -1 = 无
    private const val KEY_TODAY_DATE = "today_date" // todayMoodId 对应的 yyyymmdd
    private const val KEY_PENDING_MOODS = "pending_mood_ids"

    private fun prefs(ctx: Context) =
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun todayDay(): Int {
        val n = Calendar.getInstance()
        return n.get(Calendar.YEAR) * 10000 +
            (n.get(Calendar.MONTH) + 1) * 100 + n.get(Calendar.DAY_OF_MONTH)
    }

    /// 今天选中的心情 id（-1 = 无）。跨天自动失效：存的日期不是今天就视为无。
    fun todayMoodId(ctx: Context): Int {
        val stored = prefs(ctx).getInt(KEY_TODAY_MOOD, -1)
        if (stored < 0) return -1
        if (prefs(ctx).getInt(KEY_TODAY_DATE, 0) != todayDay()) return -1
        return stored
    }

    /// 写入今天的心情（-1 = 清除）。Flutter 推送权威值 / 小组件即时反馈都走这里。
    fun setTodayMood(ctx: Context, moodId: Int) {
        prefs(ctx).edit()
            .putInt(KEY_TODAY_MOOD, moodId)
            .putInt(KEY_TODAY_DATE, todayDay())
            .apply()
    }

    /// 记录待同步打卡（App 未运行时小组件点的心跳过 channel，先排队）
    fun addPendingMoodPick(ctx: Context, moodId: Int) {
        val pending = prefs(ctx).getStringSet(KEY_PENDING_MOODS, emptySet()) ?: emptySet()
        prefs(ctx).edit()
            .putStringSet(KEY_PENDING_MOODS, pending + moodId.toString())
            .apply()
    }

    /// App 启动时调用：返回待同步的心情 id 列表，并清空队列
    fun drainPendingMoodPicks(ctx: Context): List<Int> {
        val pending = prefs(ctx).getStringSet(KEY_PENDING_MOODS, emptySet()) ?: emptySet()
        if (pending.isEmpty()) return emptyList()
        prefs(ctx).edit().remove(KEY_PENDING_MOODS).apply()
        return pending.mapNotNull { it.toIntOrNull() }
    }

    /// 清空待同步队列（Flutter 推送权威心情时调用：陈旧打卡不应再生效）
    fun clearPendingMoodPicks(ctx: Context) {
        prefs(ctx).edit().remove(KEY_PENDING_MOODS).apply()
    }
}
