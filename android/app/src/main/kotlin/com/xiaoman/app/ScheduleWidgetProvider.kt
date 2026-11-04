package com.xiaoman.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews

/// 今日日程小组件（v5.3，4x2）：头部「今日日程 · 剩余N」+ 最多 3 条（时间 + 标题）。
/// 数据来自 ScheduleWidgetStore（Flutter 推送的缓存）；点击整块打开 App 日程页。
class ScheduleWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context, manager: AppWidgetManager, appWidgetIds: IntArray,
    ) {
        val showToday = ScheduleWidgetStore.isToday(context)
        val blocks = if (showToday) ScheduleWidgetStore.blocks(context, 3) else emptyList()
        val remaining = ScheduleWidgetStore.remaining(context)
        val openPi = openAppPi(context, "schedule", 30001)

        for (id in appWidgetIds) {
            val v = RemoteViews(context.packageName, R.layout.widget_schedule_4x2)
            v.setTextViewText(
                R.id.sched_count,
                if (!showToday) "—" else "$remaining",
            )
            v.setOnClickPendingIntent(R.id.sched_root, openPi)

            val rowIds = intArrayOf(R.id.sched_row0, R.id.sched_row1, R.id.sched_row2)
            val timeIds = intArrayOf(R.id.sched_time0, R.id.sched_time1, R.id.sched_time2)
            val titleIds = intArrayOf(R.id.sched_title0, R.id.sched_title1, R.id.sched_title2)
            for (i in rowIds.indices) {
                if (i < blocks.size) {
                    val b = blocks[i]
                    v.setViewVisibility(rowIds[i], View.VISIBLE)
                    v.setTextViewText(timeIds[i], b.time)
                    v.setTextViewText(titleIds[i], b.title)
                } else {
                    v.setViewVisibility(rowIds[i], View.GONE)
                }
            }
            v.setViewVisibility(
                R.id.sched_empty,
                if (blocks.isEmpty()) View.VISIBLE else View.GONE,
            )
            manager.updateAppWidget(id, v)
        }
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
