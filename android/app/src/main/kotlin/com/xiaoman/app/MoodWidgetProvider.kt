package com.xiaoman.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews

/// 心情打卡小组件（v5.8，2x2）：头部「今天心情」+ 8 个预设心情点（静态名字/颜色）。
/// 点击圆点 → 广播 ACTION_MOOD_PICK → 记 pending + 尝试通知 Flutter 落库 + 即时反馈选中圈。
/// 预设心情 id 按 MoodPalette.presets 播种顺序 1..8（开心/期待/平静/感动/疲惫/难过/焦虑/生气）。
class MoodWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_MOOD_PICK = "com.xiaoman.app.widget.MOOD_PICK"
        const val EXTRA_MOOD_ID = "widget_mood_id"

        /// 与 mood_dot_0..7 drawable 及布局静态文本一一对应
        private val MOOD_NAMES = arrayOf(
            "开心", "期待", "平静", "感动", "疲惫", "难过", "焦虑", "生气",
        )
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_MOOD_PICK) {
            val moodId = intent.getIntExtra(EXTRA_MOOD_ID, -1)
            if (moodId > 0) {
                // channel 可能为 null（App 没运行）：先记待同步队列
                MoodWidgetStore.addPendingMoodPick(context, moodId)
                // App 在运行时直接通知 Flutter 落库
                WidgetChannelBridge.moodPick(moodId)
                // 即时反馈：先把 todayMoodId 标成该心情再刷新（权威值以 Flutter 回推为准）
                MoodWidgetStore.setTodayMood(context, moodId)
                TodoWidgetData.refreshMoodWidgets(context)
            }
        } else {
            super.onReceive(context, intent)
        }
    }

    override fun onUpdate(
        context: Context, manager: AppWidgetManager, appWidgetIds: IntArray,
    ) {
        val selected = MoodWidgetStore.todayMoodId(context)
        // 心情名按下标取（id = 下标 + 1）；防御越界退回「今天心情」
        val stateText = if (selected in 1..MOOD_NAMES.size) {
            "今天 · ${MOOD_NAMES[selected - 1]}"
        } else {
            "今天心情"
        }
        val openPi = openAppPi(context, "diary", 30001)

        for (id in appWidgetIds) {
            val v = RemoteViews(context.packageName, R.layout.widget_mood_2x2)
            v.setTextViewText(R.id.mood_state, stateText)
            v.setOnClickPendingIntent(R.id.mood_state, openPi)

            val dotIds = intArrayOf(
                R.id.mood_dot_0, R.id.mood_dot_1, R.id.mood_dot_2, R.id.mood_dot_3,
                R.id.mood_dot_4, R.id.mood_dot_5, R.id.mood_dot_6, R.id.mood_dot_7,
            )
            val ringIds = intArrayOf(
                R.id.mood_ring_0, R.id.mood_ring_1, R.id.mood_ring_2, R.id.mood_ring_3,
                R.id.mood_ring_4, R.id.mood_ring_5, R.id.mood_ring_6, R.id.mood_ring_7,
            )
            for (i in MOOD_NAMES.indices) {
                val moodId = i + 1
                // 选中格：圆点上叠描边圈
                v.setViewVisibility(
                    ringIds[i],
                    if (selected == moodId) View.VISIBLE else View.GONE,
                )
                v.setOnClickPendingIntent(dotIds[i], pickPi(context, moodId))
            }
            manager.updateAppWidget(id, v)
        }
    }

    private fun pickPi(context: Context, moodId: Int): PendingIntent {
        val i = Intent(context, MoodWidgetProvider::class.java)
            .setAction(ACTION_MOOD_PICK)
            .putExtra(EXTRA_MOOD_ID, moodId)
        return PendingIntent.getBroadcast(
            context, 40000 + moodId, i,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun openAppPi(context: Context, action: String, requestCode: Int): PendingIntent {
        val launch = context.packageManager
            .getLaunchIntentForPackage(context.packageName) ?: Intent()
        launch.putExtra(TodoWidgetData.EXTRA_OPEN_ACTION, action)
        return PendingIntent.getActivity(
            context, requestCode, launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
