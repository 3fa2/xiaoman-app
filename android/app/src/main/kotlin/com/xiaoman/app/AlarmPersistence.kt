package com.xiaoman.app

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

/// 原生侧提醒计划持久化（重启后由 BootReceiver 读取重建）。
/// v5.0：channel 字段区分日程/待办渠道（缺省 trinity_schedule，兼容旧持久化数据）。
data class AlarmEntry(
    val id: Int,
    val title: String,
    val body: String,
    val epochMs: Long,
    val payload: String?,
    val channel: String = "trinity_schedule",
)

object AlarmPersistence {
    private const val PREFS = "trinity_alarms"
    private const val KEY = "alarm_list"

    private fun prefs(ctx: Context): SharedPreferences =
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    @Synchronized
    fun setAll(ctx: Context, entries: List<AlarmEntry>) {
        val arr = JSONArray()
        for (e in entries) {
            arr.put(
                JSONObject()
                    .put("id", e.id)
                    .put("title", e.title)
                    .put("body", e.body)
                    .put("epochMs", e.epochMs)
                    .put("payload", e.payload ?: "")
                    .put("channel", e.channel),
            )
        }
        prefs(ctx).edit().putString(KEY, arr.toString()).apply()
    }

    @Synchronized
    fun getAll(ctx: Context): List<AlarmEntry> {
        val s = prefs(ctx).getString(KEY, null) ?: return emptyList()
        return try {
            val arr = JSONArray(s)
            (0 until arr.length()).map { i ->
                val o = arr.getJSONObject(i)
                AlarmEntry(
                    id = o.getInt("id"),
                    title = o.getString("title"),
                    body = o.getString("body"),
                    epochMs = o.getLong("epochMs"),
                    payload = o.getString("payload").takeIf { it.isNotEmpty() },
                    channel = o.optString("channel", "trinity_schedule"),
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }
}
